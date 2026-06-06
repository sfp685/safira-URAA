#include <mcsos/arch/idt.h>
#include <mcsos/kernel/log.h>
#include "mcsos_thread.h"

static uint8_t stack_a[4096];
static uint8_t stack_b[4096];

static mcsos_thread_t boot_thread;
static mcsos_thread_t thread_a;
static mcsos_thread_t thread_b;

static mcsos_scheduler_t g_sched;

static void thread_a_entry(void *arg) {
    (void)arg;
    log_writeln("[M9] thread_a: running");
}

static void thread_b_entry(void *arg) {
    (void)arg;
    log_writeln("[M9] thread_b: running");
}

void kmain(void) {
    log_init();
    log_writeln("[M9] MCSOS kernel booting...");

    x86_64_idt_init();
    log_writeln("[M4] IDT initialized");

    log_writeln("[M9] Initializing scheduler...");
    if (mcsos_scheduler_init(&g_sched, &boot_thread) != MCSOS_SCHED_OK) {
        log_writeln("[M9] ERROR: scheduler init failed");
        goto halt;
    }
    log_writeln("[M9] Scheduler init OK");

    if (mcsos_thread_prepare(&thread_a, "thread_a",
                             thread_a_entry, (void *)0,
                             stack_a, sizeof(stack_a),
                             g_sched.next_id++) != MCSOS_SCHED_OK) {
        log_writeln("[M9] ERROR: thread_a prepare failed");
        goto halt;
    }
    mcsos_sched_enqueue(&g_sched, &thread_a);
    log_writeln("[M9] thread_a enqueued");

    if (mcsos_thread_prepare(&thread_b, "thread_b",
                             thread_b_entry, (void *)0,
                             stack_b, sizeof(stack_b),
                             g_sched.next_id++) != MCSOS_SCHED_OK) {
        log_writeln("[M9] ERROR: thread_b prepare failed");
        goto halt;
    }
    mcsos_sched_enqueue(&g_sched, &thread_b);
    log_writeln("[M9] thread_b enqueued");

    if (mcsos_sched_validate(&g_sched) != MCSOS_SCHED_OK) {
        log_writeln("[M9] ERROR: runqueue corrupt before yield");
        goto halt;
    }

    log_writeln("[M9] yield 1: boot -> thread_a");
    mcsos_sched_yield(&g_sched);

    log_writeln("[M9] yield 2: thread_a -> thread_b");
    mcsos_sched_yield(&g_sched);

    log_writeln("[M9] yield 3: thread_b -> thread_a");
    mcsos_sched_yield(&g_sched);

    log_key_value_hex64("[M9] context_switches=", g_sched.context_switches);
    log_writeln("[M9] Scheduler demo COMPLETE");

halt:
    while (1) {
        __asm__ volatile("hlt");
    }
}
