// src/kernel/arch/x86_64/trap.c
#include "idt.h"
#include "../../klog.h"  // Path klog.h sesuai panduan proyek
#include "../../kpanic.h" // Path fungsi kernel panic sesuai panduan proyek

// Array string deskripsi nama exception untuk memudahkan debugging log
static const char *exception_messages[32] = {
    "#DE: Divide Error", "#DB: Debug", "Non-Maskable Interrupt", "#BP: Breakpoint",
    "#OF: Overflow", "#BR: BOUND Range Exceeded", "#UD: Invalid Opcode", "#NM: Device Not Available",
    "#DF: Double Fault", "Coprocessor Segment Overrun", "#TS: Invalid TSS", "#NP: Segment Not Present",
    "#SS: Stack-Segment Fault", "#GP: General Protection Fault", "#PF: Page Fault", "Reserved",
    "#MF: x87 FPU Floating-Point Error", "#AC: Alignment Check", "#MC: Machine Check", "#XM: SIMD Exception",
    "#VE: Virtualization Exception", "#CP: Control Protection Exception", "Reserved", "Reserved",
    "Reserved", "Reserved", "Reserved", "Reserved",
    "#HV: Hypervisor Injection", "#VC: VMM Communication", "#SX: Security Exception", "Reserved"
};

// Fungsi pusat penerima alur exception dari isr.S
void x86_64_trap_dispatch(x86_64_trap_frame_t *frame) {
    uint64_t vec = frame->vector;

    // Proteksi batas indeks array pesan
    const char *msg = (vec < 32) ? exception_messages[vec] : "Unknown Exception";

    // Kasus Khusus Jalur Uji: Breakpoint (Vektor 3) bersifat Recoverable
    if (vec == 3u) {
        klog_info("[M4 TEST PASS] Exception triggered: %s at RIP: 0x%x\n", msg, frame->rip);
        klog_info("  State details -> RAX: 0x%x, RSP: 0x%x, RFLAGS: 0x%x\n", frame->rax, frame->rsp, frame->rflags);
        // Kembali ke assembly isr.S tanpa memicu panic, program akan berlanjut melewati instruksi int3
        return;
    }

    // Kebijakan Fail-Closed: Di luar vektor 3, pemicuan exception dianggap fatal
    klog_error("\n!!! FATAL EXCEPTION DETECTED: %s (Vector: %d) !!!\n", msg, vec);
    klog_error("  Faulting Instruction Pointer (RIP) : 0x%x\n", frame->rip);
    klog_error("  Hardware Error Code                : 0x%x\n", frame->error_code);
    klog_error("  Stack Pointer (RSP) at Fault       : 0x%x\n", frame->rsp);
    klog_error("  Code Segment (CS) / RFLAGS         : 0x%x / 0x%x\n", frame->cs, frame->rflags);
    klog_error("  General Registers -> RAX: 0x%x, RBX: 0x%x, RCX: 0x%x, RDX: 0x%x\n", 
                frame->rax, frame->rbx, frame->rcx, frame->rdx);

    // Lempar ke mekanisme Kernel Panic bawaan modul M3
    kernel_panic("Fail-Closed Unhandled Kernel Exception.");
}
