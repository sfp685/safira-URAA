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
