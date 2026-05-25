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
