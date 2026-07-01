// src/kernel/arch/x86_64/idt.h
#ifndef ARCH_X86_64_IDT_H
#define ARCH_X86_64_IDT_H

#include <stdint.h>

// Struktur data Entry IDT (16 Byte untuk mode 64-bit)
struct x86_64_idt_entry {
    uint16_t offset_low;       // Bit 0..15 dari alamat handler
    uint16_t selector;         // Segment Selector untuk Kode Kernel (0x28u)
    uint8_t  ist;              // Interrupt Stack Table (diisi 0u jika tidak digunakan)
    uint8_t  type_attributes;  // Atribut tipe gate (0x8Eu atau 0x8Fu)
    uint16_t offset_mid;       // Bit 16..31 dari alamat handler
    uint32_t offset_high;      // Bit 32..63 dari alamat handler
    uint32_t reserved;         // Harus diisi 0u
} __attribute__((packed));

typedef struct x86_64_idt_entry x86_64_idt_entry_t;

// Struktur data Pointer IDTR untuk instruksi lidt
struct x86_64_idtr {
    uint16_t limit;            // Ukuran tabel IDT dalam byte - 1 (4095 untuk 256 entries)
    uint64_t base;             // Alamat memori linier tempat tabel IDT berada
} __attribute__((packed));

typedef struct x86_64_idtr x86_64_idtr_t;

// Struktur data Trap Frame untuk normalisasi kondisi stack setelah Exception
struct x86_64_trap_frame {
    // Register umum yang disimpan manual via stub assembly
    uint64_t r15; uint64_t r14; uint64_t r13; uint64_t r12;
    uint64_t r11; uint64_t r10; uint64_t r9;  uint64_t r8;
    uint64_t rsi; uint64_t rdi; uint64_t rbp; uint64_t rdx;
    uint64_t rcx; uint64_t rbx; uint64_t rax;

    // Informasi exception tambahan
    uint64_t vector;           // Nomor vektor eksepsi (0..31)
    uint64_t error_code;       // Kode error buatan atau asli dari CPU

    // State otomatis yang didorong oleh hardware CPU x86_64
    uint64_t rip;
    uint64_t cs;
    uint64_t rflags;
    uint64_t rsp;
    uint64_t ss;
} __attribute__((packed));

typedef struct x86_64_trap_frame x86_64_trap_frame_t;

// Deklarasi fungsi-fungsi penanganan interupsi
void x86_64_idt_init(void);
void x86_64_trap_dispatch(x86_64_trap_frame_t *frame);

// Array eksternal yang berisi pointer ke stub assembly untuk vektor 0..31
extern uint64_t x86_64_exception_stubs[32];

#endif // ARCH_X86_64_IDT_H
