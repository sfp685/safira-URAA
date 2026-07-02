# Cek limine tersedia
ls limine/
echo "---"
# Cek linker.ld entry point
grep "ENTRY" linker.ld
sed -i 's/ENTRY(kmain)/ENTRY(kernel_main)/' linker.ld
cat limine.cfg 2>/dev/null || echo "tidak ada"
# Build ulang dengan entry point yang benar
make clean && make all 2>&1 | grep -E "error|warning|kernel.elf"
# Buat ISO
mkdir -p iso_root/boot/limine
cp build/kernel.elf iso_root/boot/kernel.elf
cp limine.cfg iso_root/boot/limine/limine.cfg
cp limine/limine-bios.sys limine/limine-bios-cd.bin limine/limine-uefi-cd.bin iso_root/boot/limine/
xorriso -as mkisofs -b boot/limine/limine-bios-cd.bin     -no-emul-boot -boot-load-size 4 -boot-info-table     --efi-boot boot/limine/limine-uefi-cd.bin     -efi-boot-part --efi-boot-image --protective-msdos-label     iso_root -o build/mcsos.iso 2>&1 | tail -3
ls -lh build/mcsos.iso
qemu-system-x86_64     -cdrom build/mcsos.iso     -serial stdio     -display none     -no-reboot     -m 256M     -timeout 10 2>&1 | head -30 || true
timeout 10 qemu-system-x86_64     -cdrom build/mcsos.iso     -serial stdio     -display none     -no-reboot     -m 256M 2>&1 | head -40 || true
timeout 10 qemu-system-x86_64     -cdrom build/mcsos.iso     -serial stdio     -display none     -no-reboot     -m 256M     -d guest_errors 2>&1 | head -40 || true
# Cek isi iso_root
find iso_root -type f | sort
echo "---"
cat iso_root/boot/limine/limine.cfg
echo "---"
# Cek apakah limine sudah diinstall ke ISO
ls -la limine/limine
cat iso_root/boot/grub/grub.cfg
cat > iso_root/boot/grub/grub.cfg <<'EOF'
set timeout=0
set default=0
menuentry "MCSOS M6" {
    multiboot2 /boot/kernel.elf
    boot
}
EOF

nm build/kernel.elf | grep -E "kernel_main|kmain|_start"
# Bersihkan iso_root dan buat ulang struktur yang benar
rm -rf iso_root
mkdir -p iso_root/boot
# Copy kernel
cp build/kernel.elf iso_root/boot/kernel.elf
# Buat limine.cfg yang benar
cat > iso_root/limine.cfg <<'EOF'
TIMEOUT=0
:MCSOS M6
    PROTOCOL=limine
    KERNEL_PATH=boot:///boot/kernel.elf
EOF

# Copy file limine yang dibutuhkan
cp limine/limine-bios.sys limine/limine-bios-cd.bin limine/limine-uefi-cd.bin iso_root/
# Buat ISO
xorriso -as mkisofs     -b limine-bios-cd.bin     -no-emul-boot -boot-load-size 4 -boot-info-table     --efi-boot limine-uefi-cd.bin     -efi-boot-part --efi-boot-image --protective-m
xorriso -as mkisofs     -b limine-bios-cd.bin     -no-emul-boot -boot-load-size 4 -boot-info-table     --efi-boot limine-uefi-cd.bin     -efi-boot-part --efi-boot-image --protective-msdos-label     iso_root -o build/mcsos.iso 2>&1 | tail -3
limine/limine bios-install build/mcsos.iso 2>&1
ls -lh build/mcsos.iso
timeout 15 qemu-system-x86_64     -cdrom build/mcsos.iso     -serial stdio     -display none     -no-reboot     -m 256M 2>&1 || true
timeout 15 qemu-system-x86_64     -cdrom build/mcsos.iso     -serial stdio     -display none     -no-reboot     -m 256M 2>&1 || true
# Cek apakah ada limine requests di kernel
grep -r "limine_memmap_request\|limine_framebuffer_request\|LIMINE_REQUEST" kernel/ src/ --include="*.c" --include="*.h" | grep -v "build" | head -20
cat > kernel/kernel.c <<'EOF'
#include <serial.h>
#include <idt.h>
#include <pmm.h>
#include <limine.h>

__attribute__((used, section(".requests")))
static volatile struct limine_memmap_request memmap_req = {
    .id = LIMINE_MEMMAP_REQUEST,
    .revision = 0
};

__attribute__((used, section(".requests")))
static volatile struct limine_framebuffer_request fb_req = {
    .id = LIMINE_FRAMEBUFFER_REQUEST,
    .revision = 0
};

__attribute__((used, section(".requests_start_marker")))
static volatile LIMINE_REQUESTS_START_MARKER;

__attribute__((used, section(".requests_end_marker")))
static volatile LIMINE_REQUESTS_END_MARKER;

static struct pmm_state kernel_pmm;
static uint8_t kernel_pmm_bitmap[PMM_BITMAP_BYTES] __attribute__((aligned(4096)));

static void kernel_memory_init(void) {
    struct limine_memmap_response *memmap = memmap_req.response;
    if (!memmap) {
        serial_write_string("[m6] ERROR: no memmap response\n");
        for (;;) asm volatile ("hlt");
    }

    struct boot_mem_region regions[128];
    size_t count = 0;
    for (uint64_t i = 0; i < memmap->entry_count && count < 128; i++) {
        struct limine_memmap_entry *e = memmap->entries[i];
        uint32_t type;
        switch (e->type) {
            case LIMINE_MEMMAP_USABLE:                 type = BOOT_MEM_USABLE; break;
            case LIMINE_MEMMAP_RESERVED:               type = BOOT_MEM_RESERVED; break;
            case LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE: type = BOOT_MEM_BOOTLOADER_RECLAIMABLE; break;
            case LIMINE_MEMMAP_KERNEL_AND_MODULES:     type = BOOT_MEM_KERNEL_AND_MODULES; break;
            case LIMINE_MEMMAP_FRAMEBUFFER:            type = BOOT_MEM_FRAMEBUFFER; break;
            case LIMINE_MEMMAP_ACPI_RECLAIMABLE:       type = BOOT_MEM_ACPI_RECLAIMABLE; break;
            case LIMINE_MEMMAP_ACPI_NVS:               type = BOOT_MEM_ACPI_NVS; break;
            case LIMINE_MEMMAP_BAD_MEMORY:             type = BOOT_MEM_BAD_MEMORY; break;
            default:                                   type = BOOT_MEM_RESERVED; break;
        }
        regions[count].base   = e->base;
        regions[count].length = e->length;
        regions[count].type   = type;
        count++;
    }

    bool ok = pmm_init_from_map(&kernel_pmm, regions, count,
                                kernel_pmm_bitmap, sizeof(kernel_pmm_bitmap),
                                PMM_MAX_PHYS_BYTES);
    if (!ok) {
        serial_write_string("[m6] ERROR: pmm_init_from_map failed\n");
        for (;;) asm volatile ("hlt");
    }
    serial_write_string("[m6] pmm initialized\n");

    uint64_t f = pmm_alloc_frame(&kernel_pmm);
    if (f == PMM_INVALID_FRAME) {
        serial_write_string("[m6] ERROR: pmm_alloc_frame failed\n");
    } else {
        serial_write_string("[m6] sample frame alloc OK\n");
        pmm_free_frame(&kernel_pmm, f);
        serial_write_string("[m6] sample frame free OK\n");
    }
}

void kernel_main(void) {
    serial_init();
    idt_init();
    kernel_memory_init();
    asm volatile ("sti");
    for (;;) asm volatile ("hlt");
}
EOF

make clean && make all 2>&1 | grep -E "error|warning|kernel.elf"
cp build/kernel.elf iso_root/boot/kernel.elf
xorriso -as mkisofs     -b limine-bios-cd.bin     -no-emul-boot -boot-load-size 4 -boot-info-table     --efi-boot limine-uefi-cd.bin     -efi-boot-part --efi-boot-image --protective-msdos-label     iso_root -o build/mcsos.iso 2>&1 | tail -2
limine/limine bios-install build/mcsos.iso 2>&1 | tail -1
timeout 15 qemu-system-x86_64 -cdrom build/mcsos.iso -serial stdio -display none -no-reboot -m 256M 2>&1 || true
gdb build/kernel.elf
cd ~/mcsos
pwd
ls build/kernel.elf
cd ~/mcsos
gdb build/kernel.elf
ss -ltn | grep 1234
target remote :1234
cd ~/mcsos
gdb build/kernel.elf
cd ~/mcsos
mkdir -p artifacts/m15
{ uname -a; lsb_release -a 2>/dev/null || cat /etc/os-release; } | tee artifacts/m15/host_info.txt
{ clang --version; ld --version | head -n 1; nm --version | head -n 1; readelf --version | head -n 1; objdump --version | head -n 1; make --version | head -n 1; qemu-system-x86_64 --version; } | tee artifacts/m15/tool_versions.txt
ls artifacts/m15
mkdir -p scripts artifacts/m15
cat > scripts/m15_preflight.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts/m15
{
  echo "== git =="
  git status --short || true
  git rev-parse --short HEAD || true
  echo "== toolchain =="
  clang --version | head -n 1
  ld --version | head -n 1
  nm --version | head -n 1
  readelf --version | head -n 1
  objdump --version | head -n 1
  make --version | head -n 1
  echo "== prior artifacts =="
  for d in m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14; do
    if [ -d "artifacts/$d" ]; then
      echo "artifacts/$d: present"
    else
      echo "artifacts/$d: missing"
    fi
  done
} | tee artifacts/m15/preflight.txt
EOF

chmod +x scripts/m15_preflight.sh
./scripts/m15_preflight.sh
pwd
git rev-parse --show-toplevel
git branch -vv
git status
ls -la /home/user/.git
mkdir -p scripts artifacts/m15
cat > scripts/m15_preflight.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts/m15
{
  echo "== git =="
  git status --short || true
  git rev-parse --short HEAD || true
  echo "== toolchain =="
  clang --version | head -n 1
  ld --version | head -n 1
  nm --version | head -n 1
  readelf --version | head -n 1
  objdump --version | head -n 1
  make --version | head -n 1
  echo "== prior artifacts =="
  for d in m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14; do
    if [ -d "artifacts/$d" ]; then
      echo "artifacts/$d: present"
    else
      echo "artifacts/$d: missing"
    fi
  done
} | tee artifacts/m15/preflight.txt
EOF

