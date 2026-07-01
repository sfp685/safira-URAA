#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "fs/mcsfs1/mcsfs1.h"

/* RAM blkdev sederhana untuk host test */
#define STORAGE_BLOCKS 64u
#define BLOCK_SZ       512u

static uint8_t g_storage[BLOCK_SZ * STORAGE_BLOCKS];

static int ram_read(void *ctx, uint32_t lba, void *buf) {
    (void)ctx;
    if (lba >= STORAGE_BLOCKS) return -1;
    memcpy(buf, g_storage + lba * BLOCK_SZ, BLOCK_SZ);
    return 0;
}
static int ram_write(void *ctx, uint32_t lba, const void *buf) {
    (void)ctx;
    if (lba >= STORAGE_BLOCKS) return -1;
    memcpy(g_storage + lba * BLOCK_SZ, buf, BLOCK_SZ);
    return 0;
}
static int ram_flush(void *ctx) { (void)ctx; return 0; }

static void make_dev(struct mcsfs1_blkdev *dev, uint32_t blocks) {
    memset(g_storage, 0, sizeof(g_storage));
    dev->ctx         = (void *)0;
    dev->block_count = blocks;
    dev->read        = ram_read;
    dev->write       = ram_write;
    dev->flush       = ram_flush;
}

static int g_failures = 0;

#define CHECK(label, expr, expected) do { \
    int _rc = (expr); \
    if (_rc == (expected)) { \
        printf("[PASS] %s\n", (label)); \
    } else { \
        printf("[FAIL] %s: got %d, expected %d\n", (label), _rc, (expected)); \
        g_failures++; \
    } \
} while(0)

/* ── Fault 1: superblock magic rusak ────────────────────────────────── */
static void test_corrupt_magic(void) {
    struct mcsfs1_blkdev dev;
    make_dev(&dev, STORAGE_BLOCKS);
    mcsfs1_format(&dev);
    /* block 0 byte 0-3 = field magic */
    g_storage[0] = 0xDE;
    g_storage[1] = 0xAD;
    g_storage[2] = 0xBE;
    g_storage[3] = 0xEF;
    CHECK("corrupt_magic: fsck detects CORRUPT",
          mcsfs1_fsck(&dev), MCSFS1_ERR_CORRUPT);
}

/* ── Fault 2: root inode mode salah (DIR → FILE) ─────────────────────── */
static void test_root_inode_bad_mode(void) {
    struct mcsfs1_blkdev dev;
    make_dev(&dev, STORAGE_BLOCKS);
    mcsfs1_format(&dev);
    /*
     * Root inode: ino=1, index=0
     * per_block = 512/60 = 8  →  lba = 3, offset = 0
     * struct layout: uint16_t mode (byte 0-1)
     */
    g_storage[3 * BLOCK_SZ + 0] = (uint8_t)MCSFS1_MODE_FILE;
    g_storage[3 * BLOCK_SZ + 1] = 0;
    struct mcsfs1_mount mnt;
    CHECK("root_bad_mode: mount detects CORRUPT",
          mcsfs1_mount(&mnt, &dev), MCSFS1_ERR_CORRUPT);
    CHECK("root_bad_mode: fsck detects CORRUPT",
          mcsfs1_fsck(&dev), MCSFS1_ERR_CORRUPT);
}

/* ── Fault 3: dirent menunjuk inode bebas ────────────────────────────── */
static void test_dirent_free_inode(void) {
    struct mcsfs1_blkdev dev;
    make_dev(&dev, STORAGE_BLOCKS);
    mcsfs1_format(&dev);
    struct mcsfs1_mount mnt;
    mcsfs1_mount(&mnt, &dev);
    mcsfs1_create(&mnt, "testfile");
    /*
     * alloc_inode_block mulai dari ino=2.
     * Inode bitmap ada di block 1.
     * Hapus bit 2: byte 1[0] &= ~(1<<2)
     */
    g_storage[BLOCK_SZ + 0] &= (uint8_t)~(1u << 2u);
    CHECK("dirent_free_inode: fsck detects CORRUPT",
          mcsfs1_fsck(&dev), MCSFS1_ERR_CORRUPT);
}

