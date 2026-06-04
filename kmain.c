#include <stdint.h>
#include <stddef.h>

// Deklarasi fungsi inisialisasi IDT dari modul M4 (Halaman 5)
void x86_64_idt_init(void);

static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile ("outb %b0, %w1" : : "a"(val), "Nd"(port));
}

void early_serial_init() {
    outb(0x3f8 + 1, 0x00);
    outb(0x3f8 + 3, 0x80);
    outb(0x3f8 + 0, 0x03);
    outb(0x3f8 + 1, 0x00);
    outb(0x3f8 + 3, 0x03);
}

void early_serial_puts(const char* s) {
    for (size_t i = 0; s[i] != '\0'; i++) {
        outb(0x3f8, s[i]);
    }
}

void kmain(void) {
    early_serial_init();
    early_serial_puts("MCSOS 260502 M2 boot path entered\n");
    early_serial_puts("[M2] early serial online\n");

    // 1. Panggil fungsi inisialisasi IDT M4
    x86_64_idt_init();

    early_serial_puts("[M4] Triggering manual int3 breakpoint test execution...\n");

    // 2. Jalankan Uji Coba Pemicuan manual int3 (Halaman 13)
    __asm__ __volatile__("int $3");

    early_serial_puts("[M4 SUCCESS] System successfully recovered from breakpoint and continued execution!\n");
    early_serial_puts("[M2] kernel reached controlled halt loop\n");

    for (;;) { __asm__ ("hlt"); }
}