chmod +x scripts/m15_preflight.sh
./scripts/m15_preflight.sh
mkdir -p scripts artifacts/m15
cat > scripts/m15_preflight.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts/m15
{
  echo "== git =="
  git status --short || true
  git rev-parse --short HEAD || true
  echo "== toolchain =="
  clang --version | head -n 1
  ld --version | head -n 1
  nm --version | head -n 1
  readelf --version | head -n 1
  objdump --version | head -n 1
  make --version | head -n 1
  echo "== prior artifacts =="
  for d in m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14; do
    if [ -d "artifacts/$d" ]; then
      echo "artifacts/$d: present"
    else
      echo "artifacts/$d: missing"
    fi
  done
} | tee artifacts/m15/preflight.txt
EOF

chmod +x scripts/m15_preflight.sh
./scripts/m15_preflight.sh
mkdir -p scripts artifacts/m15
cat > scripts/m15_preflight.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts/m15
{
  echo "== git =="
  git status --short || true
  git rev-parse --short HEAD || true
  echo "== toolchain =="
  clang --version | head -n 1
  ld --version | head -n 1
  nm --version | head -n 1
  readelf --version | head -n 1
  objdump --version | head -n 1
  make --version | head -n 1
  echo "== prior artifacts =="
  for d in m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14; do
    if [ -d "artifacts/$d" ]; then
      echo "artifacts/$d: present"
    else
      echo "artifacts/$d: missing"
    fi
  done
} | tee artifacts/m15/preflight.txt
EOF

chmod +x scripts/m15_preflight.sh
./scripts/m15_preflight.sh
git switch -c praktikum-m15-mcsfs1
git switch praktikum-m15-mcsfs1
mkdir -p fs/mcsfs1 tests/m15 artifacts/m15
git branch --show-current
ls -R fs tests artifacts
cat > fs/mcsfs1/mcsfs1.h <<'EOF'
#ifndef MCSFS1_H
#define MCSFS1_H

#include <stdint.h>
#include <stddef.h>

#define MCSFS1_BLOCK_SIZE 512u
#define MCSFS1_MAGIC 0x31465343u
#define MCSFS1_VERSION 1u
#define MCSFS1_MAX_INODES 32u
#define MCSFS1_DIRECT_BLOCKS 8u
#define MCSFS1_MAX_NAME 27u
#define MCSFS1_ROOT_INO 1u
#define MCSFS1_MODE_FREE 0u
#define MCSFS1_MODE_FILE 1u
#define MCSFS1_MODE_DIR 2u
#define MCSFS1_ERR_OK 0
#define MCSFS1_ERR_INVAL -1
#define MCSFS1_ERR_IO -2
#define MCSFS1_ERR_NOSPC -3
#define MCSFS1_ERR_EXIST -4
#define MCSFS1_ERR_NOENT -5
#define MCSFS1_ERR_NAMETOOLONG -6
#define MCSFS1_ERR_CORRUPT -7
#define MCSFS1_ERR_ISDIR -8
#define MCSFS1_ERR_RANGE -9

struct mcsfs1_blkdev {
    void *ctx;
    uint32_t block_count;
    int (*read)(void *ctx, uint32_t lba, void *buf512);
    int (*write)(void *ctx, uint32_t lba, const void *buf512);
    int (*flush)(void *ctx);
};

struct mcsfs1_mount {
    struct mcsfs1_blkdev *dev;
    uint32_t block_count;
    uint32_t data_start;
};

int mcsfs1_format(struct mcsfs1_blkdev *dev);
int mcsfs1_mount(struct mcsfs1_mount *mnt, struct mcsfs1_blkdev *dev);
int mcsfs1_fsck(struct mcsfs1_blkdev *dev);
int mcsfs1_create(struct mcsfs1_mount *mnt, const char *name);
int mcsfs1_write(struct mcsfs1_mount *mnt, const char *name, const uint8_t *buf, uint32_t len);
int mcsfs1_read(struct mcsfs1_mount *mnt, const char *name, uint8_t *buf, uint32_t cap, uint32_t *out_len);
int mcsfs1_unlink(struct mcsfs1_mount *mnt, const char *name);

#endif
EOF

ls fs/mcsfs1
cat fs/mcsfs1/mcsfs1.h
cat > fs/mcsfs1/mcsfs1.c <<'EOF'
#include "mcsfs1.h"

#define MCSFS1_SB_LBA 0u
#define MCSFS1_INODE_BMAP_LBA 1u
#define MCSFS1_BLOCK_BMAP_LBA 2u
#define MCSFS1_INODE_TABLE_LBA 3u
#define MCSFS1_INODE_TABLE_BLOCKS 4u
#define MCSFS1_ROOT_DIR_LBA 7u
#define MCSFS1_DATA_START_LBA 8u
#define MCSFS1_MIN_BLOCKS 16u
#define MCSFS1_DIRENT_COUNT 16u

struct mcsfs1_super_disk {
    uint32_t magic;
    uint32_t version;
    uint32_t block_size;
    uint32_t block_count;
    uint32_t inode_count;
    uint32_t inode_bmap_lba;
    uint32_t block_bmap_lba;
    uint32_t inode_table_lba;
    uint32_t inode_table_blocks;
    uint32_t root_ino;
    uint32_t root_dir_lba;
    uint32_t data_start_lba;
    uint32_t clean;
    uint32_t reserved[115];
};

struct mcsfs1_inode_disk {
    uint16_t mode;
    uint16_t links;
    uint32_t size;
    uint32_t direct[MCSFS1_DIRECT_BLOCKS];
    uint32_t reserved[5];
};

struct mcsfs1_dirent_disk {
    uint32_t ino;
    uint8_t type;
    char name[MCSFS1_MAX_NAME];
};

static void *mcsfs_memset(void *dst, int c, uint32_t n) {
    uint8_t *d = (uint8_t *)dst;
    for (uint32_t i = 0; i < n; i++) {
        d[i] = (uint8_t)c;
    }
    return dst;
}

static void *mcsfs_memcpy(void *dst, const void *src, uint32_t n) {
    uint8_t *d = (uint8_t *)dst;
    const uint8_t *s = (const uint8_t *)src;
    for (uint32_t i = 0; i < n; i++) {
        d[i] = s[i];
    }
    return dst;
}

static int mcsfs_memcmp(const void *a, const void *b, uint32_t n) {
    const uint8_t *x = (const uint8_t *)a;
    const uint8_t *y = (const uint8_t *)b;
    for (uint32_t i = 0; i < n; i++) {
        if (x[i] != y[i]) {
            return (int)x[i] - (int)y[i];
        }
    }
    return 0;
}

static uint32_t mcsfs_strlen_bound(const char *s, uint32_t max_plus_one) {
    uint32_t n = 0;
    if (s == 0) {
        return max_plus_one;
    }
    while (n < max_plus_one && s[n] != '\0') {
        n++;
    }
    return n;
}

static int valid_name(const char *name, uint32_t *len_out) {
    uint32_t n = mcsfs_strlen_bound(name, MCSFS1_MAX_NAME + 1u);
    if (n == 0u) {
        return MCSFS1_ERR_INVAL;
    }
    if (n > MCSFS1_MAX_NAME) {
        return MCSFS1_ERR_NAMETOOLONG;
    }
    for (uint32_t i = 0; i < n; i++) {
        if (name[i] == '/') {
            return MCSFS1_ERR_INVAL;
        }
    }
    *len_out = n;
    return MCSFS1_ERR_OK;
}

static int dev_read(struct mcsfs1_blkdev *dev, uint32_t lba, void *buf) {
    if (dev == 0 || dev->read == 0 || buf == 0 || lba >= dev->block_count) {
        return MCSFS1_ERR_INVAL;
    }
    return dev->read(dev->ctx, lba, buf) == 0 ? MCSFS1_ERR_OK : MCSFS1_ERR_IO;
}

static int dev_write(struct mcsfs1_blkdev *dev, uint32_t lba, const void *buf) {
    if (dev == 0 || dev->write == 0 || buf == 0 || lba >= dev->block_count) {
        return MCSFS1_ERR_INVAL;
    }
    return dev->write(dev->ctx, lba, buf) == 0 ? MCSFS1_ERR_OK : MCSFS1_ERR_IO;
}

static int dev_flush(struct mcsfs1_blkdev *dev) {
    if (dev == 0 || dev->flush == 0) {
        return MCSFS1_ERR_INVAL;
    }
    return dev->flush(dev->ctx) == 0 ? MCSFS1_ERR_OK : MCSFS1_ERR_IO;
}

static void bit_set(uint8_t *b, uint32_t bit) {
    b[bit / 8u] = (uint8_t)(b[bit / 8u] | (uint8_t)(1u << (bit % 8u)));
}

static void bit_clear(uint8_t *b, uint32_t bit) {
    b[bit / 8u] = (uint8_t)(b[bit / 8u] & (uint8_t)~(uint8_t)(1u << (bit % 8u)));
}

static int bit_test(const uint8_t *b, uint32_t bit) {
    return (b[bit / 8u] & (uint8_t)(1u << (bit % 8u))) != 0u;
}
EOF

cat >> fs/mcsfs1/mcsfs1.c <<'EOF'

static int load_super(struct mcsfs1_blkdev *dev, struct mcsfs1_super_disk *sb) {
    int rc = dev_read(dev, MCSFS1_SB_LBA, sb);
    if (rc != 0) {
        return rc;
    }
    if (sb->magic != MCSFS1_MAGIC || sb->version != MCSFS1_VERSION || sb->block_size != MCSFS1_BLOCK_SIZE) {
        return MCSFS1_ERR_CORRUPT;
    }
    if (sb->block_count != dev->block_count || sb->inode_count != MCSFS1_MAX_INODES) {
        return MCSFS1_ERR_CORRUPT;
    }
    if (sb->inode_bmap_lba != MCSFS1_INODE_BMAP_LBA || sb->block_bmap_lba != MCSFS1_BLOCK_BMAP_LBA || sb->inode_table_lba != MCSFS1_INODE_TABLE_LBA) {
        return MCSFS1_ERR_CORRUPT;
    }
    if (sb->root_ino != MCSFS1_ROOT_INO || sb->root_dir_lba != MCSFS1_ROOT_DIR_LBA || sb->data_start_lba != MCSFS1_DATA_START_LBA) {
        return MCSFS1_ERR_CORRUPT;
    }
    if (sb->data_start_lba >= sb->block_count) {
        return MCSFS1_ERR_CORRUPT;
    }
    return MCSFS1_ERR_OK;
}

static int read_inode(struct mcsfs1_blkdev *dev, uint32_t ino, struct mcsfs1_inode_disk *inode) {
    if (ino == 0u || ino > MCSFS1_MAX_INODES || inode == 0) {
        return MCSFS1_ERR_INVAL;
    }
    uint8_t block[MCSFS1_BLOCK_SIZE];
    uint32_t index = ino - 1u;
    uint32_t per_block = MCSFS1_BLOCK_SIZE / (uint32_t)sizeof(struct mcsfs1_inode_disk);
    uint32_t lba = MCSFS1_INODE_TABLE_LBA + (index / per_block);
    uint32_t off = (index % per_block) * (uint32_t)sizeof(struct mcsfs1_inode_disk);
    if (lba >= MCSFS1_DATA_START_LBA) {
        return MCSFS1_ERR_CORRUPT;
    }
    int rc = dev_read(dev, lba, block);
    if (rc != 0) {
        return rc;
    }
    mcsfs_memcpy(inode, block + off, (uint32_t)sizeof(*inode));
    return MCSFS1_ERR_OK;
}

