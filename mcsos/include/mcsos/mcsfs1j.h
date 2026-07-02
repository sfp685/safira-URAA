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
