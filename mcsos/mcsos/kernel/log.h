#ifndef MCSOS_KERNEL_LOG_H
#define MCSOS_KERNEL_LOG_H

#include <stdint.h>

// Fungsi dasar input-output port x86
static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile("outb %0, %1" : : "a"(val), "Nd"(port));
}

static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    __asm__ volatile("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

// Inisialisasi Port Serial 0x3F8 (COM1) agar siap mengirim teks
static inline void log_init(void) {
    outb(0x3F8 + 1, 0x00);    // Disable all interrupts
    outb(0x3F8 + 3, 0x80);    // Enable DLAB (set baud rate divisor)
    outb(0x3F8 + 0, 0x03);    // Set divisor to 3 (lo byte) 38400 baud
    outb(0x3F8 + 1, 0x00);    //                  (hi byte)
    outb(0x3F8 + 3, 0x03);    // 8 bits, no parity, one stop bit
    outb(0x3F8 + 2, 0xC7);    // Enable FIFO, clear them, with 14-byte threshold
    outb(0x3F8 + 4, 0x0B);    // IRQs enabled, RTS/DSR set
}

static inline int is_transmit_empty(void) {
    return inb(0x3F8 + 5) & 0x20;
}

static inline void log_writeln(const char* m) {
    while (*m) {
        while (is_transmit_empty() == 0);
        outb(0x3F8, *m++);
    }
    while (is_transmit_empty() == 0);
    outb(0x3F8, '\r');
    while (is_transmit_empty() == 0);
    outb(0x3F8, '\n');
}

static inline void log_key_value_hex64(const char* k, uint64_t v) {
    log_writeln(k);
    // Cetak nilai hex sederhana ke serial
    char hex_str[19];
    hex_str[0] = '0'; hex_str[1] = 'x';
    for (int i = 15; i >= 0; i--) {
        int nibble = (v >> (i * 4)) & 0xF;
        hex_str[17 - i] = (nibble < 10) ? ('0' + nibble) : ('A' + nibble - 10);
    }
    hex_str[18] = '\0';
    log_writeln(hex_str);
}

#endif
