.intel_syntax noprefix

# === MULTIBOOT HEADER (Syarat Wajib QEMU Modern) ===
.section .text
.align 4
multiboot_header:
    .long 0x1BADB002              # Magic number
    .long 0x00000001              # Flags (align modules)
    .long -(0x1BADB002 + 0x00000001) # Checksum

.global isr_stub_3
.global isr_stub_32
.extern x86_64_trap_dispatch

.align 8
isr_stub_3:
    push 0
    push 3
    jmp isr_common_stub

.align 8
isr_stub_32:
    push 0
    push 32
    jmp isr_common_stub

isr_common_stub:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    mov rdi, rsp
    cld
    call x86_64_trap_dispatch

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    add rsp, 16
    iretq
