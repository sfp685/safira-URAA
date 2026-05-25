#ifndef MCSOS_IDT_H
#define MCSOS_IDT_H
#include "types.h"
struct trap_frame {
    uint64_t r15, r14, r13, r12, r11, r10, r9, r8;
    uint64_t rbp, rdi, rsi, rdx, rcx, rbx, rax;
    uint64_t vector, error_code;
    uint64_t rip, cs, rflags, rsp, ss;
} __attribute__((packed));
void idt_init(void);
#endif
