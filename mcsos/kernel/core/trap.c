#include <stdint.h>
#include <mcsos/arch/idt.h>
#include <mcsos/kernel/log.h>
#include <mcsos/kernel/panic.h>

static uint64_t trap_count;

uint64_t m4_trap_count_for_test(void) {
    return trap_count;
}

void x86_64_trap_dispatch(x86_64_trap_frame_t *frame) {
    trap_count++;

    log_writeln("--- [TRAP FRAME REGISTER DUMP] ---");
    log_key_value_hex64("Trap Vector", frame->vector);
    log_key_value_hex64("Error Code ", frame->error_code);
    log_key_value_hex64("RIP        ", frame->rip);

    if (frame->vector == 3u) {
        log_writeln("[M4] Breakpoint exception handled correctly. Recovering path...");
        return;
    }

    kernel_panic_at("trap.c", 45, "CPU Exception Non-Recoverable Terjadi - Fail-Closed Triggered");
}

// Fungsi pemicu interupsi breakpoint untuk kebutuhan pengujian M4
void x86_64_trigger_breakpoint_for_test(void) {
    __asm__ volatile("int $3");
}