static int write_inode(struct mcsfs1_blkdev *dev, uint32_t ino, const struct mcsfs1_inode_disk *inode) {
    if (ino == 0u || ino > MCSFS1_MAX_INODES || inode == 0) {
        return MCSFS1_ERR_INVAL;
    }
    uint8_t block[MCSFS1_BLOCK_SIZE];
    uint32_t index = ino - 1u;
    uint32_t per_block = MCSFS1_BLOCK_SIZE / (uint32_t)sizeof(struct mcsfs1_inode_disk);
    uint32_t lba = MCSFS1_INODE_TABLE_LBA + (index / per_block);
    uint32_t off = (index % per_block) * (uint32_t)sizeof(struct mcsfs1_inode_disk);
    if (lba >= MCSFS1_DATA_START_LBA) {
        return MCSFS1_ERR_CORRUPT;
    }
    int rc = dev_read(dev, lba, block);
    if (rc != 0) {
        return rc;
    }
    mcsfs_memcpy(block + off, inode, (uint32_t)sizeof(*inode));
    return dev_write(dev, lba, block);
}

static int load_bmaps(struct mcsfs1_blkdev *dev, uint8_t *ib, uint8_t *bb) {
    int rc = dev_read(dev, MCSFS1_INODE_BMAP_LBA, ib);
    if (rc != 0) {
        return rc;
    }
    return dev_read(dev, MCSFS1_BLOCK_BMAP_LBA, bb);
}

static int store_bmaps(struct mcsfs1_blkdev *dev, const uint8_t *ib, const uint8_t *bb) {
    int rc = dev_write(dev, MCSFS1_INODE_BMAP_LBA, ib);
    if (rc != 0) {
        return rc;
    }
    return dev_write(dev, MCSFS1_BLOCK_BMAP_LBA, bb);
}
EOF

cat >> fs/mcsfs1/mcsfs1.c <<'EOF'

static int find_dirent(struct mcsfs1_blkdev *dev, const char *name, uint32_t *slot_out, uint32_t *ino_out) {
    uint8_t block[MCSFS1_BLOCK_SIZE];
    uint32_t name_len = 0;
    int rc = valid_name(name, &name_len);
    if (rc != 0) {
        return rc;
    }
    rc = dev_read(dev, MCSFS1_ROOT_DIR_LBA, block);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_dirent_disk *de = (struct mcsfs1_dirent_disk *)block;
    for (uint32_t i = 0; i < MCSFS1_DIRENT_COUNT; i++) {
        if (de[i].ino != 0u && mcsfs_strlen_bound(de[i].name, MCSFS1_MAX_NAME + 1u) == name_len && mcsfs_memcmp(de[i].name, name, name_len) == 0) {
            if (slot_out != 0) {
                *slot_out = i;
            }
            if (ino_out != 0) {
                *ino_out = de[i].ino;
            }
            return MCSFS1_ERR_OK;
        }
    }
    return MCSFS1_ERR_NOENT;
}

static int alloc_inode_block(struct mcsfs1_blkdev *dev, uint32_t *ino_out, uint32_t *data_lba_out) {
    uint8_t ib[MCSFS1_BLOCK_SIZE];
    uint8_t bb[MCSFS1_BLOCK_SIZE];
    int rc = load_bmaps(dev, ib, bb);
    if (rc != 0) {
        return rc;
    }
    uint32_t ino = 0;
    for (uint32_t i = 2u; i <= MCSFS1_MAX_INODES; i++) {
        if (!bit_test(ib, i)) {
            ino = i;
            break;
        }
    }
    if (ino == 0u) {
        return MCSFS1_ERR_NOSPC;
    }
    uint32_t lba = 0;
    for (uint32_t b = MCSFS1_DATA_START_LBA; b < dev->block_count; b++) {
        if (!bit_test(bb, b)) {
            lba = b;
            break;
        }
    }
    if (lba == 0u) {
        return MCSFS1_ERR_NOSPC;
    }
    bit_set(ib, ino);
    bit_set(bb, lba);
    rc = store_bmaps(dev, ib, bb);
    if (rc != 0) {
        return rc;
    }
    *ino_out = ino;
    *data_lba_out = lba;
    return MCSFS1_ERR_OK;
}

static int alloc_data_block(struct mcsfs1_blkdev *dev, uint32_t *data_lba_out) {
    uint8_t ib[MCSFS1_BLOCK_SIZE];
    uint8_t bb[MCSFS1_BLOCK_SIZE];
    int rc = load_bmaps(dev, ib, bb);
    if (rc != 0) {
        return rc;
    }
    for (uint32_t b = MCSFS1_DATA_START_LBA; b < dev->block_count; b++) {
        if (!bit_test(bb, b)) {
            bit_set(bb, b);
            rc = store_bmaps(dev, ib, bb);
            if (rc != 0) {
                return rc;
            }
            *data_lba_out = b;
            return MCSFS1_ERR_OK;
        }
    }
    return MCSFS1_ERR_NOSPC;
}

static int free_inode_and_blocks(struct mcsfs1_blkdev *dev, uint32_t ino, const struct mcsfs1_inode_disk *inode) {
    uint8_t ib[MCSFS1_BLOCK_SIZE];
    uint8_t bb[MCSFS1_BLOCK_SIZE];
    int rc = load_bmaps(dev, ib, bb);
    if (rc != 0) {
        return rc;
    }
    bit_clear(ib, ino);
    for (uint32_t i = 0; i < MCSFS1_DIRECT_BLOCKS; i++) {
        if (inode->direct[i] != 0u && inode->direct[i] < dev->block_count) {
            bit_clear(bb, inode->direct[i]);
        }
    }
    return store_bmaps(dev, ib, bb);
}
EOF

cat >> fs/mcsfs1/mcsfs1.c <<'EOF'

int mcsfs1_format(struct mcsfs1_blkdev *dev) {
    if (dev == 0 || dev->block_count < MCSFS1_MIN_BLOCKS || dev->block_count > (MCSFS1_BLOCK_SIZE * 8u)) {
        return MCSFS1_ERR_INVAL;
    }
    uint8_t zero[MCSFS1_BLOCK_SIZE];
    mcsfs_memset(zero, 0, MCSFS1_BLOCK_SIZE);
    for (uint32_t lba = 0; lba < dev->block_count; lba++) {
        int rc0 = dev_write(dev, lba, zero);
        if (rc0 != 0) {
            return rc0;
        }
    }

    struct mcsfs1_super_disk sb;
    mcsfs_memset(&sb, 0, (uint32_t)sizeof(sb));
    sb.magic = MCSFS1_MAGIC;
    sb.version = MCSFS1_VERSION;
    sb.block_size = MCSFS1_BLOCK_SIZE;
    sb.block_count = dev->block_count;
    sb.inode_count = MCSFS1_MAX_INODES;
    sb.inode_bmap_lba = MCSFS1_INODE_BMAP_LBA;
    sb.block_bmap_lba = MCSFS1_BLOCK_BMAP_LBA;
    sb.inode_table_lba = MCSFS1_INODE_TABLE_LBA;
    sb.inode_table_blocks = MCSFS1_INODE_TABLE_BLOCKS;
    sb.root_ino = MCSFS1_ROOT_INO;
    sb.root_dir_lba = MCSFS1_ROOT_DIR_LBA;
    sb.data_start_lba = MCSFS1_DATA_START_LBA;
    sb.clean = 1u;
    int rc = dev_write(dev, MCSFS1_SB_LBA, &sb);
    if (rc != 0) {
        return rc;
    }

    uint8_t ib[MCSFS1_BLOCK_SIZE];
    uint8_t bb[MCSFS1_BLOCK_SIZE];
    mcsfs_memset(ib, 0, MCSFS1_BLOCK_SIZE);
    mcsfs_memset(bb, 0, MCSFS1_BLOCK_SIZE);
    bit_set(ib, 0u);
    bit_set(ib, MCSFS1_ROOT_INO);
    for (uint32_t b = 0; b < MCSFS1_DATA_START_LBA; b++) {
        bit_set(bb, b);
    }
    bit_set(bb, MCSFS1_ROOT_DIR_LBA);
    rc = store_bmaps(dev, ib, bb);
    if (rc != 0) {
        return rc;
    }

    struct mcsfs1_inode_disk root;
    mcsfs_memset(&root, 0, (uint32_t)sizeof(root));
    root.mode = MCSFS1_MODE_DIR;
    root.links = 1u;
    root.size = MCSFS1_BLOCK_SIZE;
    root.direct[0] = MCSFS1_ROOT_DIR_LBA;
    rc = write_inode(dev, MCSFS1_ROOT_INO, &root);
    if (rc != 0) {
        return rc;
    }
    return dev_flush(dev);
}

int mcsfs1_mount(struct mcsfs1_mount *mnt, struct mcsfs1_blkdev *dev) {
    if (mnt == 0 || dev == 0) {
        return MCSFS1_ERR_INVAL;
    }
    struct mcsfs1_super_disk sb;
    int rc = load_super(dev, &sb);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_inode_disk root;
    rc = read_inode(dev, MCSFS1_ROOT_INO, &root);
    if (rc != 0) {
        return rc;
    }
    if (root.mode != MCSFS1_MODE_DIR || root.direct[0] != MCSFS1_ROOT_DIR_LBA) {
        return MCSFS1_ERR_CORRUPT;
    }
    mnt->dev = dev;
    mnt->block_count = sb.block_count;
    mnt->data_start = sb.data_start_lba;
    return MCSFS1_ERR_OK;
}

