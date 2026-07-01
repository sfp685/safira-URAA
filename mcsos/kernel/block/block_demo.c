#include "mcsos/block.h"

extern void serial_write_string(char *str);

static uint8_t g_ram0_backing[512u * 32u];
static mcsos_blk_device_t g_ram0_dev;
static mcsos_ramblk_t g_ram0_ram;

void block_demo_run(void) {
    mcsos_blk_registry_reset();

    mcsos_blk_status_t st = mcsos_ramblk_init(&g_ram0_dev, &g_ram0_ram,
                                               "ram0",
                                               g_ram0_backing,
                                               sizeof(g_ram0_backing),
                                               512u);
    if (st != MCSOS_BLK_OK) {
        serial_write_string("[M14] ramblk init FAILED\n");
        return;
    }

    st = mcsos_blk_register(&g_ram0_dev);
    if (st != MCSOS_BLK_OK) {
        serial_write_string("[M14] ramblk register FAILED\n");
        return;
    }

    serial_write_string("M14: block layer initialized\n");
    serial_write_string("[M14] block device registered: ");
    serial_write_string(g_ram0_dev.name);
    serial_write_string("\n");
}
mcsos_blk_device_t *block_demo_get_dev(void) {
    return &g_ram0_dev;
}
