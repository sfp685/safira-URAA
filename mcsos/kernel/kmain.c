#include <mcsos/arch/idt.h>
#include <mcsos/kernel/log.h>

void kmain(void) {
    // Panggil inisialisasi IDT M4
    x86_64_idt_init();

    // Picu uji coba breakpoint (int3)
    log_writeln("[M4] Triggering intentional int3 test execution...");
    x86_64_trigger_breakpoint_for_test();
    log_writeln("[M4] Successfully returned from int3 test handler!");

    // Loop selamanya agar CPU tetap menyala
    while(1) {
        __asm__ volatile("hlt");
    }
}