/* ── Fault 4: direct block keluar range ──────────────────────────────── */
static void test_direct_block_out_of_range(void) {
    struct mcsfs1_blkdev dev;
    make_dev(&dev, STORAGE_BLOCKS);
    mcsfs1_format(&dev);
    struct mcsfs1_mount mnt;
    mcsfs1_mount(&mnt, &dev);
    mcsfs1_create(&mnt, "testfile");
    /*
     * Inode ino=2: index=1, lba=3, offset=60
     * struct layout: mode(2)+links(2)+size(4) → direct[0] di byte 8
     */
    uint32_t bad_lba = STORAGE_BLOCKS + 1u;
    memcpy(g_storage + 3 * BLOCK_SZ + 60 + 8, &bad_lba, 4);
    CHECK("direct_out_of_range: fsck detects CORRUPT",
          mcsfs1_fsck(&dev), MCSFS1_ERR_CORRUPT);
}

/* ── Fault 5: nama terlalu panjang (>27 byte) ────────────────────────── */
static void test_name_too_long(void) {
    struct mcsfs1_blkdev dev;
    make_dev(&dev, STORAGE_BLOCKS);
    mcsfs1_format(&dev);
    struct mcsfs1_mount mnt;
    mcsfs1_mount(&mnt, &dev);
    /* 28 karakter = 1 lebih dari MCSFS1_MAX_NAME=27 */
    CHECK("name_too_long: create rejects NAMETOOLONG",
          mcsfs1_create(&mnt, "abcdefghijklmnopqrstuvwxyz12"),
          MCSFS1_ERR_NAMETOOLONG);
}

/* ── Fault 6: tulis data >4096 byte ──────────────────────────────────── */
static void test_write_too_large(void) {
    struct mcsfs1_blkdev dev;
    make_dev(&dev, STORAGE_BLOCKS);
    mcsfs1_format(&dev);
    struct mcsfs1_mount mnt;
    mcsfs1_mount(&mnt, &dev);
    mcsfs1_create(&mnt, "bigfile");
    static uint8_t big_buf[4097];
    /* 4097 > MCSFS1_DIRECT_BLOCKS*BLOCK_SIZE = 8*512 = 4096 */
    CHECK("write_too_large: write rejects RANGE",
          mcsfs1_write(&mnt, "bigfile", big_buf, 4097u),
          MCSFS1_ERR_RANGE);
}

/* ── Fault 7: directory penuh (>16 file) ─────────────────────────────── */
static void test_dir_full(void) {
    struct mcsfs1_blkdev dev;
    make_dev(&dev, STORAGE_BLOCKS);
    mcsfs1_format(&dev);
    struct mcsfs1_mount mnt;
    mcsfs1_mount(&mnt, &dev);
    /* Isi 16 slot dirent (MCSFS1_DIRENT_COUNT=16) */
    char name[5];
    for (int i = 0; i < 16; i++) {
        name[0] = 'f';
        name[1] = (char)('0' + i / 10);
        name[2] = (char)('0' + i % 10);
        name[3] = '\0';
        mcsfs1_create(&mnt, name);
    }
    /* File ke-17 harus gagal karena dirent penuh */
    CHECK("dir_full: 17th create rejects NOSPC",
          mcsfs1_create(&mnt, "extra"),
          MCSFS1_ERR_NOSPC);
}

/* ─────────────────────────────────────────────────────────────────────── */
int main(void) {
    printf("=== M15 Fault Injection Tests ===\n");
    test_corrupt_magic();
    test_root_inode_bad_mode();
    test_dirent_free_inode();
    test_direct_block_out_of_range();
    test_name_too_long();
    test_write_too_large();
    test_dir_full();
    if (g_failures == 0) {
        printf("All fault injection tests PASSED\n");
        return 0;
    }
    printf("%d test(s) FAILED\n", g_failures);
    return 1;
}
