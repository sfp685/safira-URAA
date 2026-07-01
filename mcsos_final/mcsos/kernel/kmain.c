#include <stdint.h>
#include <mcsos/kernel/log.h>
#include "mcsos_thread.h"

void m12_sync_selftest(void);

static uint8_t stack_a[4096];
static uint8_t stack_b[4096];
static mcsos_thread_t boot_thread;
static mcsos_thread_t thread_a;
static mcsos_thread_t thread_b;
static mcsos_scheduler_t g_sched;

static void thread_a_entry(void *arg) { (void)arg; }
static void thread_b_entry(void *arg) { (void)arg; }

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
halt:
    while (1) __asm__ volatile("hlt");
}
