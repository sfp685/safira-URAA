#include <stdint.h>
#include <mcsos/kernel/log.h>
#include "mcsos_thread.h"
#include "mcs_vfs.h"

void m12_sync_selftest(void);
void mcs_vfs_set_active_ramfs_for_test(mcs_ramfs_t *fs);

static uint8_t stack_a[4096];
static uint8_t stack_b[4096];
static mcsos_thread_t boot_thread;
static mcsos_thread_t thread_a;
static mcsos_thread_t thread_b;
static mcsos_scheduler_t g_sched;

static void thread_a_entry(void *arg) { (void)arg; }
static void thread_b_entry(void *arg) { (void)arg; }

static mcs_ramfs_t   g_fs;
static mcs_process_t g_proc;
static char          g_buf[32];

static void m13_vfs_smoke_test(void) {
    int fd;
    mcs_ssize_t n;

    log_writeln("[M13] VFS smoke test start");

    mcs_ramfs_init(&g_fs);

    if (mcs_ramfs_seed_file(&g_fs, "/hello.txt",
            (const uint8_t *)"hello-mcsos", 11) != MCS_OK) {
        log_writeln("[M13] FAIL: seed_file");
        return;
    }

    g_proc.pid = 1;
    mcs_fd_table_init(&g_proc.fd_table);
    mcs_vfs_set_active_ramfs_for_test(&g_fs);

    fd = mcs_sys_open(&g_proc, &g_fs, "/hello.txt", MCS_O_RDONLY);
    if (fd < 0) { log_writeln("[M13] FAIL: open"); return; }

    n = mcs_sys_read(&g_proc, fd, g_buf, 5);
    if (n != 5) { log_writeln("[M13] FAIL: read"); return; }

    if (g_buf[0]!='h' || g_buf[1]!='e' ||
        g_buf[2]!='l' || g_buf[3]!='l' || g_buf[4]!='o') {
        log_writeln("[M13] FAIL: content");
        return;
    }

    if (mcs_sys_close(&g_proc, fd) != MCS_OK) {
        log_writeln("[M13] FAIL: close");
        return;
    }

    log_writeln("[M13] VFS smoke test: PASS");
}

void kmain(void) {
    log_init();
    log_writeln("[M9] MCSOS booting...");
    m12_sync_selftest();
    if (mcsos_scheduler_init(&g_sched, &boot_thread) != MCSOS_SCHED_OK) goto halt;
    log_writeln("[M9] Scheduler OK");
    mcsos_thread_prepare(&thread_a, "a", thread_a_entry, 0,
                         stack_a, sizeof(stack_a), g_sched.next_id++);
    mcsos_sched_enqueue(&g_sched, &thread_a);
    mcsos_thread_prepare(&thread_b, "b", thread_b_entry, 0,
                         stack_b, sizeof(stack_b), g_sched.next_id++);
    mcsos_sched_enqueue(&g_sched, &thread_b);
    mcsos_sched_yield(&g_sched);
    mcsos_sched_yield(&g_sched);
    mcsos_sched_yield(&g_sched);
    log_key_value_hex64("[M9] switches=", g_sched.context_switches);
    log_writeln("[M9] Scheduler demo COMPLETE");

    m13_vfs_smoke_test();

halt:
    while (1) __asm__ volatile("hlt");
}
