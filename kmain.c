#include <stdint.h>
#include <stddef.h>
#include "mcsos/kmem.h"

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

#define M8_BOOT_HEAP_SIZE (64u * 1024u)
static unsigned char m8_boot_heap[M8_BOOT_HEAP_SIZE] __attribute__((aligned(4096)));

void kmain(void) {
    early_serial_init();
    early_serial_puts("MCSOS 260502 M2 boot path entered\n");
    early_serial_puts("[M2] early serial online\n");

    x86_64_idt_init();
    early_serial_puts("[M4] Triggering manual int3 breakpoint test execution...\n");
    __asm__ __volatile__("int $3");
    early_serial_puts("[M4 SUCCESS] System successfully recovered from breakpoint and continued execution!\n");

    /* M8: inisialisasi kernel heap awal */
    int rc = kmem_init(m8_boot_heap, sizeof(m8_boot_heap));
    if (rc != 0) {
        early_serial_puts("[M8 FAIL] kmem_init failed\n");
        for (;;) { __asm__ ("hlt"); }
    }
    early_serial_puts("[M8] heap initialized\n");

    void *probe = kmem_alloc(128);
    if (probe == (void*)0) {
        early_serial_puts("[M8 FAIL] kmem_alloc probe failed\n");
        for (;;) { __asm__ ("hlt"); }
    }
    if (kmem_free_checked(probe) != 0) {
        early_serial_puts("[M8 FAIL] kmem_free_checked probe failed\n");
        for (;;) { __asm__ ("hlt"); }
    }
    early_serial_puts("[M8 SUCCESS] kernel heap alloc/free probe OK\n");

    early_serial_puts("[M2] kernel reached controlled halt loop\n");
    for (;;) { __asm__ ("hlt"); }
}