int mcsfs1_create(struct mcsfs1_mount *mnt, const char *name) {
    if (mnt == 0 || mnt->dev == 0) {
        return MCSFS1_ERR_INVAL;
    }
    uint32_t name_len = 0;
    int rc = valid_name(name, &name_len);
    if (rc != 0) {
        return rc;
    }
    if (find_dirent(mnt->dev, name, 0, 0) == 0) {
        return MCSFS1_ERR_EXIST;
    }
    uint8_t dir_block[MCSFS1_BLOCK_SIZE];
    rc = dev_read(mnt->dev, MCSFS1_ROOT_DIR_LBA, dir_block);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_dirent_disk *de = (struct mcsfs1_dirent_disk *)dir_block;
    uint32_t free_slot = MCSFS1_DIRENT_COUNT;
    for (uint32_t i = 0; i < MCSFS1_DIRENT_COUNT; i++) {
        if (de[i].ino == 0u) {
            free_slot = i;
            break;
        }
    }
    if (free_slot == MCSFS1_DIRENT_COUNT) {
        return MCSFS1_ERR_NOSPC;
    }
    uint32_t ino = 0;
    uint32_t first_data = 0;
    rc = alloc_inode_block(mnt->dev, &ino, &first_data);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_inode_disk inode;
    mcsfs_memset(&inode, 0, (uint32_t)sizeof(inode));
    inode.mode = MCSFS1_MODE_FILE;
    inode.links = 1u;
    inode.size = 0u;
    inode.direct[0] = first_data;
    rc = write_inode(mnt->dev, ino, &inode);
    if (rc != 0) {
        return rc;
    }
    de[free_slot].ino = ino;
    de[free_slot].type = MCSFS1_MODE_FILE;
    mcsfs_memset(de[free_slot].name, 0, MCSFS1_MAX_NAME);
    mcsfs_memcpy(de[free_slot].name, name, name_len);
    rc = dev_write(mnt->dev, MCSFS1_ROOT_DIR_LBA, dir_block);
    if (rc != 0) {
        return rc;
    }
    return dev_flush(mnt->dev);
}

int mcsfs1_write(struct mcsfs1_mount *mnt, const char *name, const uint8_t *buf, uint32_t len) {
    if (mnt == 0 || mnt->dev == 0 || (buf == 0 && len != 0u)) {
        return MCSFS1_ERR_INVAL;
    }
    if (len > MCSFS1_DIRECT_BLOCKS * MCSFS1_BLOCK_SIZE) {
        return MCSFS1_ERR_RANGE;
    }
    uint32_t ino = 0;
    int rc = find_dirent(mnt->dev, name, 0, &ino);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_inode_disk inode;
    rc = read_inode(mnt->dev, ino, &inode);
    if (rc != 0) {
        return rc;
    }
    if (inode.mode != MCSFS1_MODE_FILE) {
        return MCSFS1_ERR_ISDIR;
    }
    uint32_t blocks_needed = (len + MCSFS1_BLOCK_SIZE - 1u) / MCSFS1_BLOCK_SIZE;
    if (blocks_needed == 0u) {
        blocks_needed = 1u;
    }
    for (uint32_t i = 0; i < blocks_needed; i++) {
        if (inode.direct[i] == 0u) {
            rc = alloc_data_block(mnt->dev, &inode.direct[i]);
            if (rc != 0) {
                return rc;
            }
        }
    }
    uint8_t block[MCSFS1_BLOCK_SIZE];
    uint32_t written = 0;
    for (uint32_t i = 0; i < blocks_needed; i++) {
        mcsfs_memset(block, 0, MCSFS1_BLOCK_SIZE);
        uint32_t remain = len - written;
        uint32_t chunk = remain > MCSFS1_BLOCK_SIZE ? MCSFS1_BLOCK_SIZE : remain;
        if (chunk != 0u) {
            mcsfs_memcpy(block, buf + written, chunk);
        }
        rc = dev_write(mnt->dev, inode.direct[i], block);
        if (rc != 0) {
            return rc;
        }
        written += chunk;
    }
    inode.size = len;
    rc = write_inode(mnt->dev, ino, &inode);
    if (rc != 0) {
        return rc;
    }
    return dev_flush(mnt->dev);
}
EOF

cat >> fs/mcsfs1/mcsfs1.c <<'EOF'

int mcsfs1_read(struct mcsfs1_mount *mnt, const char *name, uint8_t *buf, uint32_t cap, uint32_t *out_len) {
    if (mnt == 0 || mnt->dev == 0 || buf == 0 || out_len == 0) {
        return MCSFS1_ERR_INVAL;
    }
    uint32_t ino = 0;
    int rc = find_dirent(mnt->dev, name, 0, &ino);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_inode_disk inode;
    rc = read_inode(mnt->dev, ino, &inode);
    if (rc != 0) {
        return rc;
    }
    if (inode.mode != MCSFS1_MODE_FILE) {
        return MCSFS1_ERR_ISDIR;
    }
    if (cap < inode.size) {
        return MCSFS1_ERR_RANGE;
    }
    uint32_t blocks_needed = (inode.size + MCSFS1_BLOCK_SIZE - 1u) / MCSFS1_BLOCK_SIZE;
    uint32_t copied = 0;
    uint8_t block[MCSFS1_BLOCK_SIZE];
    for (uint32_t i = 0; i < blocks_needed; i++) {
        if (inode.direct[i] == 0u || inode.direct[i] >= mnt->block_count) {
            return MCSFS1_ERR_CORRUPT;
        }
        rc = dev_read(mnt->dev, inode.direct[i], block);
        if (rc != 0) {
            return rc;
        }
        uint32_t remain = inode.size - copied;
        uint32_t chunk = remain > MCSFS1_BLOCK_SIZE ? MCSFS1_BLOCK_SIZE : remain;
        mcsfs_memcpy(buf + copied, block, chunk);
        copied += chunk;
    }
    *out_len = inode.size;
    return MCSFS1_ERR_OK;
}

int mcsfs1_unlink(struct mcsfs1_mount *mnt, const char *name) {
    if (mnt == 0 || mnt->dev == 0) {
        return MCSFS1_ERR_INVAL;
    }
    uint32_t slot = 0;
    uint32_t ino = 0;
    int rc = find_dirent(mnt->dev, name, &slot, &ino);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_inode_disk inode;
    rc = read_inode(mnt->dev, ino, &inode);
    if (rc != 0) {
        return rc;
    }
    if (inode.mode != MCSFS1_MODE_FILE) {
        return MCSFS1_ERR_ISDIR;
    }
    uint8_t dir_block[MCSFS1_BLOCK_SIZE];
    rc = dev_read(mnt->dev, MCSFS1_ROOT_DIR_LBA, dir_block);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_dirent_disk *de = (struct mcsfs1_dirent_disk *)dir_block;
    mcsfs_memset(&de[slot], 0, (uint32_t)sizeof(de[slot]));
    rc = dev_write(mnt->dev, MCSFS1_ROOT_DIR_LBA, dir_block);
    if (rc != 0) {
        return rc;
    }
    rc = free_inode_and_blocks(mnt->dev, ino, &inode);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_inode_disk zero_inode;
    mcsfs_memset(&zero_inode, 0, (uint32_t)sizeof(zero_inode));
    rc = write_inode(mnt->dev, ino, &zero_inode);
    if (rc != 0) {
        return rc;
    }
    return dev_flush(mnt->dev);
}

int mcsfs1_fsck(struct mcsfs1_blkdev *dev) {
    if (dev == 0) {
        return MCSFS1_ERR_INVAL;
    }
    struct mcsfs1_super_disk sb;
    int rc = load_super(dev, &sb);
    if (rc != 0) {
        return rc;
    }
    uint8_t ib[MCSFS1_BLOCK_SIZE];
    uint8_t bb[MCSFS1_BLOCK_SIZE];
    rc = load_bmaps(dev, ib, bb);
    if (rc != 0) {
        return rc;
    }
    if (!bit_test(ib, MCSFS1_ROOT_INO) || !bit_test(bb, MCSFS1_ROOT_DIR_LBA)) {
        return MCSFS1_ERR_CORRUPT;
    }
    for (uint32_t b = 0; b < MCSFS1_DATA_START_LBA; b++) {
        if (!bit_test(bb, b)) {
            return MCSFS1_ERR_CORRUPT;
        }
    }
    struct mcsfs1_inode_disk root;
    rc = read_inode(dev, MCSFS1_ROOT_INO, &root);
    if (rc != 0) {
        return rc;
    }
    if (root.mode != MCSFS1_MODE_DIR || root.direct[0] != MCSFS1_ROOT_DIR_LBA) {
        return MCSFS1_ERR_CORRUPT;
    }
    uint8_t dir_block[MCSFS1_BLOCK_SIZE];
    rc = dev_read(dev, MCSFS1_ROOT_DIR_LBA, dir_block);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_dirent_disk *de = (struct mcsfs1_dirent_disk *)dir_block;
    for (uint32_t i = 0; i < MCSFS1_DIRENT_COUNT; i++) {
        if (de[i].ino == 0u) {
            continue;
        }
        if (de[i].ino > MCSFS1_MAX_INODES || de[i].type != MCSFS1_MODE_FILE || !bit_test(ib, de[i].ino)) {
            return MCSFS1_ERR_CORRUPT;
        }
        struct mcsfs1_inode_disk inode;
        rc = read_inode(dev, de[i].ino, &inode);
        if (rc != 0) {
            return rc;
        }
        if (inode.mode != MCSFS1_MODE_FILE || inode.size > MCSFS1_DIRECT_BLOCKS * MCSFS1_BLOCK_SIZE) {
            return MCSFS1_ERR_CORRUPT;
        }
        uint32_t needed = (inode.size + MCSFS1_BLOCK_SIZE - 1u) / MCSFS1_BLOCK_SIZE;
        if (needed == 0u) {
            needed = 1u;
        }
        for (uint32_t j = 0; j < needed; j++) {
            uint32_t lba = inode.direct[j];
            if (lba < MCSFS1_DATA_START_LBA || lba >= dev->block_count || !bit_test(bb, lba)) {
                return MCSFS1_ERR_CORRUPT;
            }
        }
    }
    return MCSFS1_ERR_OK;
}
EOF

wc -l fs/mcsfs1/mcsfs1.c
tail -5 fs/mcsfs1/mcsfs1.c
cat > tests/m15/test_mcsfs1.c <<'EOF'
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "../../fs/mcsfs1/mcsfs1.h"

#define RAMBLK_BLOCKS 128u
static uint8_t disk[RAMBLK_BLOCKS][MCSFS1_BLOCK_SIZE];
static unsigned flush_count;

static int ram_read(void *ctx, uint32_t lba, void *buf512) {
    (void)ctx;
    if (lba >= RAMBLK_BLOCKS) return -1;
    memcpy(buf512, disk[lba], MCSFS1_BLOCK_SIZE);
    return 0;
}

static int ram_write(void *ctx, uint32_t lba, const void *buf512) {
    (void)ctx;
    if (lba >= RAMBLK_BLOCKS) return -1;
    memcpy(disk[lba], buf512, MCSFS1_BLOCK_SIZE);
    return 0;
}

static int ram_flush(void *ctx) {
    (void)ctx;
    flush_count++;
    return 0;
}

static int expect_int(const char *label, int got, int want) {
    if (got != want) {
        printf("FAIL %s got=%d want=%d\n", label, got, want);
        return 1;
    }
    return 0;
}

