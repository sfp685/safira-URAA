	.section .text
	.align 8

multiboot2_header_start:
	.long 0xe85250d6
	.long 0
	.long 24
	.long 0x17adaf2a
	.short 0
	.short 0
	.long 8
multiboot2_header_end:

	/* GRUB2 dengan multiboot2 sudah masuk 64-bit long mode */
	.code64
	.global _start
_start:
	cli
	movabsq $stack_top, %rsp
	xorq %rbp, %rbp
	call kmain
hang:
	hlt
	jmp hang

	.section .bss
	.align 16
stack_bottom:
	.skip 16384
stack_top:
