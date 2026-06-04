#ifndef MCSOS_KERNEL_PANIC_H
#define MCSOS_KERNEL_PANIC_H

// Fungsi tiruan (stub) agar trap.c sukses kompilasi tanpa nyangkut
static inline void kernel_panic_at(const char* file, int line, const char* msg) {
    (void)file; (void)line; (void)msg;
    while(1) {
        __asm__ volatile("hlt");
    }
}

#endif