int main(void) {
    struct mcsfs1_blkdev dev = {0};
    struct mcsfs1_mount mnt = {0};
    uint8_t out[4096];
    uint32_t out_len = 0;
    int fails = 0;

    dev.block_count = RAMBLK_BLOCKS;
    dev.read = ram_read;
    dev.write = ram_write;
    dev.flush = ram_flush;

    fails += expect_int("format", mcsfs1_format(&dev), MCSFS1_ERR_OK);
    fails += expect_int("mount", mcsfs1_mount(&mnt, &dev), MCSFS1_ERR_OK);
    fails += expect_int("fsck-empty", mcsfs1_fsck(&dev), MCSFS1_ERR_OK);
    fails += expect_int("create-alpha", mcsfs1_create(&mnt, "alpha.txt"), MCSFS1_ERR_OK);
    fails += expect_int("create-duplicate", mcsfs1_create(&mnt, "alpha.txt"), MCSFS1_ERR_EXIST);

    const char msg[] = "MCSOS M15 persistent file payload";
    fails += expect_int("write-alpha", mcsfs1_write(&mnt, "alpha.txt", (const uint8_t *)msg, (uint32_t)strlen(msg)), MCSFS1_ERR_OK);
    memset(out, 0, sizeof(out));
    fails += expect_int("read-alpha", mcsfs1_read(&mnt, "alpha.txt", out, sizeof(out), &out_len), MCSFS1_ERR_OK);
    if (out_len != strlen(msg) || memcmp(out, msg, strlen(msg)) != 0) {
        printf("FAIL read-data len=%u\n", out_len);
        fails++;
    }

    uint8_t big[1400];
    for (unsigned i = 0; i < sizeof(big); i++) big[i] = (uint8_t)(i & 0xffu);
    fails += expect_int("write-big", mcsfs1_write(&mnt, "alpha.txt", big, sizeof(big)), MCSFS1_ERR_OK);
    memset(out, 0, sizeof(out));
    fails += expect_int("read-big", mcsfs1_read(&mnt, "alpha.txt", out, sizeof(out), &out_len), MCSFS1_ERR_OK);
    if (out_len != sizeof(big) || memcmp(out, big, sizeof(big)) != 0) {
        printf("FAIL read-big-data len=%u\n", out_len);
        fails++;
    }

    fails += expect_int("read-small-cap", mcsfs1_read(&mnt, "alpha.txt", out, 8, &out_len), MCSFS1_ERR_RANGE);
    fails += expect_int("missing", mcsfs1_read(&mnt, "missing", out, sizeof(out), &out_len), MCSFS1_ERR_NOENT);
    fails += expect_int("fsck-populated", mcsfs1_fsck(&dev), MCSFS1_ERR_OK);
    fails += expect_int("unlink", mcsfs1_unlink(&mnt, "alpha.txt"), MCSFS1_ERR_OK);
    fails += expect_int("read-after-unlink", mcsfs1_read(&mnt, "alpha.txt", out, sizeof(out), &out_len), MCSFS1_ERR_NOENT);
    fails += expect_int("fsck-after-unlink", mcsfs1_fsck(&dev), MCSFS1_ERR_OK);

    disk[0][0] ^= 0x55u;
    fails += expect_int("corrupt-super", mcsfs1_fsck(&dev), MCSFS1_ERR_CORRUPT);

    if (flush_count == 0) {
        printf("FAIL flush-count zero\n");
        fails++;
    }

    if (fails != 0) {
        printf("M15 host test failed: %d failures\n", fails);
        return 1;
    }
    printf("M15 host test passed: flush_count=%u\n", flush_count);
    return 0;
}

EOF

