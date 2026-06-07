	.section .note.gnu.build-id, "a"
	.align 4
	.long 4          /* namesz */
	.long 4          /* descsz */
	.long 0x1        /* type: NT_GNU_BUILD_ID */
	.ascii "GNU\0"
	.long 0x0

	.section .text
	.align 8

multiboot2_header_start:
	.byte 0xd6, 0x50, 0x52, 0xe8
	.long 0
	.long 24
	.long 0x17adaf12
	.short 0
	.short 0
	.long 8
multiboot2_header_end:

	.global _start
	.code32
_start:
	cli
	/* Port 0xe9 = QEMU debug port, langsung tanpa init */
	movl $0xe9, %edx
	movb $65, %al
	outb %al, %dx
	/* Inisialisasi COM1 */
	movl $0x3F8+1, %edx
	movb $0x00, %al
	outb %al, %dx
	movl $0x3F8+3, %edx
	movb $0x80, %al
	outb %al, %dx
	movl $0x3F8+0, %edx
	movb $0x01, %al
	outb %al, %dx
	movl $0x3F8+1, %edx
	movb $0x00, %al
	outb %al, %dx
	movl $0x3F8+3, %edx
	movb $0x03, %al
	outb %al, %dx
	movl $0x3F8+2, %edx
	movb $0xC7, %al
	outb %al, %dx
	movl $0x3F8+4, %edx
	movb $0x0B, %al
	outb %al, %dx
	/* Tulis 'A' ke serial */
	movl $0x3F8, %edx
	movb $65, %al
	outb %al, %dx

	/* Setup stack */
	movl $stack_top, %esp

	/* Zero page tables */
	cld
	xorl %eax, %eax
	movl $pml4, %edi
	movl $(3 * 4096 / 4), %ecx
	rep stosl

	/* PML4[0] -> PDPT */
	movl $pdpt, %eax
	orl  $3, %eax
	movl %eax, pml4

	/* PDPT[0] -> PD */
	movl $pd, %eax
	orl  $3, %eax
	movl %eax, pdpt

	/* PD: 512 x 2MB identity pages */
	movl $pd, %edi
	movl $0x83, %eax
	movl $512, %ecx
fill_pd:
	movl %eax, (%edi)
	movl $0, 4(%edi)
	addl $0x200000, %eax
	addl $8, %edi
	loop fill_pd

	/* Tulis 'B' setelah page tables */
	movl $0x3F8, %edx
	movb $'B', %al
	outb %al, %dx

	/* CR3 = PML4 */
	movl $pml4, %eax
	movl %eax, %cr3

	/* CR4.PAE */
	movl %cr4, %eax
	orl  $0x20, %eax
	movl %eax, %cr4

	/* EFER.LME */
	movl $0xC0000080, %ecx
	rdmsr
	orl  $0x100, %eax
	wrmsr

	/* CR0: PG+PE */
	movl %cr0, %eax
	orl  $0x80000001, %eax
	movl %eax, %cr0

	/* Tulis 'C' setelah paging enabled */
	movl $0x3F8, %edx
	movb $'C', %al
	outb %al, %dx

	lgdt gdt64_ptr
	ljmp $8, $start64

	.code64
start64:
	/* Tulis 'D' di 64-bit mode */
	movl $0x3F8, %edx
	movb $'D', %al
	outb %al, %dx

	movw $0x10, %ax
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %ss
	xorw %ax, %ax
	movw %ax, %fs
	movw %ax, %gs
	movl $stack_top, %esp
	xorq %rbp, %rbp
	call kmain
hang:
	hlt
	jmp hang

	.align 16
gdt64:
	.quad 0x0000000000000000
	.quad 0x00af9a000000ffff
	.quad 0x00cf92000000ffff
gdt64_end:
gdt64_ptr:
	.word gdt64_end - gdt64 - 1
	.long gdt64

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
