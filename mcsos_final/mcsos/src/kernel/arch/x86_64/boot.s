/* Multiboot2 header */
.section .multiboot
.align 8
mb2_header:
    .long 0xe85250d6
    .long 0
    .long mb2_header_end - mb2_header
    .long -(0xe85250d6 + 0 + (mb2_header_end - mb2_header))
    .short 0
    .short 0
    .long 8
mb2_header_end:

/* 32-bit entry point */
.section .text
.code32
.global _start
_start:
    cli

    /* Setup temporary stack */
    mov $(_bss_end + 0x4000), %esp

    /* Load GDT */
    lgdt (gdt_ptr)

    /* Enable PAE */
    mov %cr4, %eax
    or $0x20, %eax
    mov %eax, %cr4

    /* Load PML4 */
    mov $pml4, %eax
    mov %eax, %cr3

    /* Enable long mode via EFER */
    mov $0xC0000080, %ecx
    rdmsr
    or $0x100, %eax
    wrmsr

    /* Enable paging + protected mode */
    mov %cr0, %eax
    or $0x80000001, %eax
    mov %eax, %cr0

    /* Far jump to 64-bit */
    ljmp $0x08, $_start64

/* 64-bit code */
.code64
_start64:
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    xor %ax, %ax
    mov %ax, %fs
    mov %ax, %gs

    call kmain
1:  hlt
    jmp 1b

/* GDT */
.align 16
gdt:
    .quad 0x0000000000000000   /* null */
    .quad 0x00af9a000000ffff   /* code64 */
    .quad 0x00af92000000ffff   /* data */
gdt_ptr:
    .short gdt_ptr - gdt - 1
    .long gdt

/* Page tables (identity map first 1GB) */
.align 0x1000
pml4:
    .quad pdpt + 0x3
    .fill 511, 8, 0
pdpt:
    .quad pd + 0x3
    .fill 511, 8, 0
pd:
    .set i, 0
    .rept 512
    .quad (i << 21) | 0x83
    .set i, i+1
    .endr