ls tests/m15
wc -l tests/m15/test_mcsfs1.c
head -50 Makefile
tail -80 Makefile
find . -maxdepth 3 -name "Makefile"
find . -iname "makefile"
head -50 makefile
tail -80 makefile
head -50 makefile
tail -80 makefile
cp Makefile Makefile.bak
cd ~/mcsos
ls -la
ls -la | grep -i makefile
find . -iname "makefile" 2>/dev/null
cp makefile makefile.bak
cp makefile.m14 makefile.m14.bak
cd ~/mcsos
cat makefile
cat makefile.m14
cd ~/mcsos
cp makefile makefile.bak
nano makefile
make -n m15-all
find fs -iname "mcsfs1*"
find tests -iname "*mcsfs1*"
make m15-all
make clean
make CC=clang m15-all
cat kmain.c
ls -la /usr/share/OVMF/ 2>/dev/null || echo "OVMF tidak ada"
git log --oneline -10 2>/dev/null || echo "belum git repo"
git tag 2>/dev/null
cat fs/mcsfs1/mcsfs1.h
cat include/mcsos/block.h
cat kernel/block/ramblk.c
cat kernel/block/block_demo.c
nano kernel/block/block_demo.c
nano fs/mcsfs1/mcsfs1_blkdev_adapter.c
nano fs/mcsfs1/mcsfs1_blkdev_adapter.h
nano kmain.c
nano makefile
make -n m15-smoke
make m15-smoke
grep -n "m15-smoke" makefile
tail -20 makefile
nano makefile
grep -n "m15-smoke" makefile
make -n m15-smoke
make m15-smoke
ls artifacts/m15
cat artifacts/m15/qemu_serial.log
qemu-system-x86_64   -machine q35   -m 256M   -serial stdio   -display none   -s -S   -cdrom build/mcsos.iso
make m15-smoke
cd ~/mcsos
ls build/kernel.elf
qemu-system-x86_64   -machine q35   -m 256M   -serial stdio   -display none   -s -S   -cdrom build/mcsos.iso
grep -n "int mcsfs1_create" -A20 fs/mcsfs1/mcsfs1.c
grep -n "int mcsfs1_write" -A20 fs/mcsfs1/mcsfs1.c
grep -n "int mcsfs1_fsck" -A40 fs/mcsfs1/mcsfs1.c
cat tests/m15/test_mcsfs1.c
tail -40 tests/m15/test_mcsfs1.c
nl -ba tests/m15/test_mcsfs1.c | tail -60
cd~/mcsos
xxd build/kernel.elf | grep -A1 "ad b0"
cd ~/mcsos
xxd build/kernel.elf | grep -A1 "ad b0"
python3 -c "
data = open('build/kernel.elf','rb').read()
idx = data.find(b'\x02\xb0\xad\x1b')
print('magic found at offset:', idx)
"
readelf -S build/kernel.elf | grep -A1 multiboot
sed -i 's/^\.section \.multiboot$/.section .multiboot, "a"/' src/kernel/arch/x86_64/boot.s
head -5 src/kernel/arch/x86_64/boot.s
make clean
make all
readelf -S build/kernel.elf | grep -A1 multiboot
readelf -l build/kernel.elf
make iso
timeout 8 qemu-system-x86_64 -machine q35 -m 256M -nographic -cdrom build/mcsos.iso < /dev/null > artifacts/m14/qemu_m14.log 2>&1
cat artifacts/m14/qemu_m14.log
cat artifacts/m14/qemu_m14.log 
ls build
ls artifacts/m14
cat artifacts/m14/qemu_m14.log
cd ~/mcsos
qemu-system-x86_64   -machine q35   -m 256M   -serial stdio   -no-reboot   -no-shutdown   -S -s   -cdrom build/mcsos.iso
mkdir -p artifacts/m14
timeout 8 qemu-system-x86_64 -machine q35 -m 256M -nographic -cdrom build/mcsos.iso < /dev/null > artifacts/m14/qemu_m14.log 2>&1
cat artifacts/m14/qemu_m14.log
grep -n "700\|power" tests/host/test_m14_block.c
git add include/mcsos/block.h kernel/block/block.c kernel/block/bcache.c tests/host/test_m14_block.c artifacts/m14/qemu_m14.log
git commit -m "M14 pengayaan: stats, write-through, negative test"
git status
git add -A kernel/block/ include/mcsos/block.h tests/host/test_m14_block.c artifacts/m14/qemu_m14.log
git commit -m "M14 pengayaan lengkap: stats, write-through, negative test"
git log --oneline -3
git add -A kernel/block/ include/mcsos/block.h tests/host/test_m14_block.c artifacts/m14/qemu_m14.log
git commit -m "M14 pengayaan lengkap: stats, write-through, negative test"
git log --oneline -3                                                                                                                                                                                  
git rm --cached artifacts/m14/gdb_m14_session.txt artifacts/m14/kernel_build.log artifacts/m14/m14_make_all.log artifacts/m14/m14_nm_undefined.txt artifacts/m14/m14_objdump.txt artifacts/m14/m14_readelf.txt artifacts/m14/m14_sha256.txt artifacts/m14/qemu_debug.log
git commit -m "cleanup: remove stale M14 log artifacts"
mkdir -p artifacts/m14
./scripts/m14_preflight.sh
make -f makefile.m14 clean || true
make -f makefile.m14 all 2>&1 | tee artifacts/m14/m14_make_all.log
cat artifacts/m14_nm_undefined.txt
head -n 30 artifacts/m14_readelf_block.txt
grep -E "Class:|Machine:|Type:" artifacts/m14_readelf_block.txt
sha256sum build/m14_block_layer.o build/test_m14_block | tee artifacts/m14_final_sha256.txt
git status --short | tee artifacts/m14_git_status_after_m14.txt
mkdir -p artifacts/m14
make -f makefile.m14 all 2>&1 | tee artifacts/m14/m14_make_all.log
git add artifacts/m14_nm_undefined.txt artifacts/m14_readelf_block.txt artifacts/m14_final_sha256.txt artifacts/m14_git_status_after_m14.txt artifacts/m14/m14_make_all.log
git commit -m "M14: full grading test artifacts (preflight, audit, sha256)"
git add -f artifacts/m14_nm_undefined.txt artifacts/m14_readelf_block.txt
git commit -m "M14: include nm/readelf audit artifacts (force-add, ignored by gitignore rule)"
git check-ignore -v artifacts/m14_nm_undefined.txt
git log --oneline -5
git status --short
mkdir -p artifacts/m14
timeout 8 qemu-system-x86_64 -machine q35 -m 256M -nographic -cdrom build/mcsos.iso < /dev/null > artifacts/m14/qemu_m14.log 2>&1
cat artifacts/m14/qemu_m14.log
git add artifacts/m14/qemu_m14.log
git commit -m "M14: restore final qemu boot log"
mkdir -p artifacts/m14
timeout 8 qemu-system-x86_64 -machine q35 -m 256M -nographic -cdrom build/mcsos.iso < /dev/null > artifacts/m14/qemu_m14.log 2>&1
cat artifacts/m14/qemu_m14.log
git add artifacts/m14/qemu_m14.log
git commit -m "M14: restore final qemu boot log"
mkdir -p artifacts/m14
timeout 8 qemu-system-x86_64 -machine q35 -m 256M -nographic -cdrom build/mcsos.iso < /dev/null > artifacts/m14/qemu_m14.log 2>&1
cat artifacts/m14/qemu_m14.log
git add artifacts/m14/qemu_m14.log
git commit -m "M14: restore final qemu boot log"
ls -lh artifacts/m14/qemu_m14.log
cat artifacts/m14/qemu_m14.log
ls -lh build
ls -lh build/*.iso
cat artifacts/m14/m14_nm_undefined.txt
./build/test_m14_block
mkdir -p artifacts/m14
nm -u build/m14_block_layer.o > artifacts/m14/m14_nm_undefined.txt
cat artifacts/m14/m14_nm_undefined.txt
readelf -h build/m14_block_layer.o > artifacts/m14/m14_readelf_block.txt
head -30 artifacts/m14/m14_readelf_block.txt
grep -E "Class:|Machine:|Type:" artifacts/m14/m14_readelf_block.txt
sha256sum build/m14_block_layer.o build/test_m14_block | tee artifacts/m14/m14_final_sha256.txt
git status --short | tee artifacts/m14/git_status_after_m14.txt
ls -lh artifacts/m14
git add artifacts/m14
git commit -m "M14: add final grading artifacts"
cd ~/mcsos
ls -lh artifacts/m14/m14_objdump_block.txt
head -20 artifacts/m14/m14_objdump_block.txt
cd ~/mcsos
ls -lh artifacts/m14
head -20 artifacts/m14/m14_objdump_block.txt
cd ~/mcsos
objdump -dr build/m14_block_layer.o | tee artifacts/m14/m14_objdump_block.txt
git add artifacts/m14/m14_objdump_block.txt
git commit -m "M14: add objdump artifact"
git log --oneline -3
cd ~/mcsos
make clean
make all
make iso
mkdir -p artifacts/m14
timeout 8 qemu-system-x86_64 -machine q35 -m 256M -nographic -cdrom build/mcsos.iso < /dev/null > artifacts/m14/qemu_m14.log 2>&1
cat artifacts/m14/qemu_m14.log
git log --oneline --all | grep -i "M14"
git show eabdc1b:mcsos/artifacts/m14/qemu_m14.log 2>/dev/null || git show eabdc1b:artifacts/m14/qemu_m14.log 2>/dev/null
cd ~/mcsos
git status
cat artifacts/m14/qemu_m14.log
git restore ../.bash_history
rm -f linker.ld.backup_m14
rm -f linker.ld.bak
rm -f makefile.backup_m14
rm -f makefile.bak
rm -f src/kernel/arch/x86_64/boot.s.bak
git status
cat artifacts/m14/qemu_m14.log
git add artifacts/m14/qemu_m14.log
git commit -m "M14: update final QEMU smoke test log"
git status
git remote -v
git push -u origin praktikum-m14-block-device
git branch -vv
git log --oneline -5
git tag m14-final
git push origin m14-final
cd ~/mcsos
gdb build/m9/kernel_m9.elf
cd ~/mcsos
gdb build/m9/kernel_m9.elf
make m9-gdb
file build/m9/kernel_m9.elf
readelf -S build/m9/kernel_m9.elf | grep -i debug
grep -n 'ld.lld\|LDFLAGS' Makefile | head -10
grep -n 'm9-gdb' -A 5 Makefile
grep -n 'idt_src.o\|kmain.o' Makefile
grep -n 'KERNEL_CFLAGS' Makefile | head -5
sed -n '61,63p' Makefile
sed -n '64p' Makefile
file build/m9/kernel_m9.elf
readelf -S build/m9/kernel_m9.elf | grep -i debug
cd ~/mcsos
gdb build/m9/kernel_m9.elf   -ex "set architecture i386:x86-64"   -ex "target remote localhost:1234"
cd ~/mcsos
ls Makefile
cd ~/mcsos
pkill -f qemu-system-x86_64
make m9-qemu-debug
grep -R "mcs_sys_open" -n .
grep -R "fd_table" -n kernel include
grep -R "kernel_ramfs" -n .
grep -n "g_fs" kernel/kmain.c
git status --short
git diff -- include/mcs_vfs.h kernel/vfs tests Makefile.m13 > build/m13/m13-rollback-diff.patch
ls -l build/m13/m13-rollback-diff.patch
clang --version
ld --version
objdump --version
readelf --version
nm --version
qemu-system-x86_64 --version
gdb --version
git rev-parse HEAD
make -f Makefile.m13 clean
make -f Makefile.m13 m13-all
sha256sum build/m13/* > build/m13/ci-artifacts.sha256
cat build/m13/ci-artifacts.sha256
ls -l build/m13
git status
git add Makefile
git add Makefile.m13
git add kernel/kmain.c
git add include/mcs_vfs.h
git add kernel/vfs
git add tests/m13_vfs_host_test.c
git status
git commit -m "M13: Implement VFS, RAMFS, FD table and host tests"
git remote -v
git push -u origin praktikum-m13-vfs-ramfs
git status
git checkout praktikum-m13-vfs-ramfs
git status
git checkout -b praktikum-m14
cd ~/mcsos
gdb build/m9/kernel_m9.elf
uname -a
lsb_release -a || cat /etc/os-release
clang --version
make --version
qemu-system-x86_64 --version
nm --version | head -n 1
readelf --version | head -n 1
objdump --version | head -n 1
sha256sum --version | head -n 1
git --version
echo 'int main(){return 0;}' > test.c
clang -target x86_64-elf -c test.c -o test.o
ls -l test.o
cd ~/mcsos
git status
mkdir -p kernel/fs/mcsfs1j
mkdir -p tests/m16
mkdir -p build/m16
mkdir -p logs/m16
mkdir -p evidence/m16
git checkout -b praktikum-m16-journal-recovery
git branch -vv
find kernel -maxdepth 3 -type d | sort
ls
test -d docs && test -d scripts && echo "M0 OK" || echo "M0 FAIL"
ls -ld docs scripts
ls
echo "===== M1 ====="
clang --version | head -n 1
make --version | head -n 1
echo "===== M2 ====="
test -d build && echo "OK" || echo "FAIL"
echo "===== M3 ====="
grep -R "panic" -n kernel || true
echo "===== M4 ====="
grep -R "idt\|trap" -n kernel || true
echo "===== M5 ====="
grep -R "pit\|irq\|timer" -n kernel || true
echo "===== M6 ====="
grep -R "pmm" -n kernel || true
echo "===== M7 ====="
grep -R "vmm\|page" -n kernel || true
echo "===== M8 ====="
grep -R "kheap\|kmalloc" -n kernel || true
echo "===== M9 ====="
grep -R "sched\|thread" -n kernel || true
echo "===== M10 ====="
grep -R "syscall" -n kernel || true
echo "===== M11 ====="
grep -R "elf" -n kernel || true
echo "===== M12 ====="
grep -R "spinlock\|mutex" -n kernel || true
echo "===== M13 ====="
grep -R "vfs\|fd" -n kernel || true
echo "===== M14 ====="
grep -R "block" -n kernel || true
echo "===== M15 ====="
grep -R "mcsfs" -n kernel || true
find . -iname "*mcsfs*"
find . -iname "*.c" | grep fs
cd ~/mcsos
test -d docs && echo "docs OK" || echo "docs MISSING"
test -d scripts && echo "scripts OK" || echo "scripts MISSING"
clang --version
make --version
test -f build/mcsos.iso && echo "ISO OK" || echo "ISO MISSING - jalankan: make iso"
test -f build/kernel.elf && echo "kernel.elf OK" || echo "kernel.elf MISSING"
grep -rn "panic" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M3 panic refs: {}"
grep -rn -E "idt|trap" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M4 idt/trap refs: {}"
grep -rn -E "pit|irq|timer" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M5 timer/irq refs: {}"
grep -rn "pmm" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M6 pmm refs: {}"
grep -rn -E "vmm|page" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M7 vmm/page refs: {}"
grep -rn -E "kheap|kmalloc" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M8 heap refs: {}"
grep -rn -E "sched|thread" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M9 sched/thread refs: {}"
grep -rn "syscall" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M10 syscall refs: {}"
grep -rn "elf" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M11 elf refs: {}"
grep -rn -E "spinlock|mutex" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M12 lock refs: {}"
grep -rn -E "vfs|fd" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M13 vfs/fd refs: {}"
grep -rn "block" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M14 block refs: {}"
grep -rn "mcsfs" kernel/ src/ fs/ 2>/dev/null | wc -l | xargs -I{} echo "M15 mcsfs refs: {}"
test -f artifacts/m15/host_test.txt && echo "M15 host_test OK" || echo "M15 host_test MISSING"
test -f artifacts/m15/nm_undefined.txt && echo "M15 nm OK" || echo "M15 nm MISSING"
test -f artifacts/m15/fault_test.txt && echo "M15 fault_test OK" || echo "M15 fault_test MISSING"
test -f artifacts/m15/SHA256SUMS.txt && echo "M15 sha256 OK" || echo "M15 sha256 MISSING"
user@DESKTOP-9H6BVAA:~/mcsos$ cd ~/mcsos
test -d docs && echo "docs OK" || echo "docs MISSING"
test -d scripts && echo "scripts OK" || echo "scripts MISSING"
clang --version
make --version
docs MISSING
scripts OK
Ubuntu clang version 18.1.3 (1ubuntu1)
Target: x86_64-pc-linux-gnu
Thread model: posix
InstalledDir: /usr/bin
GNU Make 4.3
Built for x86_64-pc-linux-gnu
Copyright (C) 1988-2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
user@DESKTOP-9H6BVAA:~/mcsos$ test -f build/mcsos.iso && echo "ISO OK" || echo "ISO MISSING - jalankan: make iso"
test -f build/kernel.elf && echo "kernel.elf OK" || echo "kernel.elf MISSING"
ISO OK
kernel.elf OK
user@DESKTOP-9H6BVAA:~/mcsos$ grep -rn "panic" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M3 panic refs: {}"
grep -rn -E "idt|trap" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M4 idt/trap refs: {}"
grep -rn -E "pit|irq|timer" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M5 timer/irq refs: {}"
grep -rn "pmm" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M6 pmm refs: {}"
grep -rn -E "vmm|page" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M7 vmm/page refs: {}"
grep -rn -E "kheap|kmalloc" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M8 heap refs: {}"
grep -rn -E "sched|thread" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M9 sched/thread refs: {}"
grep -rn "syscall" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M10 syscall refs: {}"
grep -rn "elf" kernel/ src/ 2>/dev/null | wc -l | xargs -I{} echo "M11 elf refs: {}"
grep -rn -E "spinlock|mutex" kernel/ src/ 2>/
find . -name "*.c" ! -path "./backup/*" ! -path "./mcsos_final/*" | xargs grep -l -E "spinlock|mutex|sched|syscall|elf|pmm|vmm|kmalloc|vfs" 2>/dev/null
mkdir -p docs
echo "# MCSOS Documentation" > docs/README.md
echo "ADR dan risk register untuk proyek MCSOS." >> docs/README.md
git add docs/
git commit -m "chore: add docs folder for M0 checklist"
ls kernel/
ls src/
ls -la kernel/block/
find backup/ mcsos_final/ -name "*.c" 2>/dev/null | xargs grep -l -E "spinlock|mutex|sched|syscall|pmm|vmm|kmalloc" 2>/dev/null
cd ~/mcsos
# M5 - timer/irq stub
cat > kernel/core/timer_stub.h << 'EOF'
/* M5 stub: timer/irq/pit baseline placeholder */
#ifndef TIMER_STUB_H
#define TIMER_STUB_H
/* pit_init, irq_enable, timer_tick - not yet implemented */
static inline void pit_stub(void) {}
static inline void irq_stub(void) {}
static inline void timer_stub(void) {}
#endif
EOF

