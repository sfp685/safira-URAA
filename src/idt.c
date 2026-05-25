#include "idt.h"
#include "io.h"
#include "panic.h"
#include "serial.h"
#include "pic.h"
#include "pit.h"

struct idt_entry {
    uint16_t isr_low;
    uint16_t kernel_cs;
    uint8_t  ist;
    uint8_t  attributes;
    uint16_t isr_mid;
    uint32_t isr_high;
    uint32_t reserved;
} __attribute__((packed));

struct idt_ptr {
    uint16_t limit;
    uint64_t base;
} __attribute__((packed));

static struct idt_entry g_idt[256];
static struct idt_ptr g_idtr;

extern void isr_stub_3(void);
extern void isr_stub_32(void);

static void idt_set_gate(uint8_t vector, void *isr, uint8_t attributes) {
    uint64_t addr = (uint64_t)isr;
    g_idt[vector].isr_low = (uint16_t)(addr & 0xFFFFu);
    g_idt[vector].kernel_cs = x86_64_read_cs();
    g_idt[vector].ist = 0;
    g_idt[vector].attributes = attributes;
    g_idt[vector].isr_mid = (uint16_t)((addr >> 16) & 0xFFFFu);
    g_idt[vector].isr_high = (uint32_t)((addr >> 32) & 0xFFFFFFFFu);
    g_idt[vector].reserved = 0;
}

void idt_init(void) {
    for (int i = 0; i < 256; i++) {
        g_idt[i].attributes = 0;
    }

    idt_set_gate(3, isr_stub_3, 0x8Eu);   // Breakpoint exception
    idt_set_gate(32, isr_stub_32, 0x8Eu); // IRQ0 Timer pada Vektor 32

    g_idtr.limit = sizeof(g_idt) - 1;
    g_idtr.base = (uint64_t)&g_idt;

    __asm__ volatile ("lidt %0" :: "m"(g_idtr));
}

void x86_64_trap_dispatch(struct trap_frame *frame) {
    if (frame->vector == 32) {
        timer_on_irq0();
        pic_send_eoi(0); // Sinyal End-Of-Interrupt wajib dikirim ke PIC
    } else if (frame->vector == 3) {
        serial_write_string("[MCSOS:DEBUG] Breakpoint hit!\n");
    } else {
        kernel_panic("Fatal Exception Terjadi", frame->vector);
    }
}
