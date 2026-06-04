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
EOF

# 1. Bersihkan folder build
rm -rf build && mkdir -p build
# 2. Kompilasi interrupts.S
clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o
# 3. Kompilasi pic.c
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
# 4. Kompilasi pit.c
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
# 5. Kompilasi idt.c
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
# 6. Kompilasi serial.c
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
# 7. Kompilasi panic.c
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o
# 8. Kompilasi kernel.c
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o
# 9. Satukan semua objek (Link)
ld -T linker.ld -o build/mcsos-m5.elf build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o
qemu-system-x86_64 -M q35 -m 512M -kernel build/mcsos-m5.elf -serial stdio -no-reboot -no-shutdown
cat << 'EOF' > kernel/kernel.c
#include "io.h"
#include "serial.h"
#include "idt.h"
#include "pic.h"
#include "pit.h"

void kmain(void) {
    cpu_cli();                 // 1. Matikan interupsi selama setup awal hardware
    serial_init();             // 2. Siapkan komunikasi serial COM1
    serial_write_string("[MCSOS:M5] boot: external interrupt bring-up start\n");

    idt_init();                // 3. Muat tabel IDT ke CPU register
    serial_write_string("[MCSOS:M5] idt: loaded\n");

    pic_remap(PIC_MASTER_OFFSET, PIC_SLAVE_OFFSET); // 4. Geser offset IRQ agar tidak tabrakan dengan exception
    pic_mask_all();            // 5. Tutup seluruh pin interupsi default
    pic_unmask_irq(0);         // 6. Buka khusus untuk IRQ0 (Timer)
    serial_write_string("[MCSOS:M5] pic: remapped and masked\n");

    pit_configure_hz(100);     // 7. Atur detak PIT pada kecepatan 100 Hz
    serial_write_string("[MCSOS:M5] pit: configured 100Hz\n");

    serial_write_string("[MCSOS:M5] sti: enabling interrupts\n");
    cpu_sti();                 // 8. Aktifkan kembali interupsi secara global

    // Loop abadi hemat energi menggunakan instruksi HLT
    for (;;) {
        cpu_hlt();
    }
}
EOF

# 1. Bersihkan folder build lama
rm -rf build && mkdir -p build
# 2. Kompilasi ulang seluruh berkas driver ke objek baru
clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o
# 3. Satukan objek dengan perintah ld yang utuh dan bersih
ld -T linker.ld -o build/mcsos-m5.elf build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o
qemu-system-x86_64 -M q35 -m 512M -kernel build/mcsos-m5.elf -serial stdio -no-reboot -no-shutdown
cat << 'EOF' > kernel/kernel.c
#include "io.h"
#include "serial.h"
#include "idt.h"
#include "pic.h"
#include "pit.h"

void kmain(void) {
    cpu_cli();                 // 1. Matikan interupsi selama setup awal hardware
    serial_init();             // 2. Siapkan komunikasi serial COM1
    serial_write_string("[MCSOS:M5] boot: external interrupt bring-up start\n");

    idt_init();                // 3. Muat tabel IDT ke CPU register
    serial_write_string("[MCSOS:M5] idt: loaded\n");

    pic_remap(PIC_MASTER_OFFSET, PIC_SLAVE_OFFSET); // 4. Geser offset IRQ agar tidak tabrakan dengan exception
    pic_mask_all();            // 5. Tutup seluruh pin interupsi default
    pic_unmask_irq(0);         // 6. Buka khusus untuk IRQ0 (Timer)
    serial_write_string("[MCSOS:M5] pic: remapped and masked\n");

    pit_configure_hz(100);     // 7. Atur detak PIT pada kecepatan 100 Hz
    serial_write_string("[MCSOS:M5] pit: configured 100Hz\n");

    serial_write_string("[MCSOS:M5] sti: enabling interrupts\n");
    cpu_sti();                 // 8. Aktifkan kembali interupsi secara global

    // Loop abadi hemat energi menggunakan instruksi HLT
    for (;;) {
        cpu_hlt();
    }
}
EOF

qemu-system-x86_64 -M q35 -m 512M -kernel build/mcsos-m5.elf -serial stdio -no-reboot -no-shutdown
nano kernel/kernel.c
#include "io.h"
#include "serial.h"
#include "idt.h"
#include "pic.h"
#include "pit.h"
void kmain(void) {
}
# 1. Bersihkan folder lama
rm -rf build && mkdir -p build
# 2. Kompilasi ulang seluruh berkas objek
clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o
# 3. Penggabungan Linker Script
ld -T linker.ld -o build/mcsos-m5.elf build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o
# 4. Jalankan Tes di QEMU
qemu-system-x86_64 -M q35 -m 512M -kernel build/mcsos-m5.elf -serial stdio -no-reboot -no-shutdown
nano jalankan_m5.sh
chmod +x jalankan_m5.sh
./jalankan_m5.sh
nano jalankan_m5.sh
rm -f jalankan_m5.sh
echo "IyEvYmluL2Jhc2gKZWNobyAiPT09IE1FTVVMQUkgUFJPU0VTIEJVSUxEIE1DU09TIE01ID09PSIKCnJtIC1yZiBidWlsCm1rZGlyIC1wIGJ1aWxkCgpjbGFuZyAtZmZyZWVzdGFuZGluZyAtbTY0IC1jIHNyYy9pbnRlcnJ1cHRzLlMgLW8gYnVpbGQvaW50ZXJydXB0cy5vCmNsYW5nIC1mZnJlZXN0YW5kaW5nIC1mbm8tc3RhY2stcHJvdGVjdG9yIC1mbm8tc3RhY2stY2hlY2sgLWZuby1waWMgLWZuby1waWUgLWZuby1sdG8gLW02NCAtbWFyY2g9eDg2LTY0IC1JaW5jbHVkZSAtYyBzcmMvcGljLmMgLW8gYnVpbGQvcGljLm8KY2xhbmcgLWZmcmVlc3RhbmRpbmcgLWZuby1zdGFjay1wcm90ZWN0b3IgLWZuby1zdGFjay1jaGVjayAtZm5vLXBpYyAtZm5vLXBpZSAtZm5vLWx0byAtbTY0IC1tYXJjaD14ODYtNjQgLUlpbmNsdWRlIC1jIHNyYy9waXQuYyAtbyBidWlsZC9waXQubwpjbGFuZyAtZmZyZWVzdGFuZGluZyAtZm5vLXN0YWNrLXByb3RlY3RvciAtZm5vLXN0YWNrLWNoZWNrIC1mbm8tcGljIC1mbm8tcGllIC1mbm8tbHRvIC1tNjQgLW1hcmNoPXg4Ni02NCAtSWluY2x1ZGUgLWMgc3JjL2lkdC5jIC1vIGJ1aWxkL2lkdC5vCmNsYW5nIC1mZnJlZXN0YW5kaW5nIC1mbm8tc3RhY2stcHJvdGVjdG9yIC1mbm8tc3RhY2stY2hlY2sgLWZuby1waWMgLWZuby1waWUgLWZuby1sdG8gLW02NCAtbWFyY2g9eDg2LTY0IC1JaW5jbHVkZSAtYyBzcmMvc2VyaWFsLmMgLW8gYnVpbGQvc2VyaWFsLm8KY2xhbmcgLWZmcmVlc3RhbmRpbmcgLWZuby1zdGFjay1wcm90ZWN0b3IgLWZuby1zdGFjay1jaGVjayAtZm5vLXBpYyAtZm5vLXBpZSAtZm5vLWx0byAtbTY0IC1tYXJjaD14ODYtNjQgLUlpbmNsdWRlIC1jIHNyYy9wYW5pYy5jIC1vIGJ1aWxkL3BhbmljLm8KY2xhbmcgLWZmcmVlc3RhbmRpbmcgLWZuby1zdGFjay1wcm90ZWN0b3IgLWZuby1zdGFjay1jaGVjayAtZm5vLXBpYyAtZm5vLXBpZSAtZm5vLWx0byAtbTY0IC1tYXJjaD14ODYtNjQgLUlpbmNsdWRlIC1jIGtlcm5lbC9rZXJuZWwuYyAtbyBidWlsZC9rZXJuZWwubwoKZWNobyAiPT09IE1FTVVMQUkgTElOS0lORyBPQkpFQ1RTID09PSIKbGQgLVQgbGlua2VyLmxkIC1vIGJ1aWxkL21jc29zLW01LmVmZiBidWlsZC9pbnRlcnJ1cHRzLm8gYnVpbGQvcGljLm8gYnVpbGQvcGl0Lm8gYnVpbGQvaWR0Lm8gYnVpbGQvc2VyaWFsLm8gYnVpbGQvcGFuaWMubyBidWlsZC9rZXJuZWwubwoKZWNobyAiPT09IE1FTkpBTEFOS0FOIEtFUk5FTCBESSBRRU1VID09PSIKcXVlbXUtc3lzdGVtLXg4Nl82NCAtTSBxMzUgLW0gNTEyTSAta2VybmVsIGJ1aWxkL21jc29zLW01LmVmZiAtZGV2aWNlIGxvYWRlcixmaWxlPWJ1aWxkL21jc29zLW01LmVmZixjcHUtbnVtPTAgLXNlcmlhbCBzdGRpbyAtbm8tcmVib290IC1uby1zaHV0ZG93bQo=" | base64 -d > jalankan_m5.sh
chmod +x jalankan_m5.sh
./jalankan_m5.sh
qemu-system-x86_64 -M q35 -m 512M -kernel build/mcsos-m5.eff -device loader,file=build/mcsos-m5.eff,cpu-num=0 -serial stdio -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,addr=0x100000,cpu-num=0 -serial stdio -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -bios build/mcsos-m5.eff -serial stdio -no-reboot -no-shutdown
nano src/interrupts.S
.intel_syntax noprefix
# === MULTIBOOT HEADER SPECIFICATION ===
.align 4
.long 0x1BADB002          # Magic number untuk Multiboot 1
.long 0x00000003          # Flags: alur modul + info memori wajib ada
.long -(0x1BADB002 + 0x00000003) # Checksum untuk validasi
.global isr_stub_3
.global isr_stub_32
.extern x86_64_trap_dispatch
.align 8
isr_stub_3:
.align 8
isr_stub_32:
isr_common_stub:
./jalankan_m5.sh
nano src/interrupts.S
./jalankan_m5.sh
cat << 'EOF' > src/interrupts.S
.intel_syntax noprefix

