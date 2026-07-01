#include "fs/mcsfs1/mcsfs1_blkdev_adapter.h"

void serial_write_string(char* str) {
    for (int i = 0; str[i] != '\0'; i++) {
        __asm__ volatile ("outb %0, %1" : : "a"(str[i]), "Nd"((unsigned short)0x3F8));
    }
}

extern void block_demo_run(void);
extern mcsos_blk_device_t *block_demo_get_dev(void);

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

    while(1);
}
