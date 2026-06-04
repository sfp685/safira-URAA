.section .multiboot
.align 4
.long 0x1BADB002
.long 0x00
.long -(0x1BADB002 + 0)

.section .text
.global _start
_start:
    # Mengatur Stack Pointer agar fungsi C bisa berjalan
    mov $stack_top, %rsp

    # Memanggil fungsi kmain dari kmain.c
    call kmain

    # Jika kmain selesai (tidak boleh terjadi), loop selamanya
.loop:
    hlt
    jmp .loop

.section .bss
.align 16
stack_bottom:
    .skip 16384 # 16KB stack
stack_top:
