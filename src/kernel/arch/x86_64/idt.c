// src/kernel/arch/x86_64/idt.c
#include "idt.h"
#include "../../klog.h" // Sesuaikan path klog.h pada proyek Anda

// Alokasi tabel IDT statis sebanyak 256 entri di segmen memory bss/data
static x86_64_idt_entry_t idt_table[256];
static x86_64_idtr_t      idtr_pointer;

// Fungsi pembantu untuk melakukan set satu entri gate pada IDT
static void x86_64_idt_set_gate(uint8_t vector, uint64_t handler_address, uint8_t attributes) {
    idt_table[vector].offset_low      = (uint16_t)(handler_address & 0xFFFFu);
    idt_table[vector].selector        = 0x28u; // Segment Selector Kode Kernel GDT M2
    idt_table[vector].ist             = 0u;    // Tidak menggunakan fitur IST di M4
    idt_table[vector].type_attributes = attributes;
    idt_table[vector].offset_mid      = (uint16_t)((handler_address >> 16u) & 0xFFFFu);
    idt_table[vector].offset_high     = (uint32_t)((handler_address >> 32u) & 0xFFFFFFFFu);
    idt_table[vector].reserved        = 0u;
}

// Fungsi utama inisialisasi IDT yang akan dipanggil oleh kmain
void x86_64_idt_init(void) {
    // 1. Bersihkan seluruh entri IDT menjadi nol terlebih dahulu
    for (int i = 0; i < 256; i++) {
        idt_table[i] = (x86_64_idt_entry_t){0};
    }

    // 2. Daftarkan 32 stub vektor exception awal menggunakan perulangan
    // Atribut 0x8Eu mewakili: Present=1, DPL=00 (Kernel), Type=1110 (Interrupt Gate)
    for (uint8_t i = 0; i < 32; i++) {
        x86_64_idt_set_gate(i, x86_64_exception_stubs[i], 0x8Eu);
    }

    // 3. Konfigurasi IDTR Pointer
    idtr_pointer.limit = (uint16_t)(sizeof(idt_table) - 1u);
    idtr_pointer.base  = (uint64_t)&idt_table[0];

    // 4. Jalankan instruksi inline assembly lidt untuk memuat IDT ke register CPU
    __asm__ __volatile__("lidt %0" :: "m"(idtr_pointer) : "memory");

    // Cetak log sukses ke serial console
    klog_info("[M4] IDT loaded successfully with 32 exception stubs.\n");
}

void idt_init(void) { x86_64_idt_init(); }