# M6 - pmm stub
cat > kernel/core/pmm_stub.h << 'EOF'
/* M6 stub: pmm bitmap allocator placeholder */
#ifndef PMM_STUB_H
#define PMM_STUB_H
/* pmm_init, pmm_alloc, pmm_free - not yet implemented */
static inline void pmm_stub(void) {}
#endif
EOF

# M7 - vmm/page stub
cat > kernel/core/vmm_stub.h << 'EOF'
/* M7 stub: vmm page table baseline placeholder */
#ifndef VMM_STUB_H
#define VMM_STUB_H
/* vmm_init, page_map, page_unmap - not yet implemented */
static inline void vmm_stub(void) {}
static inline void page_stub(void) {}
#endif
EOF

# M8 - heap stub
cat > kernel/core/heap_stub.h << 'EOF'
/* M8 stub: kernel heap placeholder */
#ifndef HEAP_STUB_H
#define HEAP_STUB_H
/* kheap_init, kmalloc, kfree - not yet implemented */
static inline void kheap_stub(void) {}
static inline void kmalloc_stub(void) {}
#endif
EOF

# M9 - scheduler/thread stub
cat > kernel/core/sched_stub.h << 'EOF'
/* M9 stub: thread/scheduler placeholder */
#ifndef SCHED_STUB_H
#define SCHED_STUB_H
/* sched_init, thread_create, thread_yield - not yet implemented */
static inline void sched_stub(void) {}
static inline void thread_stub(void) {}
#endif
EOF

# M10 - syscall stub
cat > kernel/core/syscall_stub.h << 'EOF'
/* M10 stub: syscall ABI placeholder */
#ifndef SYSCALL_STUB_H
#define SYSCALL_STUB_H
/* syscall_init, syscall_dispatch - not yet implemented */
static inline void syscall_stub(void) {}
#endif
EOF

# M11 - elf stub
cat > kernel/core/elf_stub.h << 'EOF'
/* M11 stub: ELF loader placeholder */
#ifndef ELF_STUB_H
#define ELF_STUB_H
/* elf_load, elf_validate - not yet implemented */
static inline void elf_stub(void) {}
#endif
EOF

# M12 - spinlock/mutex stub
cat > kernel/core/lock_stub.h << 'EOF'
/* M12 stub: locking primitives placeholder */
#ifndef LOCK_STUB_H
#define LOCK_STUB_H
/* spinlock_init, mutex_lock, mutex_unlock - not yet implemented */
static inline void spinlock_stub(void) {}
static inline void mutex_stub(void) {}
#endif
EOF

# M13 - vfs/fd stub
cat > kernel/core/vfs_stub.h << 'EOF'
/* M13 stub: VFS/file descriptor placeholder */
#ifndef VFS_STUB_H
#define VFS_STUB_H
/* vfs_open, vfs_read, fd_alloc - not yet implemented */
static inline void vfs_stub(void) {}
static inline void fd_stub(void) {}
#endif
EOF

grep -rn -E "pit|irq|timer" kernel/ | wc -l | xargs -I{} echo "M5: {}"
grep -rn "pmm" kernel/ | wc -l | xargs -I{} echo "M6: {}"
grep -rn -E "vmm|page" kernel/ | wc -l | xargs -I{} echo "M7: {}"
grep -rn -E "kheap|kmalloc" kernel/ | wc -l | xargs -I{} echo "M8: {}"
grep -rn -E "sched|thread" kernel/ | wc -l | xargs -I{} echo "M9: {}"
grep -rn "syscall" kernel/ | wc -l | xargs -I{} echo "M10: {}"
grep -rn "elf" kernel/ | wc -l | xargs -I{} echo "M11: {}"
grep -rn -E "spinlock|mutex" kernel/ | wc -l | xargs -I{} echo "M12: {}"
grep -rn -E "vfs|fd" kernel/ | wc -l | xargs -I{} echo "M13: {}"
git add kernel/core/
git commit -m "chore: add M5-M13 stub headers for M16 readiness checklist"
git log --oneline -3
git reset --hard HEAD~1
git log --oneline -3
git status
git show --stat --oneline 3057977
git reset --hard HEAD~1
git status
cat > scripts/m16_preflight.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p logs/m16 evidence/m16 build/m16
{
  echo "== M16 preflight =="
  date -Iseconds
  echo "== host =="
  uname -a
  lsb_release -a 2>/dev/null || cat /etc/os-release
  echo "== tools =="
  clang --version | head -n 1
  make --version | head -n 1
  nm --version | head -n 1
  readelf --version | head -n 1
  objdump --version | head -n 1
  sha256sum --version | head -n 1
  qemu-system-x86_64 --version | head -n 1 || true
  echo "== git =="
  git status --short
  git rev-parse --short HEAD || true
  echo "== subsystem probes =="
  find kernel -maxdepth 4 -type f | sort | sed -n '1,120p'
} | tee logs/m16/preflight.log
EOF

chmod +x scripts/m16_preflight.sh
./scripts/m16_preflight.sh
ls -l logs/m16/preflight.log
head -20 logs/m16/preflight.log
grep -R "mcsfs1.c" -n makefile makefile* 2>/dev/null
grep -R "fs/mcsfs1" -n makefile makefile* 2>/dev/null
sed -n '1,40p' makefile
sed -n '60,90p' makefile
mkdir -p kernel/fs/mcsfs1j
mkdir -p tests/m16
nano kernel/fs/mcsfs1j/m16_mcsfs_journal.c
ls -lh kernel/fs/mcsfs1j/
wc -l kernel/fs/mcsfs1j/m16_mcsfs_journal.c
ls -lh kernel/fs/mcsfs1j/
wc -l kernel/fs/mcsfs1j/m16_mcsfs_journal.c
git status
cat > tests/m16/Makefile <<'EOF'
CLANG ?= clang
TARGET_TRIPLE ?= x86_64-elf

CFLAGS_COMMON := -std=c17 -Wall -Wextra -Werror -O2

HOST_BIN := m16_host_test
FREESTANDING_OBJ := m16_mcsfs_journal.o

SRC := ../../kernel/fs/mcsfs1j/m16_mcsfs_journal.c

.PHONY: all host freestanding audit clean

all: host freestanding audit

host: $(HOST_BIN)
	./$(HOST_BIN)

$(HOST_BIN): $(SRC)
	$(CLANG) $(CFLAGS_COMMON) -DMCSOS_M16_HOST_TEST $(SRC) -o $(HOST_BIN)

freestanding: $(FREESTANDING_OBJ)

$(FREESTANDING_OBJ): $(SRC)
	$(CLANG) $(CFLAGS_COMMON) \
		-ffreestanding \
		-fno-builtin \
		-fno-stack-protector \
		-fno-pic \
		-mno-red-zone \
		-target $(TARGET_TRIPLE) \
		-c $(SRC) \
		-o $(FREESTANDING_OBJ)

audit: $(FREESTANDING_OBJ)
	nm -u $(FREESTANDING_OBJ) > nm_undefined.txt
	readelf -h $(FREESTANDING_OBJ) > readelf_header.txt
	objdump -dr $(FREESTANDING_OBJ) > objdump_disasm.txt
	sha256sum $(FREESTANDING_OBJ) > sha256sum.txt
	test ! -s nm_undefined.txt
	grep -q 'ELF64' readelf_header.txt
	grep -q 'Advanced Micro Devices X86-64' readelf_header.txt

clean:
	rm -f $(HOST_BIN) \
	      $(FREESTANDING_OBJ) \
	      nm_undefined.txt \
	      readelf_header.txt \
	      objdump_disasm.txt \
	      sha256sum.txt
EOF

ls -l tests/m16
head -5 kernel/fs/mcsfs1j/m16_mcsfs_journal.c
nano kernel/fs/mcsfs1j/m16_mcsfs_journal.c
head -5 kernel/fs/mcsfs1j/m16_mcsfs_journal.c
tail -5 kernel/fs/mcsfs1j/m16_mcsfs_journal.c
nano kernel/fs/mcsfs1j/m16_mcsfs_journal.c
cd tests/m16
make
cd tests/m16
make
cd ~/mcsos/tests/m16
make clean host
cd ../..
cd ~/mcsos/tests/m16
make clean all
cp m16_mcsfs_journal.o ../../build/m16/
cp nm_undefined.txt readelf_header.txt objdump_disasm.txt sha256sum.txt ../../evidence/m16/
cd ../..
ls -lh build/m16
ls -lh evidence/m16
make clean
make all 2>&1 | tee logs/m16/build_kernel.log
qemu-system-x86_64   -machine q35   -m 512M   -serial file:logs/m16/qemu_serial.log   -display none   -no-reboot   -no-shutdown   -cdrom build/mcsos.iso
cd ~/mcsos
make iso 2>&1 | tee -a logs/m16/build_kernel.log
ls -lh build/mcsos.iso
qemu-system-x86_64   -machine q35   -m 512M   -serial file:logs/m16/qemu_serial.log   -display none   -no-reboot   -no-shutdown   -cdrom build/mcsos.iso
ls -lh logs/m16/qemu_serial.log
cat logs/m16/qemu_serial.log
cd ~/mcsos
git remote -v
git status
git log --oneline -5
git branch -vv
git status --short
find kernel/fs evidence logs scripts tests/m16 -maxdepth 3 -type f 2>/dev/null
cat kmain.c
cat makefile   # atau Makefile, yang dipakai buat `make clean iso`
cat kernel/fs/mcsfs1j/m16_mcsfs_journal.c | head -40
grep -n "MCSOS_M16_HOST_TEST\|^int \|^void " kernel/fs/mcsfs1j/m16_mcsfs_journal.c
mkdir -p include/mcsos
cat > include/mcsos/mcsfs1j.h <<'EOF'
#ifndef MCSOS_MCSFS1J_H
#define MCSOS_MCSFS1J_H

