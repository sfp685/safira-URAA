.section .multiboot, "a"
.align 4
.long 0x1BADB002
.long 0x00000000
.long -(0x1BADB002 + 0x00000000)

.section .bss
.align 4096
pml4:
    .skip 4096
pdpt:
    .skip 4096
pd:
    .skip 4096
.align 16
stack_bottom:
    .skip 16384
stack_top:

.section .data
.align 16
gdt64:
    .quad 0x0000000000000000
    .quad 0x00AF9A000000FFFF
    .quad 0x00AF92000000FFFF
gdt64_ptr:
    .word gdt64_ptr - gdt64 - 1
    .quad gdt64

.section .text
.code32
.global _start
.extern kmain
_start:
    cli
    mov $stack_top, %esp

    movl $pdpt, %eax
    orl $0x3, %eax
    movl %eax, pml4

    movl $pd, %eax
    orl $0x3, %eax
    movl %eax, pdpt

    movl $0, %ecx
    movl $pd, %edi
fill_pd:
    movl %ecx, %eax
    shll $21, %eax
    orl $0x83, %eax
    movl %eax, (%edi)
    addl $8, %edi
    incl %ecx
    cmpl $512, %ecx
    jl fill_pd

    movl $pml4, %eax
    movl %eax, %cr3

    movl %cr4, %eax
    orl $0x20, %eax
    movl %eax, %cr4

    movl $0xC0000080, %ecx
    rdmsr
    orl $0x100, %eax
    wrmsr

    movl %cr0, %eax
    orl $0x80000000, %eax
    movl %eax, %cr0

    lgdt gdt64_ptr
    ljmp $0x08, $long_mode_entry

.code64
long_mode_entry:
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss

    mov $stack_top, %rsp
    call kmain
.loop:
    hlt
    jmp .loop
