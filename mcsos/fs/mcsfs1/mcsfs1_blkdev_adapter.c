#include "mcsos/block.h"
#include "fs/mcsfs1/mcsfs1.h"

static int mcsfs1_adapter_read(void *ctx, uint32_t lba, void *buf512) {
    mcsos_blk_device_t *dev = (mcsos_blk_device_t *)ctx;
    return (mcsos_blk_read(dev, (uint64_t)lba, 1u, buf512) == MCSOS_BLK_OK)
        ? MCSFS1_ERR_OK : MCSFS1_ERR_IO;
}

static int mcsfs1_adapter_write(void *ctx, uint32_t lba, const void *buf512) {
    mcsos_blk_device_t *dev = (mcsos_blk_device_t *)ctx;
    return (mcsos_blk_write(dev, (uint64_t)lba, 1u, buf512) == MCSOS_BLK_OK)
        ? MCSFS1_ERR_OK : MCSFS1_ERR_IO;
}

static int mcsfs1_adapter_flush(void *ctx) {
    mcsos_blk_device_t *dev = (mcsos_blk_device_t *)ctx;
    return (mcsos_blk_flush(dev) == MCSOS_BLK_OK)
        ? MCSFS1_ERR_OK : MCSFS1_ERR_IO;
}

void mcsfs1_adapter_init(struct mcsfs1_blkdev *fsdev, mcsos_blk_device_t *dev) {
    fsdev->ctx = dev;
    fsdev->block_count = (uint32_t)dev->block_count;
    fsdev->read = mcsfs1_adapter_read;
    fsdev->write = mcsfs1_adapter_write;
    fsdev->flush = mcsfs1_adapter_flush;
}