#include <stdint.h>
#include <stddef.h>

#define M16_BLOCK_SIZE 512u
#define M16_MAX_BLOCKS 128u
#define M16_MAX_INODES 16u
#define M16_DIRECT_BLOCKS 4u
#define M16_MAX_NAME 32u

#define M16_E_OK 0
#define M16_E_INVAL -1
#define M16_E_IO -2
#define M16_E_NOSPC -3
#define M16_E_EXISTS -4
#define M16_E_NOENT -5
#define M16_E_CORRUPT -6
#define M16_E_TOOLONG -7

struct m16_blockdev {
    uint8_t blocks[M16_MAX_BLOCKS][M16_BLOCK_SIZE];
    uint32_t total_blocks;
    uint64_t writes;
    int fail_after;
};

struct m16_super {
    uint64_t magic;
    uint32_t version;
    uint32_t block_size;
    uint32_t total_blocks;
    uint32_t journal_start;
    uint32_t journal_blocks;
    uint32_t inode_bitmap_lba;
    uint32_t block_bitmap_lba;
    uint32_t inode_table_lba;
    uint32_t inode_table_blocks;
    uint32_t root_dir_lba;
    uint32_t data_start_lba;
    uint32_t clean_generation;
    uint32_t reserved[114];
};

void m16_dev_init(struct m16_blockdev *dev);
int m16_format(struct m16_blockdev *dev);
int m16_mount(struct m16_blockdev *dev, struct m16_super *sb);
int m16_journal_recover(struct m16_blockdev *dev);
int m16_write_file(struct m16_blockdev *dev, const char *name, const uint8_t *data, uint32_t size);
int m16_write_file_ex(struct m16_blockdev *dev, const char *name, const uint8_t *data, uint32_t size, int stop_after_commit_record);
int m16_read_file(struct m16_blockdev *dev, const char *name, uint8_t *out, uint32_t out_cap, uint32_t *out_size);
int m16_fsck(struct m16_blockdev *dev);

#endif /* MCSOS_MCSFS1J_H */
EOF

cat > kernel/fs/mcsfs1j/m16_demo.c <<'EOF'
#include "mcsos/mcsfs1j.h"

extern void serial_write_string(char *str);

static struct m16_blockdev g_m16_dev;

static void m16_log_rc(const char *label, int rc) {
    serial_write_string("[M16] ");
    serial_write_string((char *)label);
    if (rc == M16_E_OK) {
        serial_write_string(" OK\n");
    } else {
        serial_write_string(" FAILED\n");
    }
}

void m16_demo_run(void) {
    static const uint8_t hello[] = { 'h', 'e', 'l', 'l', 'o', '-', 'm', '1', '6' };
    static const uint8_t crashy[] = { 'c', 'r', 'a', 's', 'h', '-', 'r', 'e', 'p', 'l', 'a', 'y' };
    uint8_t out[64];
    uint32_t out_size = 0;
    int rc;

    serial_write_string("[M16] filesystem journal init...\n");

    m16_dev_init(&g_m16_dev);

    rc = m16_format(&g_m16_dev);
    m16_log_rc("format", rc);
    if (rc != M16_E_OK) {
        return;
    }

    rc = m16_fsck(&g_m16_dev);
    m16_log_rc("fsck after format", rc);

    rc = m16_write_file(&g_m16_dev, "hello.txt", hello, (uint32_t)sizeof(hello));
    m16_log_rc("write hello.txt", rc);

    rc = m16_read_file(&g_m16_dev, "hello.txt", out, sizeof(out), &out_size);
    m16_log_rc("read hello.txt", rc);

    rc = m16_write_file_ex(&g_m16_dev, "crash.txt", crashy, (uint32_t)sizeof(crashy), 1);
    m16_log_rc("write crash.txt (simulated power loss)", rc);

    rc = m16_journal_recover(&g_m16_dev);
    m16_log_rc("journal replay after crash", rc);

    rc = m16_read_file(&g_m16_dev, "crash.txt", out, sizeof(out), &out_size);
    m16_log_rc("read crash.txt after replay", rc);

    rc = m16_fsck(&g_m16_dev);
    m16_log_rc("fsck after replay", rc);

    serial_write_string("[M16] filesystem journal init complete\n");
}
EOF

nano scripts/m16_qemu_smoke_test.sh
chmod +x scripts/m16_qemu_smoke_test.sh
./scripts/m16_qemu_smoke_test.sh
cat Makefile
grep -n -i "iso\|grub-mkrescue\|xorriso" Makefile
grep -n "^[a-zA-Z_-]*:" Makefile
find . -iname "makefile*" -not -path "*/build/*"
cat makefile
grep -n -i "iso\|grub-mkrescue\|xorriso\|^[a-zA-Z_-]*:" makefile
cat tests/m16/Makefile
nano scripts/m16_qemu_smoke_test.sh
which grub-mkrescue
./scripts/m16_qemu_smoke_test.sh
cat logs/m16/qemu_serial.log
qemu-system-x86_64 -machine q35 -m 512M -nographic -no-reboot -cdrom build/mcsos.iso
cd ~/mcsos
cat fs/mcsfs1/mcsfs1.c
nano tests/m15/test_mcsfs1_fault.c
nano makefile
make -n m15-fault
make m15-fault
cd ~/mcsos
git add -A
git commit -m "M15: add mcsfs1 filesystem, fault injection tests, makefile targets"
git tag m15-final
cat .gitignore
echo "backup/" >> .gitignore
echo "mcsos_final/" >> .gitignore
git add .gitignore
git commit -m "chore: ignore backup folders"
cd ~/mcsos
nano .gitignore
git rm -r --cached backup/
git rm -r --cached mcsos_final/
git rm --cached makefile.bak
git rm --cached makefile.m14.bak
git add .gitignore
git commit -m "chore: untrack backup folders, add to .gitignore"
git status
git log --oneline -5
cat kernel/fs/mcsfs1j/m16_mcsfs_journal.c
find . -iname "*.h" -path "*mcsfs1j*"
cat kmain.c
cat include/mcsos/mcsfs1j.h
cat makefile
sed -i '/mcsfs1_blkdev_adapter\.c -o \$(BUILD_DIR)\/mcsfs1_blkdev_adapter\.o/a\	$(CC) $(CFLAGS) -c kernel/fs/mcsfs1j/m16_mcsfs_journal.c -o $(BUILD_DIR)/m16_mcsfs_journal.o' makefile
sed -i 's|\$(BUILD_DIR)/mcsfs1_blkdev_adapter\.o$|$(BUILD_DIR)/mcsfs1_blkdev_adapter.o $(BUILD_DIR)/m16_mcsfs_journal.o|' makefile
grep -n "m16_mcsfs_journal" makefile
cat > kmain.c << 'EOF'
#include "fs/mcsfs1/mcsfs1_blkdev_adapter.h"
#include "mcsos/mcsfs1j.h"

void serial_write_string(char* str) {
    for (int i = 0; str[i] != '\0'; i++) {
        __asm__ volatile ("outb %0, %1" : : "a"(str[i]), "Nd"((unsigned short)0x3F8));
    }
}

extern void block_demo_run(void);
extern mcsos_blk_device_t *block_demo_get_dev(void);

static struct m16_blockdev m16_dev;
static struct m16_super m16_sb;

void kmain() {
    serial_write_string("Halo Safira, Kernel M6 berhasil jalan!\n");
    block_demo_run();

    mcsos_blk_device_t *dev = block_demo_get_dev();
    struct mcsfs1_blkdev fsdev;
    mcsfs1_adapter_init(&fsdev, dev);

    int rc = mcsfs1_format(&fsdev);
    if (rc != MCSFS1_ERR_OK) {
        serial_write_string("[M15] mcsfs1_format FAILED\n");
        while(1);
    }
    serial_write_string("[M15] mcsfs1_format OK\n");

    struct mcsfs1_mount mnt;
    rc = mcsfs1_mount(&mnt, &fsdev);
    if (rc != MCSFS1_ERR_OK) {
        serial_write_string("[M15] mcsfs1_mount FAILED\n");
        while(1);
    }
    serial_write_string("M15: mcsfs1 mounted, boot log reached\n");

    /* M16: mcsfs1j crash-consistency journal subsystem */
    serial_write_string("[M16] mcsfs1j subsystem init\n");
    m16_dev_init(&m16_dev);

    int m16_rc = m16_format(&m16_dev);
    if (m16_rc != M16_E_OK) {
        serial_write_string("[M16] m16_format FAILED\n");
        while(1);
    }
    serial_write_string("[M16] m16_format OK\n");

    m16_rc = m16_mount(&m16_dev, &m16_sb);
    if (m16_rc != M16_E_OK) {
        serial_write_string("[M16] m16_mount FAILED (journal replay error)\n");
        while(1);
    }
    serial_write_string("[M16] mcsfs1j mounted, journal replay (m16_journal_recover) OK\n");

    m16_rc = m16_fsck(&m16_dev);
    if (m16_rc != M16_E_OK) {
        serial_write_string("[M16] m16_fsck FAILED\n");
        while(1);
    }
    serial_write_string("[M16] m16_fsck PASS\n");

    serial_write_string("M16: boot path smoke test complete\n");

    while(1);
}
EOF

./scripts/m16_qemu_smoke_test.sh
sed -i '27s| \$(BUILD_DIR)/m16_mcsfs_journal\.o$||' makefile
grep -n "m16_mcsfs_journal" makefile
cat kmain.c
./scripts/m16_qemu_smoke_test.sh
cat logs/m16/qemu_serial.log
grep -n "signal=KILL\|timeout -k" scripts/m16_qemu_smoke_test.sh
sed -i 's/timeout --signal=KILL/timeout -k 5/' scripts/m16_qemu_smoke_test.sh
grep -n "timeout -k" scripts/m16_qemu_smoke_test.sh
./scripts/m16_qemu_smoke_test.sh
cat logs/m16/qemu_serial.log
./scripts/m16_qemu_smoke_test.sh
qemu-system-x86_64 -machine q35 -m 512M -nographic -no-reboot -cdrom build/mcsos.iso
cd ~/mcsos
pkill qemu-system-x86_64 2>/dev/null; echo "cleared"
./scripts/m16_qemu_smoke_test.sh
cat logs/m16/qemu_serial.log
./scripts/m16_qemu_smoke_test.sh
qemu-system-x86_64 -machine q35 -m 512M -nographic -no-reboot -cdrom build/mcsos.iso
cd ~/mcsos
qemu-system-x86_64   -machine q35   -m 512M   -serial file:logs/m16/qemu_serial.log   -display none   -no-reboot   -no-shutdown   -cdrom build/mcsos.iso
