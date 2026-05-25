#include <core/panic.h>
#include <core/log.h>
#include <arch/x86_64/cpu.h>

void kernel_panic_at(const char* file, int line, const char* msg) {
    cli();

    log_write("\r\n[!!!] KERNEL PANIC [!!!]\r\n");
    log_write("FILE: ");
    log_write(file);
    log_write("\r\nMSG : ");
    log_write(msg);
    log_write("\r\nSYSTEM HALTED.\r\n");

    infinite_hlt();
}