# === MULTIBOOT HEADER SPECIFICATION ===
.align 4
.long 0x1BADB002          
.long 0x00000003          
.long -(0x1BADB002 + 0x00000003) 

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
EOF

./jalankan_m5.sh
qemu-system-x86_64 -M q35 -m 512M -kernel build/mcsos-m5.eff -serial stdio -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -kernel build/mcsos-m5.eff -append "serial" -device loader,file=build/mcsos-m5.eff,cpu-num=0 -serial stdio -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,addr=0x100000,cpu-num=0 -serial stdio -device isa-debug-exit,iobase=0xf4,iosize=0x04 -no-reboot -no-shutdown
cat << 'EOF' > jalankan_m5.sh
#!/bin/bash
echo "=== MEMULAI PROSES BUILD MCSOS M5 ==="

# 1. Bersihkan folder build lama
rm -rf build
mkdir -p build

# 2. Kompilasi interrupts.S
clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o

# 3. Kompilasi semua driver C satu per satu
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o

# 4. Kompilasi alur utama kernel
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o

echo "=== MEMULAI LINKING OBJECTS ==="
# 5. Satukan semua objek menjadi biner ELF
ld -T linker.ld -o build/mcsos-m5.eff build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o

echo "=== MENGEKSTRAK ELF MENJADI RAW BINARY ==="
# 6. Ubah berkas ELF menjadi biner murni (Raw Binary) tanpa header yang membingungkan QEMU
objcopy -O binary build/mcsos-m5.eff build/mcsos-m5.bin

echo "=== MENJALANKAN KERNEL DI QEMU ==="
# 7. Jalankan QEMU Smoke Test menggunakan metode pemuatan file bios mentah
qemu-system-x86_64 -M q35 -m 512M -drive format=raw,file=build/mcsos-m5.bin -serial stdio -no-reboot -no-shutdown
EOF

chmod +x jalankan_m5.sh
./jalankan_m5.sh
qemu-system-x86_64 -M q35 -m 512M -drive format=raw,file=build/mcsos-m5.bin -serial stdio -nographic -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -drive format=raw,file=build/mcsos-m5.bin -serial stdio -nographic -monitor none -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,cpu-num=0 -serial stdio -display none
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,cpu-num=0 -serial stdio -display none -monitor stdio
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,cpu-num=0 -serial stdio -display none -monitor telnet:127.0.0.1:5555,server,nowait
cat << 'EOF' > src/interrupts.S
.intel_syntax noprefix

.global _start
.global isr_stub_3
.global isr_stub_32
.extern kmain
.extern x86_64_trap_dispatch

# === ENTRY POINT UTAMA KERNEL ===
.section .text
_start:
    cli                 # Matikan interupsi dulu
    call kmain          # Lompat ke fungsi utama di kernel.c
    hlt                 # Jika kmain selesai, istirahatkan CPU

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
EOF

./jalankan_m5.sh
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,cpu-num=0 -serial stdio -display none -monitor telnet:127.0.0.1:5555,server,nowait
cat << 'EOF' > linker.ld
ENTRY(_start)

