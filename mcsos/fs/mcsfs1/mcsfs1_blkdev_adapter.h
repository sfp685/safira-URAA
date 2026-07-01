#ifndef MCSFS1_BLKDEV_ADAPTER_H
#define MCSFS1_BLKDEV_ADAPTER_H
#include "mcsos/block.h"
#include "fs/mcsfs1/mcsfs1.h"
void mcsfs1_adapter_init(struct mcsfs1_blkdev *fsdev, mcsos_blk_device_t *dev);
#endif
