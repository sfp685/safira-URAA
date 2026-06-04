#include <serial.h>
#include <types.h>

#define COM1 0x3f8

static inline void outb(uint16_t port, uint8_t val) {
    asm volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}
static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    asm volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}
static int serial_ready(void) {
    return inb(COM1 + 5) & 0x20;
}

void serial_init(void) {
    outb(COM1 + 1, 0x00);
    outb(COM1 + 3, 0x80);
    outb(COM1 + 0, 0x03);
    outb(COM1 + 1, 0x00);
    outb(COM1 + 3, 0x03);
    outb(COM1 + 2, 0xC7);
    outb(COM1 + 4, 0x0B);
}

void serial_write_char(char c) {
    while (!serial_ready());
    outb(COM1, (uint8_t)c);
}

void serial_send_string(const char *s) {
    for (int i = 0; s[i]; i++) serial_write_char(s[i]);
}

void serial_write_string(const char *s) { serial_send_string(s); }

void serial_write_hex64(uint64_t v) {
    const char *hex = "0123456789abcdef";
    char buf[19];
    buf[0]='0'; buf[1]='x';
    for (int i = 0; i < 16; i++)
        buf[2+i] = hex[(v >> (60 - i*4)) & 0xf];
    buf[18] = '\0';
    serial_send_string(buf);
}

void serial_write_dec64(uint64_t v) {
    char buf[21];
    int i = 20;
    buf[i] = '\0';
    if (v == 0) { buf[--i] = '0'; }
    else { while (v > 0) { buf[--i] = '0' + (v % 10); v /= 10; } }
    serial_send_string(&buf[i]);
}