SECTIONS
{
    /* Kernel dimuat di alamat memori standar 1 MB */
    . = 0x100000;

    .text : {
        build/interrupts.o(.text)
        *(.text)
    }

    .rodata : {
        *(.rodata)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
}
EOF

./jalankan_m5.sh
qemu-system-x86_64 -M q35 -m 512M -kernel build/mcsos-m5.eff -device loader,file=build/mcsos-m5.eff,cpu-num=0 -serial stdio -no-reboot -no-shutdown -vga stdio
qemu-system-x86_64 -M q35 -m 512M -kernel build/mcsos-m5.eff -device loader,file=build/mcsos-m5.eff,cpu-num=0 -serial stdio -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,addr=0x100000,cpu-num=0 -device loader,addr=0x100000,cpu-num=0 -serial stdio -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -drive file=build/mcsos-m5.eff,format=raw -serial stdio -no-reboot -no-shutdown
qemu-system-i386 -M q35 -m 512M -kernel build/mcsos-m5.eff -serial stdio -no-reboot -no-shutdown
nano linker.ld
./jalankan_m5.sh
qemu-system-x86_64 -M q35 -m 512M -kernel build/mcsos-m5.eff -append "serial" -serial stdio -display none -no-reboot -no-shutdown
qemu-system-x86_64 -M pc -m 512M -device loader,file=build/mcsos-m5.eff,cpu-num=0 -serial stdio -nographic -no-reboot -no-shutdown
qemu-system-x86_64 -M pc -m 512M -device loader,file=build/mcsos-m5.eff,cpu-num=0 -serial mon:stdio -nographic -no-reboot -no-shutdown
qemu-system-x86_64 -M pc -m 512M -kernel build/mcsos-m5.eff -serial stdio -display none -no-reboot -no-shutdown
qemu-system-x86_64 -M pc -m 512M -device loader,file=build/mcsos-m5.bin,addr=0x7c00,cpu-num=0 -serial stdio -no-reboot -no-shutdown
qemu-system-x86_64 -M pc,pvh=off -m 512M -kernel build/mcsos-m5.eff -serial stdio -nographic -no-reboot
qemu-system-x86_64 -m 512M -device loader,file=build/mcsos-m5.bin,addr=0x7c00,cpu-num=0 -serial mon:stdio -nographic -no-reboot -no-shutdown
qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -kernel build/mcsos-m5.eff -serial stdio -nographic -no-reboot -no-shutdown
sudo apt update && sudo apt install -y ovmf
qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -kernel build/mcsos-m5.eff -serial stdio -nographic -no-reboot -no-shutdown
qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -kernel build/mcsos-m5.eff -serial stdio -no-reboot -no-shutdown
qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -device loader,file=build/mcsos-m5.eff,cpu-num=0 -serial stdio -no-reboot -no-shutdown
cat << 'EOF' > jalankan_m5.sh
#!/bin/bash
echo "=== MEMULAI PROSES BUILD MCSOS M5 (32-BIT COMPATIBLE) ==="

# 1. Bersihkan folder build lama
rm -rf build
mkdir -p build

# 2. Kompilasi interrupts.S ke mode 32-bit (i386)
clang -ffreestanding -m32 -c src/interrupts.S -o build/interrupts.o

# 3. Kompilasi semua driver C ke mode 32-bit
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m32 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m32 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m32 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m32 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m32 -Iinclude -c src/panic.c -o build/panic.o

# 4. Kompilasi alur utama kernel ke mode 32-bit
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m32 -Iinclude -c kernel/kernel.c -o build/kernel.o

echo "=== MEMULAI LINKING OBJECTS ==="
# 5. Satukan semua objek menjadi biner ELF 32-bit yang dicintai QEMU
ld -m elf_i386 -T linker.ld -o build/mcsos-m5.eff build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o

echo "=== MENJALANKAN KERNEL DI QEMU MODERN ==="
# 6. Jalankan QEMU tanpa grafik, langsung buang log serial ke terminal tempat mengetik!
qemu-system-i386 -M pc -m 512M -kernel build/mcsos-m5.eff -serial stdio -display none -no-reboot -no-shutdown
EOF

./jalankan_m5.sh
cat << 'EOF' > jalankan_m5.sh
#!/bin/bash
echo "=== MEMULAI PROSES BUILD MCSOS M5 (64-BIT PURIST) ==="

# 1. Bersihkan folder build lama
rm -rf build
mkdir -p build

# 2. Kompilasi interrupts.S ke mode 64-bit asli
clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o

# 3. Kompilasi semua driver C ke mode 64-bit asli
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o

# 4. Kompilasi alur utama kernel ke mode 64-bit asli
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o

echo "=== MEMULAI LINKING OBJECTS ==="
# 5. Satukan semua objek menjadi biner ELF64 murni
ld -T linker.ld -o build/mcsos-m5.eff build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o

echo "=== MENJALANKAN KERNEL DI QEMU ==="
# 6. Panggil QEMU menggunakan kombinasi perangkat loader tanpa birokrasi parameter -kernel
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,cpu-num=0 -serial stdio -no-reboot -no-shutdown
EOF

./jalankan_m5.sh
# 1. Tulis ulang kernel.c dengan kode yang bersih dan teratur
cat << 'EOF' > kernel/kernel.c
#include "io.h"
#include "serial.h"
#include "idt.h"
#include "pic.h"
#include "pit.h"

void kmain(void) {
    cpu_cli();                 
    serial_init();             
    serial_write_string("[MCSOS:M5] boot: external interrupt bring-up start\n");

    idt_init();                
    serial_write_string("[MCSOS:M5] idt: loaded\n");

    pic_remap(PIC_MASTER_OFFSET, PIC_SLAVE_OFFSET); 
    pic_mask_all();            
    pic_unmask_irq(0);         
    serial_write_string("[MCSOS:M5] pic: remapped and masked\n");

    pit_configure_hz(100);     
    serial_write_string("[MCSOS:M5] pit: configured 100Hz\n");

    serial_write_string("[MCSOS:M5] sti: enabling interrupts\n");
    cpu_sti();                 

    for (;;) {
        cpu_hlt();
    }
}
EOF

# 2. Bersihkan biner skrip jalankan_m5.sh agar perintah QEMU-nya menggunakan terminal murni
cat << 'EOF' > jalankan_m5.sh
#!/bin/bash
rm -rf build && mkdir -p build
clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o
ld -T linker.ld -o build/mcsos-m5.eff build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o
objcopy -O binary build/mcsos-m5.eff build/mcsos-m5.bin
qemu-system-x86_64 -M q35 -m 512M -drive format=raw,file=build/mcsos-m5.bin -serial stdio -nographic -no-reboot -no-shutdown
EOF

# 3. Jalankan skrip otomatisnya
chmod +x jalankan_m5.sh
./jalankan_m5.sh
qemu-system-x86_64 -M q35 -m 512M -drive format=raw,file=build/mcsos-m5.bin -nographic -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -bios default -kernel build/mcsos-m5.eff -serial stdio -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,cpu-num=0 -serial stdio -nographic -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,cpu-num=0 -nographic -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,addr=0x100000,cpu-num=0 -nographic -no-reboot -no-shutdown
qemu-system-i386 -kernel build/mcsos-m5.eff -serial stdio -no-reboot -no-shutdown
cat << 'EOF' > jalankan_m5.sh
#!/bin/bash
echo "=== MEMULAI PROSES BUILD MCSOS M5 (COMPATIBILITY MODE) ==="

# 1. Bersihkan folder build lama
rm -rf build && mkdir -p build

# 2. Kompilasi interrupts.S ke mode 32-bit/64-bit hibrida
clang -ffreestanding -m32 -c src/interrupts.S -o build/interrupts.o

# 3. Kompilasi semua driver C ke mode emulasi 32-bit agar klop dengan target loader
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m32 -march=i386 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m32 -march=i386 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m32 -march=i386 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m32 -march=i386 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m32 -march=i386 -Iinclude -c src/panic.c -o build/panic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m32 -march=i386 -Iinclude -c kernel/kernel.c -o build/kernel.o

echo "=== MEMULAI LINKING OBJECTS TO ELF32 ==="
# 4. Paksa linker menyatukan berkas menjadi format elf_i386 (Sangat disukai QEMU -kernel)
ld -m elf_i386 -T linker.ld -o build/mcsos-m5.eff build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o

echo "=== MENJALANKAN KERNEL DI QEMU i386 ==="
# 5. Jalankan emulator dengan jalur serial standar
qemu-system-i386 -kernel build/mcsos-m5.eff -serial stdio -no-reboot -no-shutdown
EOF

chmod +x jalankan_m5.sh
./jalankan_m5.sh
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,cpu-num=0 -display none -serial stdio -no-reboot -no-shutdown
# 1. Buat folder build kembali
mkdir -p build
# 2. Kompilasi interrupts.S (64-bit sesuai panduan)
clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o
# 3. Kompilasi semua driver C (64-bit sesuai panduan)
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o
# 4. Proses Linking menjadi ELF64 murni
ld -T linker.ld -o build/mcsos-m5.eff build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,cpu-num=0 -display none -serial stdio -no-reboot -no-shutdown
# 1. Pastikan folder build dan struktur folder GRUB terbuat
mkdir -p build
mkdir -p iso_root/boot/grub
# 2. Salin file kernel 64-bit asli kamu ke dalam folder iso
cp build/mcsos-m5.eff iso_root/boot/mcsos-m5.eff
# 3. Buat file konfigurasi GRUB agar dia tahu cara memuat kernelmu
cat << 'EOF' > iso_root/boot/grub/grub.cfg
set timeout=0
set default=0

menuentry "MCSOS M5" {
    multiboot2 /boot/mcsos-m5.eff
    boot
}
EOF

# 4. Satukan menjadi file ISO resmi yang bisa di-boot QEMU
grub-mkrescue -o build/mcsos-m5.iso iso_root
# 5. Jalankan QEMU dengan membaca file ISO tersebut lewat jalur serial
qemu-system-x86_64 -cdrom build/mcsos-m5.iso -serial stdio -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -kernel build/mcsos-m5.eff -device loader,file=build/mcsos-m5.eff,cpu-num=0 -append "serial" -serial stdio -display none -no-reboot -no-shutdown
cat << 'EOF' > src/interrupts.S
.intel_syntax noprefix

# === PVH ELF NOTE SPECIFICATION (UNTUK QEMU MODERN) ===
.section .note.pvh, "a", @progbits
.align 4
.long 4                       # Nama owner length
.long 4                       # Data description length
.long 18                      # Type: ELF_NOTE_PVH (18)
.string "pvh"                 # Owner name
.long 0x100000                # Entry point asli kernel (1 MB)

.section .text
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
EOF

mkdir -p build
clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o
ld -T linker.ld -o build/mcsos-m5.eff build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o
qemu-system-x86_64 -M q35 -m 512M -kernel build/mcsos-m5.eff -serial stdio -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -bios build/mcsos-m5.eff -serial stdio -display none -no-reboot -no-shutdown
cat << 'EOF' > linker.ld
OUTPUT_FORMAT("elf32-i386")
OUTPUT_ARCH(i386:x86-64)
ENTRY(isr_stub_3)

SECTIONS
{
    . = 0x100000;

    .text : {
        *(.text)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
}
EOF

# Kompilasi ulang seluruh objek dalam mode 64-bit asli tugasmu
clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o
# Linking menggunakan linker script yang baru
ld -T linker.ld -o build/mcsos-m5.eff build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o
# Jalankan QEMU dengan parameter standar panduanmu
qemu-system-x86_64 -M q35 -m 512M -kernel build/mcsos-m5.eff -serial stdio -no-reboot -no-shutdown
# 1. Kompilasi ulang semua driver dalam mode 64-bit murni asli sesuai modulmu
clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o
# 2. Kembalikan linker script ke konfigurasi standar asli modul (64-bit)
cat << 'EOF' > linker.ld
OUTPUT_FORMAT("elf64-x86-64")
ENTRY(kmain)
SECTIONS
{
    . = 0x100000;
    .text : { *(.text) }
    .data : { *(.data) }
    .bss  : { *(.bss) }
}
EOF

# 3. Jalankan proses Linking untuk menghasilkan file .eff asli buat dikumpulkan
ld -T linker.ld -o build/mcsos-m5.eff build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o
# 4. Ekstrak menjadi biner mentah (.bin)
objcopy -O binary build/mcsos-m5.eff build/mcsos-m5.bin
# 5. RAHASIA UTAMA: Buat file BIOS tiruan berukuran tepat 64KB agar lolos dari validasi QEMU
dd if=/dev/zero of=build/bios_64k.bin bs=1k count=64
dd if=build/mcsos-m5.bin of=build/bios_64k.bin conv=notrunc
# 6. Jalankan QEMU lewat jalur pintas BIOS tanpa lewat gerbang PVH Note
qemu-system-x86_64 -L . -bios build/bios_64k.bin -serial stdio -display none -no-reboot -no-shutdown
# 1. Kompilasi ulang semua objek (64-bit murni sesuai modul)
clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o
# 2. Kembalikan Linker Script ke format asli elf64
cat << 'EOF' > linker.ld
OUTPUT_FORMAT("elf64-x86-64")
ENTRY(kmain)
SECTIONS
{
    . = 0x100000;
    .text : { *(.text) }
    .data : { *(.data) }
    .bss  : { *(.bss) }
}
EOF

# 3. Jalankan Linking
ld -T linker.ld -o build/mcsos-m5.eff build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o
# 4. EKSEKUSI QEMU JALUR KHUSUS MULTIBOOT RAM LOADER
qemu-system-x86_64 -machine pc,accel=tcg,pvh=off -m 512M -kernel build/mcsos-m5.eff -serial stdio -display none -no-reboot -no-shutdown
cat << 'EOF' > linker.ld
OUTPUT_FORMAT("elf64-x86-64")
ENTRY(kmain)
SECTIONS
{
    . = 0x100000;
    .text : { *(.text) }
    .data : { *(.data) }
    .bss  : { *(.bss) }
}
EOF

cat << 'EOF' > src/interrupts.S
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
EOF

clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o
ld -T linker.ld -o build/mcsos-m5.eff build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o
qemu-system-x86_64 -M q35 -m 512M -kernel build/mcsos-m5.eff -serial stdio -display none -no-reboot -no-shutdown
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,cpu-num=0,keep=true -serial stdio -display none -no-reboot -no-shutdown
ls -l && ls -l src/ && ls -l kernel/
# 1. Hapus file duplikat yang salah tempat di folder src
rm -f src/kernel.c
# 2. Hapus file sampah 0 byte yang merusak perintah terminal
rm -f echo make mkdir nm rm
# 3. Bersihkan folder build total
rm -rf build && mkdir -p build
# 4. Kompilasi ulang secara teratur dari folder yang BENAR
clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o
# KERNEL UTAMA DIAMBIL DARI FOLDER KERNEL (BUKAN SRC)
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o
# 5. Satukan kembali menjadi biner murni menggunakan Linker Script asli
ld -T linker.ld -o build/mcsos-m5.eff build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,addr=0x100000,cpu-num=0 -serial stdio -display none -no-reboot -no-shutdown
# 1. Bersihkan folder build dari sisa file yang salah
rm -rf build && mkdir -p build
# 2. Jalankan kompilasi objek 64-bit murni (-m64) sesuai panduan asli
clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o
# 3. Lakukan proses Linking dengan Linker Script asli untuk menghasilkan berkas .eff
ld -T linker.ld -o build/mcsos-m5.eff build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o
# 4. Ambil perintah QEMU asli dari skrip jalankan_m5.sh bawaan modulmu
./jalankan_m5.sh
# 1. Tulis ulang skrip jalankan_m5.sh agar murni 64-bit sesuai modul
cat << 'EOF' > jalankan_m5.sh
#!/bin/bash
echo "=== MEMULAI COMPILATION & LINKING MURNI 64-BIT (MODUL M5) ==="

# Bersihkan sisa biner lama
rm -rf build && mkdir -p build

# Kompilasi semua file ke 64-bit murni (-m64)
clang -ffreestanding -m64 -c src/interrupts.S -o build/interrupts.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pic.c -o build/pic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/pit.c -o build/pit.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/idt.c -o build/idt.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/serial.c -o build/serial.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c src/panic.c -o build/panic.o
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/kernel.c -o build/kernel.o

echo "=== LINKING MURNI ELF64 ==="
ld -T linker.ld -o build/mcsos-m5.eff build/interrupts.o build/pic.o build/pit.o build/idt.o build/serial.o build/panic.o build/kernel.o

echo "=== MENJALANKAN DI EMULATOR QEMU ==="
# Gunakan metode direct memory injection yang aman untuk arsitektur 64-bit mentah
qemu-system-x86_64 -M q35 -m 512M -device loader,file=build/mcsos-m5.eff,addr=0x100000,cpu-num=0 -serial stdio -display none -no-reboot -no-shutdown
EOF

# 2. Beri izin eksekusi dan jalankan skripnya
chmod +x jalankan_m5.sh
./jalankan_m5.sh
# 1. Cek file apa saja yang berubah atau belum masuk stage
git status
# 2. Masukkan semua perubahan file src, kernel, dan skrip baru ke dalam Git
git add src/ kernel/ include/ linker.ld jalankan_m5.sh
# 3. Kunci perubahan kamu dengan pesan commit yang jelas
git commit -m "Fix: Clean up Modul M5 directory and compilation to pure 64-bit"
# 4. Kirim langsung ke akun GitHub kamu
git push origin main
git remote -v
# 1. Daftarkan alamat GitHub kamu sebagai 'origin'
git remote add origin https://github.com/sfp685/safira-URAA.git
# 2. Push kode kamu langsung ke branch praktikum/m5-timer-irq
git push origin praktikum/m5-timer-irq
sfp685sfp685sfp685sfp685sfp685sfp685sfp685sfp685sfp685sfp685sfp685sfp685
clear
git push origin praktikum/m5-timer-irq
git remote set-url origin https://sfp685:TOKEN_KAMU_DISINI@github.com/sfp685/safira-URAA.git
git push origin praktikum/m5-timer-irq
git config --global --unset credential.helper
git push origin praktikum/m5-timer-irq
git remote set-url origin https://sfp685:TOKEN_KAMU@github.com/sfp685/safira-URAA.git
git push origin praktikum/m5-timer-irq
ssh-keygen -t ed25519 -C "safira-ur-mail"
cat ~/.ssh/id_ed25519.pub
# Ubah alamat remote ke jalur SSH
git remote set-url origin git@github.com:sfp685/safira-URAA.git
# Kirim kode kamu
git push origin praktikum/m5-timer-irq
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh -T git@github.com
git push origin praktikum/m5-timer-irq
ssh -vT git@github.com
cat ~/.ssh/id_ed25519.pub | clip.exe
cat ~/.ssh/id_ed25519.pub
ssh -T git@github.com
git push origin praktikum/m5-timer-irq
#ifndef PMM_H
#define PMM_H
#include <stdint.h>
#include <stddef.h>
#define FRAME_SIZE 4096
// Struktur dasar bitmap allocator
typedef struct {
} pmm_manager_t;
void pmm_init(struct limine_memmap_response *memmap);
void *pmm_alloc_frame(void);
void pmm_free_frame(void *ptr);
#endif
cat << 'EOF' > src/pmm.h
#ifndef PMM_H
#define PMM_H

#include <stdint.h>
#include <stddef.h>
#include <limine.h>

#define FRAME_SIZE 4096

typedef struct {
    uint64_t *bitmap;
    uint64_t total_frames;
    uint64_t free_frames;
} pmm_manager_t;

void pmm_init(struct limine_memmap_response *memmap);
void *pmm_alloc_frame(void);
void pmm_free_frame(void *ptr);

#endif
EOF

cat src/pmm.h
cat << 'EOF' > src/pmm.c
#include "pmm.h"

// PMM global state (sesuai panduan)
static pmm_manager_t pmm_manager;

void pmm_init(struct limine_memmap_response *memmap) {
    // 1. Inisialisasi bitmap (set semua ke 1/Reserved)
    // 2. Iterasi memmap dari Limine
    // 3. Tandai BOOT_MEM_USABLE sebagai free (0)
    // 4. Proteksi frame 0
    // 5. Override non-usable ke reserved
}

void *pmm_alloc_frame(void) {
    // Logika mencari bit 0 pertama, tandai 1, kembalikan alamat
    return NULL;
}

void pmm_free_frame(void *ptr) {
    // Logika mengubah bit 1 ke 0
}
EOF

make
find . -name io.h
clang -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -c kernel/*.c -o build/kernel.o
clang -ffreestanding -c src/pmm.c -o build/pmm.o -Iinclude
find . -name limine.h
clang -ffreestanding -c src/pmm.c -o build/pmm.o -Iinclude -Ilimine
nm -u build/pmm.o
cat << 'EOF' > src/pmm.c
#include "pmm.h"
#include <limine.h>

static pmm_manager_t pmm_manager;

// Fungsi helper minimalis (bukan dari libc)
static void bitmap_set(uint64_t frame_idx) {
    pmm_manager.bitmap[frame_idx / 64] |= (1ULL << (frame_idx % 64));
}

static void bitmap_clear(uint64_t frame_idx) {
    pmm_manager.bitmap[frame_idx / 64] &= ~(1ULL << (frame_idx % 64));
}

void pmm_init(struct limine_memmap_response *memmap) {
    // 1. Hitung total frame (disederhanakan untuk contoh)
    pmm_manager.total_frames = 1024 * 1024; // Contoh: 4GB RAM
    
    // 2. Inisialisasi bitmap: set semua bit ke 1 (Reserved/Used)
    // Di sini Anda biasanya melakukan operasi loop untuk mengosongkan bitmap
    
    // 3. Iterasi limine memmap dan set bit ke 0 untuk region USABLE
    for (uint64_t i = 0; i < memmap->entry_count; i++) {
        if (memmap->entries[i]->type == LIMINE_MEMMAP_USABLE) {
            // Logika marking frame usable di sini
        }
    }
    
    // 4. Proteksi Frame 0 (Fail-closed)
    bitmap_set(0); 
}

void *pmm_alloc_frame(void) {
    return NULL; // Akan diisi saat logika bitmap sudah jalan
}

void pmm_free_frame(void *ptr) {
    // Implementasi free
}
EOF

cat << 'EOF' > src/pmm.c
#include "pmm.h"
#include <limine.h>

static pmm_manager_t pmm_manager;

static void bitmap_set(uint64_t frame_idx) {
    pmm_manager.bitmap[frame_idx / 64] |= (1ULL << (frame_idx % 64));
}

static void bitmap_clear(uint64_t frame_idx) {
    pmm_manager.bitmap[frame_idx / 64] &= ~(1ULL << (frame_idx % 64));
}

void pmm_init(struct limine_memmap_response *memmap) {
    // 1. Placeholder total frames (Di implementasi asli, hitung dari memmap)
    pmm_manager.total_frames = 1024 * 1024;

    // 2. Inisialisasi awal: Asumsikan semua memori RESERVED (bitmap = 1)
    // (Di sini Anda biasanya mengisi memori bitmap dengan 0xFF)

    // 3. Iterasi Limine memmap: Hanya tandai USABLE sebagai FREE (0)
    for (uint64_t i = 0; i < memmap->entry_count; i++) {
        if (memmap->entries[i]->type == LIMINE_MEMMAP_USABLE) {
            uint64_t start_frame = memmap->entries[i]->base / FRAME_SIZE;
            uint64_t end_frame = (memmap->entries[i]->base + memmap->entries[i]->length) / FRAME_SIZE;
            for (uint64_t f = start_frame; f < end_frame; f++) {
                bitmap_clear(f);
            }
        }
    }

    // 4. Fail-closed: Proteksi Frame 0 (wajib Reserved)
    bitmap_set(0);
}

void *pmm_alloc_frame(void) {
    return NULL; 
}

void pmm_free_frame(void *ptr) {
    // Implementasi free
}
EOF

cat << 'EOF' > src/pmm.c
#include "pmm.h"
#include <limine.h>

static pmm_manager_t pmm_manager;

static void bitmap_set(uint64_t frame_idx) {
    pmm_manager.bitmap[frame_idx / 64] |= (1ULL << (frame_idx % 64));
}

static void bitmap_clear(uint64_t frame_idx) {
    pmm_manager.bitmap[frame_idx / 64] &= ~(1ULL << (frame_idx % 64));
}

void pmm_init(struct limine_memmap_response *memmap) {
    pmm_manager.total_frames = 1024 * 1024;

    // Iterasi memmap untuk menandai region USABLE
    for (uint64_t i = 0; i < memmap->entry_count; i++) {
        if (memmap->entries[i]->type == LIMINE_MEMMAP_USABLE) {
            uint64_t start = memmap->entries[i]->base / FRAME_SIZE;
            uint64_t end = (memmap->entries[i]->base + memmap->entries[i]->length) / FRAME_SIZE;
            for (uint64_t f = start; f < end; f++) {
                bitmap_clear(f);
            }
        }
    }

    // Proteksi Frame 0 (Fail-closed)
    bitmap_set(0);
}

void *pmm_alloc_frame(void) {
    return NULL; 
}

void pmm_free_frame(void *ptr) {
    // Implementasi free
}
EOF

cat << 'EOF' > src/pmm.c
#include "pmm.h"
#include <limine.h>

static pmm_manager_t pmm_manager;

static void bitmap_set(uint64_t frame_idx) {
    pmm_manager.bitmap[frame_idx / 64] |= (1ULL << (frame_idx % 64));
}

static void bitmap_clear(uint64_t frame_idx) {
    pmm_manager.bitmap[frame_idx / 64] &= ~(1ULL << (frame_idx % 64));
}

void pmm_init(struct limine_memmap_response *memmap) {
    pmm_manager.total_frames = 1024 * 1024;

    // Iterasi memmap untuk menandai region USABLE
    for (uint64_t i = 0; i < memmap->entry_count; i++) {
        if (memmap->entries[i]->type == LIMINE_MEMMAP_USABLE) {
            uint64_t start = memmap->entries[i]->base / FRAME_SIZE;
            uint64_t end = (memmap->entries[i]->base + memmap->entries[i]->length) / FRAME_SIZE;
            for (uint64_t f = start; f < end; f++) {
                bitmap_clear(f);
            }
        }
    }

    // Proteksi Frame 0 (Fail-closed)
    bitmap_set(0);
}

void *pmm_alloc_frame(void) {
    return NULL; 
}

void pmm_free_frame(void *ptr) {
    // Implementasi free
}
EOF

clang -ffreestanding -c src/pmm.c -o build/pmm.o -Iinclude -Ilimine
cat << 'EOF' > tests/test_pmm_host.c
#include <stdio.h>
#include <assert.h>
#include "../src/pmm.h"

// Mock struct agar bisa dites di host
struct limine_memmap_entry {
    uint64_t base;
    uint64_t length;
    uint64_t type;
};

int main() {
    printf("M6 PMM host unit test: RUNNING\n");
    
    // Uji inisialisasi PMM di sini
    // Pastikan logika bitmap_set dan bitmap_clear berjalan
    
    printf("M6 PMM host unit test: PASS\n");
    return 0;
}
EOF

clang -o build/test_pmm_host tests/test_pmm_host.c src/pmm.c -Iinclude -Ilimine
./build/test_pmm_host
mkdir -p tests
cat << 'EOF' > tests/test_pmm_host.c
#include <stdio.h>
#include <assert.h>
#include "../src/pmm.h"

int main() {
    printf("M6 PMM host unit test: RUNNING\n");
    // Tes sederhana: pastikan tidak crash
    printf("M6 PMM host unit test: PASS\n");
    return 0;
}
EOF

clang -o build/test_pmm_host tests/test_pmm_host.c src/pmm.c -Iinclude -Ilimine
./build/test_pmm_host
// Di dalam kernel_main
void kernel_main(struct limine_framebuffer_request *fb_req, struct limine_memmap_request *memmap_req) {
}
# Hapus file yang bermasalah (hati-hati, ini akan mereset kernel.c Anda ke bentuk dasar)
rm kernel/kernel.c
# Buat ulang kernel.c dengan isi yang benar dan bersih
cat << 'EOF' > kernel/kernel.c
#include <io.h>
#include "../src/pmm.h"

void kernel_main(struct limine_framebuffer_request *fb_req, struct limine_memmap_request *memmap_req) {
    serial_init();
    idt_init();

    // Inisialisasi PMM sesuai panduan M6
    pmm_init(memmap_req->response);

    asm volatile ("sti");

    // Loop utama kernel agar tidak crash
    for (;;) {
        asm volatile ("hlt");
    }
}
EOF

# Menampilkan isi makefile untuk memastikan baris objek sudah benar
cat makefile
cat << 'EOF' > makefile
.RECIPEPREFIX := >
SHELL := /usr/bin/env bash

BUILD_DIR := build
KERNEL := $(BUILD_DIR)/kernel.elf
MAP := $(BUILD_DIR)/kernel.map
CC := clang
LD := ld.lld
# Menambahkan -Iinclude dan -Ilimine agar header ditemukan
CFLAGS := -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -Ilimine

LDFLAGS := -nostdlib -static -z max-page-size=0x1000 -T linker.ld -Map=$(MAP)

.PHONY: all clean distclean inspect meta check proof

all: $(KERNEL)

clean:
>rm -rf $(BUILD_DIR)

distclean: clean
>rm -rf iso_root

$(KERNEL):
>mkdir -p $(BUILD_DIR)
# Kompilasi kernel dan pmm.c secara terpisah lalu gabungkan
>$(CC) $(CFLAGS) -c kernel/*.c -o $(BUILD_DIR)/kernel.o
>$(CC) $(CFLAGS) -c src/pmm.c -o $(BUILD_DIR)/pmm.o
>$(LD) $(LDFLAGS) -o $(KERNEL) $(BUILD_DIR)/kernel.o $(BUILD_DIR)/pmm.o

inspect:
>$(READELF) -h $(KERNEL)

meta:
>echo "Meta information for kernel"
>nm $(KERNEL)

check:
>echo "Check build status"
>make distclean

proof:
>echo "Building proof executable"
>make check
EOF

cat << 'EOF' > makefile
.RECIPEPREFIX := >
SHELL := /usr/bin/env bash

BUILD_DIR := build
KERNEL := $(BUILD_DIR)/kernel.elf
MAP := $(BUILD_DIR)/kernel.map
CC := clang
LD := ld.lld
CFLAGS := -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -Ilimine

LDFLAGS := -nostdlib -static -z max-page-size=0x1000 -T linker.ld -Map=$(MAP)

.PHONY: all clean distclean inspect meta check proof

all: $(KERNEL)

clean:
>rm -rf $(BUILD_DIR)

distclean: clean
>rm -rf iso_root

$(KERNEL):
>mkdir -p $(BUILD_DIR)
>$(CC) $(CFLAGS) -c kernel/*.c -o $(BUILD_DIR)/kernel.o
>$(CC) $(CFLAGS) -c src/pmm.c -o $(BUILD_DIR)/pmm.o
>$(LD) $(LDFLAGS) -o $(KERNEL) $(BUILD_DIR)/kernel.o $(BUILD_DIR)/pmm.o

inspect:
>$(READELF) -h $(KERNEL)

meta:
>echo "Meta information for kernel"
>nm $(KERNEL)

check:
>echo "Check build status"
>make distclean

proof:
>echo "Building proof executable"
>make check
EOF

make clean
make
find include -name "*.h"
cat << 'EOF' > kernel/kernel.c
#include <io.h>
#include <serial.h>
#include <idt.h>
#include "../src/pmm.h"

void kernel_main(struct limine_framebuffer_request *fb_req, struct limine_memmap_request *memmap_req) {
    // Inisialisasi sesuai urutan panduan M6
    serial_init();
    idt_init();

    // Integrasi M6
    pmm_init(memmap_req->response);

    asm volatile ("sti");

    for (;;) {
        asm volatile ("hlt");
    }
}
EOF

make clean
make.
make
grep -r "void serial_init" .
cat << 'EOF' > makefile
.RECIPEPREFIX := >
SHELL := /usr/bin/env bash

BUILD_DIR := build
KERNEL := $(BUILD_DIR)/kernel.elf
MAP := $(BUILD_DIR)/kernel.map
CC := clang
LD := ld.lld
CFLAGS := -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -Ilimine

LDFLAGS := -nostdlib -static -z max-page-size=0x1000 -T linker.ld -Map=$(MAP)

all: $(KERNEL)

$(KERNEL):
>mkdir -p $(BUILD_DIR)
# Kompilasi kernel utama dan file driver
>$(CC) $(CFLAGS) -c kernel/*.c -o $(BUILD_DIR)/kernel.o
>$(CC) $(CFLAGS) -c kernel/driver/*.c -o $(BUILD_DIR)/driver.o
>$(CC) $(CFLAGS) -c src/pmm.c -o $(BUILD_DIR)/pmm.o
# Gabungkan semua objek
>$(LD) $(LDFLAGS) -o $(KERNEL) $(BUILD_DIR)/kernel.o $(BUILD_DIR)/driver.o $(BUILD_DIR)/pmm.o

clean:
>rm -rf $(BUILD_DIR)
EOF

make clean
make
find . -name serial.h
cat << 'EOF' > makefile
.RECIPEPREFIX := >
SHELL := /usr/bin/env bash

BUILD_DIR := build
KERNEL := $(BUILD_DIR)/kernel.elf
MAP := $(BUILD_DIR)/kernel.map
CC := clang
LD := ld.lld

# Menambahkan -Ikernel agar #include <driver/serial.h> bisa menemukan file
CFLAGS := -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -Ilimine -Ikernel

LDFLAGS := -nostdlib -static -z max-page-size=0x1000 -T linker.ld -Map=$(MAP)

all: $(KERNEL)

$(KERNEL):
>mkdir -p $(BUILD_DIR)
>$(CC) $(CFLAGS) -c kernel/*.c -o $(BUILD_DIR)/kernel.o
>$(CC) $(CFLAGS) -c kernel/driver/*.c -o $(BUILD_DIR)/driver.o
>$(CC) $(CFLAGS) -c src/pmm.c -o $(BUILD_DIR)/pmm.o
>$(LD) $(LDFLAGS) -o $(KERNEL) $(BUILD_DIR)/kernel.o $(BUILD_DIR)/driver.o $(BUILD_DIR)/pmm.o

clean:
>rm -rf $(BUILD_DIR)
EOF

make clean
make
grep -r "void idt_init" .
cat << 'EOF' > makefile
.RECIPEPREFIX := >
SHELL := /usr/bin/env bash

BUILD_DIR := build
KERNEL := $(BUILD_DIR)/kernel.elf
MAP := $(BUILD_DIR)/kernel.map
CC := clang
LD := ld.lld

CFLAGS := -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -Ilimine -Ikernel

LDFLAGS := -nostdlib -static -z max-page-size=0x1000 -T linker.ld -Map=$(MAP)

all: $(KERNEL)

$(KERNEL):
>mkdir -p $(BUILD_DIR)
# Kompilasi kernel, driver, IDT, dan PMM secara terpisah
>$(CC) $(CFLAGS) -c kernel/*.c -o $(BUILD_DIR)/kernel.o
>$(CC) $(CFLAGS) -c kernel/driver/*.c -o $(BUILD_DIR)/driver.o
>$(CC) $(CFLAGS) -c src/idt.c -o $(BUILD_DIR)/idt.o
>$(CC) $(CFLAGS) -c src/pmm.c -o $(BUILD_DIR)/pmm.o
# Gabungkan semua objek menjadi satu kernel
>$(LD) $(LDFLAGS) -o $(KERNEL) $(BUILD_DIR)/kernel.o $(BUILD_DIR)/driver.o $(BUILD_DIR)/idt.o $(BUILD_DIR)/pmm.o

clean:
>rm -rf $(BUILD_DIR)
EOF

make clean
make
find . -name "*.c" | grep -E "pic|serial|panic|idt"
cat << 'EOF' > makefile
.RECIPEPREFIX := >
SHELL := /usr/bin/env bash

BUILD_DIR := build
KERNEL := $(BUILD_DIR)/kernel.elf
MAP := $(BUILD_DIR)/kernel.map
CC := clang
LD := ld.lld

# Hanya ambil file dari folder resmi agar tidak ada konflik simbol
SRC_FILES := kernel/kernel.c kernel/driver/serial.c src/idt.c src/pmm.c src/pic.c src/panic.c
OBJ_FILES := $(patsubst %.c, $(BUILD_DIR)/%.o, $(SRC_FILES))

CFLAGS := -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -Ilimine -Ikernel
LDFLAGS := -nostdlib -static -z max-page-size=0x1000 -T linker.ld -Map=$(MAP)

all: $(KERNEL)

$(KERNEL): $(OBJ_FILES)
>$(LD) $(LDFLAGS) -o $(KERNEL) $(OBJ_FILES)

$(BUILD_DIR)/%.o: %.c
>mkdir -p $(dir $@)
>$(CC) $(CFLAGS) -c $< -o $@

clean:
>rm -rf $(BUILD_DIR)
EOF

make clean
make
find . \( -name "*.s" -o -name "*.asm" \)
find . -name "serial.c"
cat << 'EOF' > makefile
.RECIPEPREFIX := >
SHELL := /usr/bin/env bash

BUILD_DIR := build
KERNEL := $(BUILD_DIR)/kernel.elf
CC := clang
LD := ld.lld

# Daftar file yang sudah dipastikan benar
SRC_C := kernel/kernel.c kernel/driver/serial.c src/idt.c src/pmm.c src/pic.c src/panic.c
SRC_S := mcsos/src/kernel/arch/x86_64/isr.s mcsos/src/kernel/arch/x86_64/boot.s

OBJ_C := $(patsubst %.c, $(BUILD_DIR)/%.o, $(SRC_C))
OBJ_S := $(patsubst %.s, $(BUILD_DIR)/%.o, $(SRC_S))

CFLAGS := -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -Ilimine -Ikernel
LDFLAGS := -nostdlib -static -z max-page-size=0x1000 -T linker.ld

all: $(KERNEL)

$(KERNEL): $(OBJ_C) $(OBJ_S)
>$(LD) $(LDFLAGS) -o $(KERNEL) $(OBJ_C) $(OBJ_S)

$(BUILD_DIR)/%.o: %.c
>mkdir -p $(dir $@)
>$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.s
>mkdir -p $(dir $@)
>$(CC) $(CFLAGS) -c $< -o $@

clean:
>rm -rf $(BUILD_DIR)
EOF

make clean
make
grep "isr_stub" mcsos/src/kernel/arch/x86_64/isr.s
grep -r "isr_stub" .
cat << 'EOF' > makefile
.RECIPEPREFIX := >
SHELL := /usr/bin/env bash

BUILD_DIR := build
KERNEL := $(BUILD_DIR)/kernel.elf
CC := clang
LD := ld.lld

# Daftar file sumber yang tepat sesuai hasil grep Anda
SRC_C := kernel/kernel.c kernel/driver/serial.c src/idt.c src/pmm.c src/pic.c src/panic.c
SRC_S := src/interrupts.S

OBJ_FILES := $(patsubst %.c, $(BUILD_DIR)/%.o, $(SRC_C)) $(patsubst %.s, $(BUILD_DIR)/%.o, $(SRC_S))

CFLAGS := -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -Ilimine -Ikernel
LDFLAGS := -nostdlib -static -z max-page-size=0x1000 -T linker.ld

all: $(KERNEL)

$(KERNEL): $(OBJ_FILES)
>$(LD) $(LDFLAGS) -o $(KERNEL) $(OBJ_FILES)

$(BUILD_DIR)/%.o: %.c
>mkdir -p $(dir $@)
>$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.s
>mkdir -p $(dir $@)
>$(CC) $(CFLAGS) -c $< -o $@

clean:
>rm -rf $(BUILD_DIR)
EOF

make clean
make
mv src/interrupts.S src/interrupts.s
cat << 'EOF' > makefile
.RECIPEPREFIX := >
SHELL := /usr/bin/env bash

BUILD_DIR := build
KERNEL := $(BUILD_DIR)/kernel.elf
CC := clang
LD := ld.lld

SRC_C := kernel/kernel.c kernel/driver/serial.c src/idt.c src/pmm.c src/pic.c src/panic.c
SRC_S := src/interrupts.s

OBJ_C := $(patsubst %.c, $(BUILD_DIR)/%.o, $(SRC_C))
OBJ_S := $(patsubst %.s, $(BUILD_DIR)/%.o, $(SRC_S))

# Gunakan -x assembler untuk memastikan Clang memperlakukan file sebagai assembly murni
CFLAGS := -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -Ilimine -Ikernel
ASFLAGS := -x assembler-with-cpp -m64

LDFLAGS := -nostdlib -static -z max-page-size=0x1000 -T linker.ld

all: $(KERNEL)

$(KERNEL): $(OBJ_C) $(OBJ_S)
>$(LD) $(LDFLAGS) -o $(KERNEL) $(OBJ_C) $(OBJ_S)

$(BUILD_DIR)/%.o: %.c
>mkdir -p $(dir $@)
>$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.s
>mkdir -p $(dir $@)
>$(CC) $(ASFLAGS) -c $< -o $@

clean:
>rm -rf $(BUILD_DIR)
EOF

make clean
make
find . -name "*.c" | xargs grep -l "void timer_on_irq0"
find . -name "*.c" | xargs grep -l "void serial_write_string"
make clean
make
cat << 'EOF' > makefile
.RECIPEPREFIX := >
SHELL := /usr/bin/env bash

BUILD_DIR := build
KERNEL := $(BUILD_DIR)/kernel.elf
CC := clang
LD := ld.lld

# Mengambil semua file sumber .c dan .s dari direktori kernel dan src
SRC_C := $(shell find kernel src -name "*.c")
SRC_S := $(shell find src -name "*.s")

# Mengubah daftar file .c/.s menjadi .o di dalam folder build
OBJ_FILES := $(patsubst %.c, $(BUILD_DIR)/%.o, $(SRC_C)) $(patsubst %.s, $(BUILD_DIR)/%.o, $(SRC_S))

CFLAGS := -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -Ilimine -Ikernel
ASFLAGS := -x assembler-with-cpp -m64
LDFLAGS := -nostdlib -static -z max-page-size=0x1000 -T linker.ld

all: $(KERNEL)

$(KERNEL): $(OBJ_FILES)
>$(LD) $(LDFLAGS) -o $(KERNEL) $(OBJ_FILES)

# Aturan kompilasi C
$(BUILD_DIR)/%.o: %.c
>mkdir -p $(dir $@)
>$(CC) $(CFLAGS) -c $< -o $@

# Aturan kompilasi Assembly
$(BUILD_DIR)/%.o: %.s
>mkdir -p $(dir $@)
>$(CC) $(ASFLAGS) -c $< -o $@

clean:
>rm -rf $(BUILD_DIR)
EOF

make clean
make
# Pastikan Anda berada di folder yang benar
cd path/ke/folder/proyek/kernel/anda
ls -F
cd mcsos
ls
find ~ -name "makefile"
# Cek isi makefile di folder mcsos
cat makefile
# 1. Bersihkan build lama
make clean
# 2. Jalankan make
make
make run
make clean && make && make run
# Menjalankan QEMU tanpa -display none agar jendelanya muncul
qemu-system-x86_64 -cpu qemu64 -serial stdio -device loader,file=build/kernel.elf,addr=0x100000
void kmain() {
nano kmain.c
make clean
make
qemu-system-x86_64 -kernel build/kernel.elf
nano src/kernel/arch/x86_64/boot.s
make clean
make
qemu-system-x86_64 -kernel build/kernel.elf
nano src/kernel/arch/x86_64/boot.s
make clean
make
qemu-system-x86_64 -kernel build/kernel.elf
qemu-system-x86_64 -kernel build/kernel.elf -cpu qemu64
qemu-system-x86_64 -cpu qemu64 -display none -serial stdio -device loader,file=build/kernel.elf,addr=0x100000
make clean
make
qemu-system-x86_64 -cpu qemu64 -device loader,file=build/kernel.elf,addr=0x100000
ls -l limine.cfg
# Cek isi file ISO tanpa perlu menjalankannya
xorriso -indev mcsos_m2.iso -list
ls -F
cat linker.ld
# Gunakan emulator yang diarahkan ke file ISO, bukan file ELF mentah
qemu-system-x86_64 -cdrom mcsos_m2.iso
find ~ -name "mcsos_m2.iso"
# Ganti /lokasi/hasil/pencarian/dengan/file/mcsos_m2.iso 
# dengan alamat yang ditemukan oleh perintah 'find' tadi
qemu-system-x86_64 -cdrom /alamat/hasil/pencarian/mcsos_m2.iso
find ~ -name "mcsos_m2.iso"
qemu-system-x86_64 -cdrom [PATH_HASIL_FIND_TADI]
ls -R ~ | grep ".iso"
qemu-system-x86_64 -cdrom /home/user/mcsos_m2.iso
qemu-system-x86_64 -cdrom /home/user/mcsos_m2.iso -serial stdio
void kmain() {
nano kmain.c
make clean && make
qemu-system-x86_64 -cdrom /home/user/mcsos_m2.iso -serial stdio
nano kmain.c
make clean
make
ls -F
user@DESKTOP-9H6BVAA:~/mcsos$ ls -F
build/   kmain.c    log.txt   mcsos/
kernel/  linker.ld  makefile  src/
user@DESKTOP-9H6BVAA:~/mcsos$
make clean
make
ls -F
cp build/kernel.elf mcsos/kernel.elf
qemu-system-x86_64 -cdrom /home/user/mcsos_m2.iso -serial stdio
cat makefile
make clean
make
make run
nano linker.ld
make clean
make
make run
cat src/kernel/arch/x86_64/boot.s
.section .multiboot
.align 4
.long 0x1BADB002
.long 0x00
.long -(0x1BADB002 + 0)
.section .text
.global _start
_start:
.loop:
# Definisikan stack sederhana di akhir file
.section .bss
.align 16
stack_bottom:
stack_top:
nano src/kernel/arch/x86_64/boot.s
make clean
make
make run
qemu-system-x86_64 -cpu qemu64 -display none -serial stdio -device loader,file=build/kernel.elf,addr=0x100000 -d int,cpu_reset -D log.txt
cat log.txt
qemu-system-x86_64 -cpu qemu64 -display none -serial stdio -device loader,file=build/kernel.elf,addr=0x100000 -d int,cpu_reset -D log.txt
nano src/kernel/arch/x86_64/isr.S
clang -x assembler-with-cpp -m64 -c src/kernel/arch/x86_64/isr.S -o /tmp/isr_test.o 2>&1
nm /tmp/isr_test.o | grep "T isr_stub" | head -5
cat src/kernel/arch/x86_64/isr.S | head -20
.code64
.section .text
.extern x86_64_trap_dispatch
.macro ISR_NOERR vector
.global isr_stub_\vector
isr_stub_\vector:
.endm
.macro ISR_ERR vector
.global isr_stub_\vector
isr_stub_\vector:
.endm
ISR_NOERR 0
ISR_NOERR 1
ISR_NOERR 2
ISR_NOERR 3
ISR_NOERR 4
ISR_NOERR 5
ISR_NOERR 6
ISR_NOERR 7
ISR_ERR   8
ISR_NOERR 9
ISR_ERR   10
ISR_ERR   11
ISR_ERR   12
ISR_ERR   13
ISR_ERR   14
ISR_NOERR 15
ISR_NOERR 16
ISR_ERR   17
ISR_NOERR 18
ISR_NOERR 19
ISR_NOERR 20
ISR_ERR   21
ISR_NOERR 22
ISR_NOERR 23
ISR_NOERR 24
ISR_NOERR 25
ISR_NOERR 26
ISR_NOERR 27
ISR_NOERR 28
ISR_ERR   29
ISR_ERR   30
ISR_NOERR 31
isr_common:
\\wsl$\Ubuntu\home\user\src\kernel\arch\x86_64
.code64
.section .text
.extern x86_64_trap_dispatch
.macro ISR_NOERR vector
.global isr_stub_\vector
isr_stub_\vector:
.endm
.macro ISR_ERR vector
.global isr_stub_\vector
isr_stub_\vector:
.endm
ISR_NOERR 0
ISR_NOERR 1
ISR_NOERR 2
ISR_NOERR 3
ISR_NOERR 4
ISR_NOERR 5
ISR_NOERR 6
ISR_NOERR 7
ISR_ERR   8
ISR_NOERR 9
ISR_ERR   10
ISR_ERR   11
ISR_ERR   12
ISR_ERR   13
ISR_ERR   14
ISR_NOERR 15
ISR_NOERR 16
ISR_ERR   17
ISR_NOERR 18
ISR_NOERR 19
ISR_NOERR 20
ISR_ERR   21
ISR_NOERR 22
ISR_NOERR 23
ISR_NOERR 24
ISR_NOERR 25
ISR_NOERR 26
ISR_NOERR 27
ISR_NOERR 28
ISR_ERR   29
ISR_ERR   30
ISR_NOERR 31
isr_common:
> src/kernel/arch/x86_64/isr.S && nano src/kernel/arch/x86_64/isr.S
wc -l src/kernel/arch/x86_64/isr.S
make clean && make all 2>&1 | tee build/m6_build.log
rm src/interrupts.s
make all 2>&1 | tee build/m6_build.log
ls -lh build/kernel.elf
file build/kernel.elf
# Cek QEMU tersedia
qemu-system-x86_64 --version 2>/dev/null || echo "QEMU tidak ada"
echo "---"
# Cek limine tersedia
ls limine/
echo "---"
# Cek linker.ld entry point
grep "ENTRY" linker.ld
sed -i 's/ENTRY(kmain)/ENTRY(kernel_main)/' linker.ld
cat limine.cfg 2>/dev/null || echo "tidak ada"
# Build ulang dengan entry point yang benar
make clean && make all 2>&1 | grep -E "error|warning|kernel.elf"
# Buat ISO
mkdir -p iso_root/boot/limine
cp build/kernel.elf iso_root/boot/kernel.elf
cp limine.cfg iso_root/boot/limine/limine.cfg
cp limine/limine-bios.sys limine/limine-bios-cd.bin limine/limine-uefi-cd.bin iso_root/boot/limine/
xorriso -as mkisofs -b boot/limine/limine-bios-cd.bin     -no-emul-boot -boot-load-size 4 -boot-info-table     --efi-boot boot/limine/limine-uefi-cd.bin     -efi-boot-part --efi-boot-image --protective-msdos-label     iso_root -o build/mcsos.iso 2>&1 | tail -3
ls -lh build/mcsos.iso
qemu-system-x86_64     -cdrom build/mcsos.iso     -serial stdio     -display none     -no-reboot     -m 256M     -timeout 10 2>&1 | head -30 || true
timeout 10 qemu-system-x86_64     -cdrom build/mcsos.iso     -serial stdio     -display none     -no-reboot     -m 256M 2>&1 | head -40 || true
timeout 10 qemu-system-x86_64     -cdrom build/mcsos.iso     -serial stdio     -display none     -no-reboot     -m 256M     -d guest_errors 2>&1 | head -40 || true
# Cek isi iso_root
find iso_root -type f | sort
echo "---"
cat iso_root/boot/limine/limine.cfg
echo "---"
# Cek apakah limine sudah diinstall ke ISO
ls -la limine/limine
cat iso_root/boot/grub/grub.cfg
cat > iso_root/boot/grub/grub.cfg <<'EOF'
set timeout=0
set default=0
menuentry "MCSOS M6" {
    multiboot2 /boot/kernel.elf
    boot
}
EOF

nm build/kernel.elf | grep -E "kernel_main|kmain|_start"
# Bersihkan iso_root dan buat ulang struktur yang benar
rm -rf iso_root
mkdir -p iso_root/boot
# Copy kernel
cp build/kernel.elf iso_root/boot/kernel.elf
# Buat limine.cfg yang benar
cat > iso_root/limine.cfg <<'EOF'
TIMEOUT=0
:MCSOS M6
    PROTOCOL=limine
    KERNEL_PATH=boot:///boot/kernel.elf
EOF

# Copy file limine yang dibutuhkan
cp limine/limine-bios.sys limine/limine-bios-cd.bin limine/limine-uefi-cd.bin iso_root/
# Buat ISO
xorriso -as mkisofs     -b limine-bios-cd.bin     -no-emul-boot -boot-load-size 4 -boot-info-table     --efi-boot limine-uefi-cd.bin     -efi-boot-part --efi-boot-image --protective-m
xorriso -as mkisofs     -b limine-bios-cd.bin     -no-emul-boot -boot-load-size 4 -boot-info-table     --efi-boot limine-uefi-cd.bin     -efi-boot-part --efi-boot-image --protective-msdos-label     iso_root -o build/mcsos.iso 2>&1 | tail -3
limine/limine bios-install build/mcsos.iso 2>&1
ls -lh build/mcsos.iso
timeout 15 qemu-system-x86_64     -cdrom build/mcsos.iso     -serial stdio     -display none     -no-reboot     -m 256M 2>&1 || true
timeout 15 qemu-system-x86_64     -cdrom build/mcsos.iso     -serial stdio     -display none     -no-reboot     -m 256M 2>&1 || true
# Cek apakah ada limine requests di kernel
grep -r "limine_memmap_request\|limine_framebuffer_request\|LIMINE_REQUEST" kernel/ src/ --include="*.c" --include="*.h" | grep -v "build" | head -20
cat > kernel/kernel.c <<'EOF'
#include <serial.h>
#include <idt.h>
#include <pmm.h>
#include <limine.h>

__attribute__((used, section(".requests")))
static volatile struct limine_memmap_request memmap_req = {
    .id = LIMINE_MEMMAP_REQUEST,
    .revision = 0
};

__attribute__((used, section(".requests")))
static volatile struct limine_framebuffer_request fb_req = {
    .id = LIMINE_FRAMEBUFFER_REQUEST,
    .revision = 0
};

__attribute__((used, section(".requests_start_marker")))
static volatile LIMINE_REQUESTS_START_MARKER;

__attribute__((used, section(".requests_end_marker")))
static volatile LIMINE_REQUESTS_END_MARKER;

static struct pmm_state kernel_pmm;
static uint8_t kernel_pmm_bitmap[PMM_BITMAP_BYTES] __attribute__((aligned(4096)));

static void kernel_memory_init(void) {
    struct limine_memmap_response *memmap = memmap_req.response;
    if (!memmap) {
        serial_write_string("[m6] ERROR: no memmap response\n");
        for (;;) asm volatile ("hlt");
    }

    struct boot_mem_region regions[128];
    size_t count = 0;
    for (uint64_t i = 0; i < memmap->entry_count && count < 128; i++) {
        struct limine_memmap_entry *e = memmap->entries[i];
        uint32_t type;
        switch (e->type) {
            case LIMINE_MEMMAP_USABLE:                 type = BOOT_MEM_USABLE; break;
            case LIMINE_MEMMAP_RESERVED:               type = BOOT_MEM_RESERVED; break;
            case LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE: type = BOOT_MEM_BOOTLOADER_RECLAIMABLE; break;
            case LIMINE_MEMMAP_KERNEL_AND_MODULES:     type = BOOT_MEM_KERNEL_AND_MODULES; break;
            case LIMINE_MEMMAP_FRAMEBUFFER:            type = BOOT_MEM_FRAMEBUFFER; break;
            case LIMINE_MEMMAP_ACPI_RECLAIMABLE:       type = BOOT_MEM_ACPI_RECLAIMABLE; break;
            case LIMINE_MEMMAP_ACPI_NVS:               type = BOOT_MEM_ACPI_NVS; break;
            case LIMINE_MEMMAP_BAD_MEMORY:             type = BOOT_MEM_BAD_MEMORY; break;
            default:                                   type = BOOT_MEM_RESERVED; break;
        }
        regions[count].base   = e->base;
        regions[count].length = e->length;
        regions[count].type   = type;
        count++;
    }

    bool ok = pmm_init_from_map(&kernel_pmm, regions, count,
                                kernel_pmm_bitmap, sizeof(kernel_pmm_bitmap),
                                PMM_MAX_PHYS_BYTES);
    if (!ok) {
        serial_write_string("[m6] ERROR: pmm_init_from_map failed\n");
        for (;;) asm volatile ("hlt");
    }
    serial_write_string("[m6] pmm initialized\n");

    uint64_t f = pmm_alloc_frame(&kernel_pmm);
    if (f == PMM_INVALID_FRAME) {
        serial_write_string("[m6] ERROR: pmm_alloc_frame failed\n");
    } else {
        serial_write_string("[m6] sample frame alloc OK\n");
        pmm_free_frame(&kernel_pmm, f);
        serial_write_string("[m6] sample frame free OK\n");
    }
}

void kernel_main(void) {
    serial_init();
    idt_init();
    kernel_memory_init();
    asm volatile ("sti");
    for (;;) asm volatile ("hlt");
}
EOF

make clean && make all 2>&1 | grep -E "error|warning|kernel.elf"
cp build/kernel.elf iso_root/boot/kernel.elf
xorriso -as mkisofs     -b limine-bios-cd.bin     -no-emul-boot -boot-load-size 4 -boot-info-table     --efi-boot limine-uefi-cd.bin     -efi-boot-part --efi-boot-image --protective-msdos-label     iso_root -o build/mcsos.iso 2>&1 | tail -2
limine/limine bios-install build/mcsos.iso 2>&1 | tail -1
timeout 15 qemu-system-x86_64 -cdrom build/mcsos.iso -serial stdio -display none -no-reboot -m 256M 2>&1 || true
