.code64
.section .text

.extern x86_64_trap_dispatch

# Makro untuk exception tanpa Error Code bawaan CPU
.macro ISR_NOERR vector
.global isr_stub_\vector
isr_stub_\vector:
    pushq $0               # Dorong dummy error code bernilai 0
    pushq \vector          # Dorong nomor vektor eksepsi
    jmp isr_common
.endm

# Makro untuk exception yang otomatis memiliki Error Code dari CPU
.macro ISR_ERR vector
.global isr_stub_\vector
isr_stub_\vector:
    pushq \vector          # CPU sudah mendorong error code, langsung dorong nomor vektor
    jmp isr_common
.endm

# Definisi Stub Vektor 0 sampai 31 sesuai spesifikasi arsitektur Intel
ISR_NOERR $0   # Divide Error
ISR_NOERR $1   # Debug
ISR_NOERR $2   # Non-Maskable Interrupt
ISR_NOERR $3   # Breakpoint (int3)
ISR_NOERR $4   # Overflow
ISR_NOERR $5   # BOUND Range Exceeded
ISR_NOERR $6   # Invalid Opcode
ISR_NOERR $7   # Device Not Available
ISR_ERR   $8   # Double Fault
ISR_NOERR $9   # Coprocessor Segment Overrun
ISR_ERR   $10  # Invalid TSS
ISR_ERR   $11  # Segment Not Present
ISR_ERR   $12  # Stack-Segment Fault
ISR_ERR   $13  # General Protection Fault (#GP)
ISR_ERR   $14  # Page Fault (#PF)
ISR_NOERR $15  # Reserved
ISR_NOERR $16  # x87 FPU Floating-Point Error
ISR_ERR   $17  # Alignment Check
ISR_NOERR $18  # Machine Check
ISR_NOERR $19  # SIMD Floating-Point Exception
ISR_NOERR $20  # Virtualization Exception
ISR_ERR   $21  # Control Protection Exception
ISR_NOERR $22  # Reserved
ISR_NOERR $23  # Reserved
ISR_NOERR $24  # Reserved
ISR_NOERR $25  # Reserved
ISR_NOERR $26  # Reserved
ISR_NOERR $27  # Reserved
ISR_NOERR $28  # Hypervisor Injection Exception
ISR_ERR   $29  # VMM Communication Exception
ISR_ERR   $30  # Security Exception
ISR_NOERR $31  # Reserved

# Blok Penyelamatan Register (Jalur Utama Konvergensi Stub)
isr_common:
    # Dorong seluruh register umum ke stack sesuai urutan x86_64_trap_frame_t
    pushq %rax
    pushq %rbx
    pushq %rcx
    pushq %rdx
    pushq %rbp
    pushq %rdi
    pushq %rsi
    pushq %r8
    pushq %r9
    pushq %r10
    pushq %r11
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    # Siapkan argumen pertama untuk fungsi C x86_64_trap_dispatch
    # Berdasarkan System V ABI, argumen pertama dikirim melalui register %rdi
    movq %rsp, %rdi
    
    # Panggil fungsi dispatcher pusat di bahasa C
    call x86_64_trap_dispatch

    # Alur pemulihan setelah penanganan eksepsi selesai (misal dari vektor 3)
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %r11
    popq %r10
    popq %r9
    popq %r8
    popq %rsi
    popq %rdi
    popq %rbp
    popq %rdx
    popq %rcx
    popq %rbx
    popq %rax

    # Bersihkan field vector dan error_code dari stack (2 * 8 byte = 16 byte)
    addq $16, %rsp
    
    # Kembali ke program utama yang terinterupsi
    iretq

# Membuat tabel pointer statis yang dikirim ke idt.c
.section .rodata
.global x86_64_exception_stubs
.align 8
x86_64_exception_stubs:
    .quad isr_stub_0;  .quad isr_stub_1;  .quad isr_stub_2;  .quad isr_stub_3
    .quad isr_stub_4;  .quad isr_stub_5;  .quad isr_stub_6;  .quad isr_stub_7
    .quad isr_stub_8;  .quad isr_stub_9;  .quad isr_stub_10; .quad isr_stub_11
    .quad isr_stub_12; .quad isr_stub_13; .quad isr_stub_14; .quad isr_stub_15
    .quad isr_stub_16; .quad isr_stub_17; .quad isr_stub_18; .quad isr_stub_19
    .quad isr_stub_20; .quad isr_stub_21; .quad isr_stub_22; .quad isr_stub_23
    .quad isr_stub_24; .quad isr_stub_25; .quad isr_stub_26; .quad isr_stub_27
    .quad isr_stub_28; .quad isr_stub_29; .quad isr_stub_30; .quad isr_stub_31
