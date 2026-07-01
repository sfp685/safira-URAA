
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
gdb build/kernel.elf
cd ~/mcsos
pwd
ls build/kernel.elf
cd ~/mcsos
gdb build/kernel.elf
ss -ltn | grep 1234
target remote :1234
cd ~/mcsos
gdb build/kernel.elf
cd ~/mcsos
mkdir -p artifacts/m15
{ uname -a; lsb_release -a 2>/dev/null || cat /etc/os-release; } | tee artifacts/m15/host_info.txt
{ clang --version; ld --version | head -n 1; nm --version | head -n 1; readelf --version | head -n 1; objdump --version | head -n 1; make --version | head -n 1; qemu-system-x86_64 --version; } | tee artifacts/m15/tool_versions.txt
ls artifacts/m15
mkdir -p scripts artifacts/m15
cat > scripts/m15_preflight.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts/m15
{
  echo "== git =="
  git status --short || true
  git rev-parse --short HEAD || true
  echo "== toolchain =="
  clang --version | head -n 1
  ld --version | head -n 1
  nm --version | head -n 1
  readelf --version | head -n 1
  objdump --version | head -n 1
  make --version | head -n 1
  echo "== prior artifacts =="
  for d in m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14; do
    if [ -d "artifacts/$d" ]; then
      echo "artifacts/$d: present"
    else
      echo "artifacts/$d: missing"
    fi
  done
} | tee artifacts/m15/preflight.txt
EOF

chmod +x scripts/m15_preflight.sh
./scripts/m15_preflight.sh
pwd
git rev-parse --show-toplevel
git branch -vv
git status
ls -la /home/user/.git
mkdir -p scripts artifacts/m15
cat > scripts/m15_preflight.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts/m15
{
  echo "== git =="
  git status --short || true
  git rev-parse --short HEAD || true
  echo "== toolchain =="
  clang --version | head -n 1
  ld --version | head -n 1
  nm --version | head -n 1
  readelf --version | head -n 1
  objdump --version | head -n 1
  make --version | head -n 1
  echo "== prior artifacts =="
  for d in m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14; do
    if [ -d "artifacts/$d" ]; then
      echo "artifacts/$d: present"
    else
      echo "artifacts/$d: missing"
    fi
  done
} | tee artifacts/m15/preflight.txt
EOF

chmod +x scripts/m15_preflight.sh
./scripts/m15_preflight.sh
mkdir -p scripts artifacts/m15
cat > scripts/m15_preflight.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts/m15
{
  echo "== git =="
  git status --short || true
  git rev-parse --short HEAD || true
  echo "== toolchain =="
  clang --version | head -n 1
  ld --version | head -n 1
  nm --version | head -n 1
  readelf --version | head -n 1
  objdump --version | head -n 1
  make --version | head -n 1
  echo "== prior artifacts =="
  for d in m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14; do
    if [ -d "artifacts/$d" ]; then
      echo "artifacts/$d: present"
    else
      echo "artifacts/$d: missing"
    fi
  done
} | tee artifacts/m15/preflight.txt
EOF

chmod +x scripts/m15_preflight.sh
./scripts/m15_preflight.sh
mkdir -p scripts artifacts/m15
cat > scripts/m15_preflight.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts/m15
{
  echo "== git =="
  git status --short || true
  git rev-parse --short HEAD || true
  echo "== toolchain =="
  clang --version | head -n 1
  ld --version | head -n 1
  nm --version | head -n 1
  readelf --version | head -n 1
  objdump --version | head -n 1
  make --version | head -n 1
  echo "== prior artifacts =="
  for d in m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14; do
    if [ -d "artifacts/$d" ]; then
      echo "artifacts/$d: present"
    else
      echo "artifacts/$d: missing"
    fi
  done
} | tee artifacts/m15/preflight.txt
EOF

chmod +x scripts/m15_preflight.sh
./scripts/m15_preflight.sh
git switch -c praktikum-m15-mcsfs1
git switch praktikum-m15-mcsfs1
mkdir -p fs/mcsfs1 tests/m15 artifacts/m15
git branch --show-current
ls -R fs tests artifacts
cat > fs/mcsfs1/mcsfs1.h <<'EOF'
#ifndef MCSFS1_H
#define MCSFS1_H

#include <stdint.h>
#include <stddef.h>

#define MCSFS1_BLOCK_SIZE 512u
#define MCSFS1_MAGIC 0x31465343u
#define MCSFS1_VERSION 1u
#define MCSFS1_MAX_INODES 32u
#define MCSFS1_DIRECT_BLOCKS 8u
#define MCSFS1_MAX_NAME 27u
#define MCSFS1_ROOT_INO 1u
#define MCSFS1_MODE_FREE 0u
#define MCSFS1_MODE_FILE 1u
#define MCSFS1_MODE_DIR 2u
#define MCSFS1_ERR_OK 0
#define MCSFS1_ERR_INVAL -1
#define MCSFS1_ERR_IO -2
#define MCSFS1_ERR_NOSPC -3
#define MCSFS1_ERR_EXIST -4
#define MCSFS1_ERR_NOENT -5
#define MCSFS1_ERR_NAMETOOLONG -6
#define MCSFS1_ERR_CORRUPT -7
#define MCSFS1_ERR_ISDIR -8
#define MCSFS1_ERR_RANGE -9

struct mcsfs1_blkdev {
    void *ctx;
    uint32_t block_count;
    int (*read)(void *ctx, uint32_t lba, void *buf512);
    int (*write)(void *ctx, uint32_t lba, const void *buf512);
    int (*flush)(void *ctx);
};

struct mcsfs1_mount {
    struct mcsfs1_blkdev *dev;
    uint32_t block_count;
    uint32_t data_start;
};

int mcsfs1_format(struct mcsfs1_blkdev *dev);
int mcsfs1_mount(struct mcsfs1_mount *mnt, struct mcsfs1_blkdev *dev);
int mcsfs1_fsck(struct mcsfs1_blkdev *dev);
int mcsfs1_create(struct mcsfs1_mount *mnt, const char *name);
int mcsfs1_write(struct mcsfs1_mount *mnt, const char *name, const uint8_t *buf, uint32_t len);
int mcsfs1_read(struct mcsfs1_mount *mnt, const char *name, uint8_t *buf, uint32_t cap, uint32_t *out_len);
int mcsfs1_unlink(struct mcsfs1_mount *mnt, const char *name);

#endif
EOF

ls fs/mcsfs1
cat fs/mcsfs1/mcsfs1.h
cat > fs/mcsfs1/mcsfs1.c <<'EOF'
#include "mcsfs1.h"

#define MCSFS1_SB_LBA 0u
#define MCSFS1_INODE_BMAP_LBA 1u
#define MCSFS1_BLOCK_BMAP_LBA 2u
#define MCSFS1_INODE_TABLE_LBA 3u
#define MCSFS1_INODE_TABLE_BLOCKS 4u
#define MCSFS1_ROOT_DIR_LBA 7u
#define MCSFS1_DATA_START_LBA 8u
#define MCSFS1_MIN_BLOCKS 16u
#define MCSFS1_DIRENT_COUNT 16u

struct mcsfs1_super_disk {
    uint32_t magic;
    uint32_t version;
    uint32_t block_size;
    uint32_t block_count;
    uint32_t inode_count;
    uint32_t inode_bmap_lba;
    uint32_t block_bmap_lba;
    uint32_t inode_table_lba;
    uint32_t inode_table_blocks;
    uint32_t root_ino;
    uint32_t root_dir_lba;
    uint32_t data_start_lba;
    uint32_t clean;
    uint32_t reserved[115];
};

struct mcsfs1_inode_disk {
    uint16_t mode;
    uint16_t links;
    uint32_t size;
    uint32_t direct[MCSFS1_DIRECT_BLOCKS];
    uint32_t reserved[5];
};

struct mcsfs1_dirent_disk {
    uint32_t ino;
    uint8_t type;
    char name[MCSFS1_MAX_NAME];
};

static void *mcsfs_memset(void *dst, int c, uint32_t n) {
    uint8_t *d = (uint8_t *)dst;
    for (uint32_t i = 0; i < n; i++) {
        d[i] = (uint8_t)c;
    }
    return dst;
}

static void *mcsfs_memcpy(void *dst, const void *src, uint32_t n) {
    uint8_t *d = (uint8_t *)dst;
    const uint8_t *s = (const uint8_t *)src;
    for (uint32_t i = 0; i < n; i++) {
        d[i] = s[i];
    }
    return dst;
}

static int mcsfs_memcmp(const void *a, const void *b, uint32_t n) {
    const uint8_t *x = (const uint8_t *)a;
    const uint8_t *y = (const uint8_t *)b;
    for (uint32_t i = 0; i < n; i++) {
        if (x[i] != y[i]) {
            return (int)x[i] - (int)y[i];
        }
    }
    return 0;
}

static uint32_t mcsfs_strlen_bound(const char *s, uint32_t max_plus_one) {
    uint32_t n = 0;
    if (s == 0) {
        return max_plus_one;
    }
    while (n < max_plus_one && s[n] != '\0') {
        n++;
    }
    return n;
}

static int valid_name(const char *name, uint32_t *len_out) {
    uint32_t n = mcsfs_strlen_bound(name, MCSFS1_MAX_NAME + 1u);
    if (n == 0u) {
        return MCSFS1_ERR_INVAL;
    }
    if (n > MCSFS1_MAX_NAME) {
        return MCSFS1_ERR_NAMETOOLONG;
    }
    for (uint32_t i = 0; i < n; i++) {
        if (name[i] == '/') {
            return MCSFS1_ERR_INVAL;
        }
    }
    *len_out = n;
    return MCSFS1_ERR_OK;
}

static int dev_read(struct mcsfs1_blkdev *dev, uint32_t lba, void *buf) {
    if (dev == 0 || dev->read == 0 || buf == 0 || lba >= dev->block_count) {
        return MCSFS1_ERR_INVAL;
    }
    return dev->read(dev->ctx, lba, buf) == 0 ? MCSFS1_ERR_OK : MCSFS1_ERR_IO;
}

static int dev_write(struct mcsfs1_blkdev *dev, uint32_t lba, const void *buf) {
    if (dev == 0 || dev->write == 0 || buf == 0 || lba >= dev->block_count) {
        return MCSFS1_ERR_INVAL;
    }
    return dev->write(dev->ctx, lba, buf) == 0 ? MCSFS1_ERR_OK : MCSFS1_ERR_IO;
}

static int dev_flush(struct mcsfs1_blkdev *dev) {
    if (dev == 0 || dev->flush == 0) {
        return MCSFS1_ERR_INVAL;
    }
    return dev->flush(dev->ctx) == 0 ? MCSFS1_ERR_OK : MCSFS1_ERR_IO;
}

static void bit_set(uint8_t *b, uint32_t bit) {
    b[bit / 8u] = (uint8_t)(b[bit / 8u] | (uint8_t)(1u << (bit % 8u)));
}

static void bit_clear(uint8_t *b, uint32_t bit) {
    b[bit / 8u] = (uint8_t)(b[bit / 8u] & (uint8_t)~(uint8_t)(1u << (bit % 8u)));
}

static int bit_test(const uint8_t *b, uint32_t bit) {
    return (b[bit / 8u] & (uint8_t)(1u << (bit % 8u))) != 0u;
}
EOF

cat >> fs/mcsfs1/mcsfs1.c <<'EOF'

static int load_super(struct mcsfs1_blkdev *dev, struct mcsfs1_super_disk *sb) {
    int rc = dev_read(dev, MCSFS1_SB_LBA, sb);
    if (rc != 0) {
        return rc;
    }
    if (sb->magic != MCSFS1_MAGIC || sb->version != MCSFS1_VERSION || sb->block_size != MCSFS1_BLOCK_SIZE) {
        return MCSFS1_ERR_CORRUPT;
    }
    if (sb->block_count != dev->block_count || sb->inode_count != MCSFS1_MAX_INODES) {
        return MCSFS1_ERR_CORRUPT;
    }
    if (sb->inode_bmap_lba != MCSFS1_INODE_BMAP_LBA || sb->block_bmap_lba != MCSFS1_BLOCK_BMAP_LBA || sb->inode_table_lba != MCSFS1_INODE_TABLE_LBA) {
        return MCSFS1_ERR_CORRUPT;
    }
    if (sb->root_ino != MCSFS1_ROOT_INO || sb->root_dir_lba != MCSFS1_ROOT_DIR_LBA || sb->data_start_lba != MCSFS1_DATA_START_LBA) {
        return MCSFS1_ERR_CORRUPT;
    }
    if (sb->data_start_lba >= sb->block_count) {
        return MCSFS1_ERR_CORRUPT;
    }
    return MCSFS1_ERR_OK;
}

static int read_inode(struct mcsfs1_blkdev *dev, uint32_t ino, struct mcsfs1_inode_disk *inode) {
    if (ino == 0u || ino > MCSFS1_MAX_INODES || inode == 0) {
        return MCSFS1_ERR_INVAL;
    }
    uint8_t block[MCSFS1_BLOCK_SIZE];
    uint32_t index = ino - 1u;
    uint32_t per_block = MCSFS1_BLOCK_SIZE / (uint32_t)sizeof(struct mcsfs1_inode_disk);
    uint32_t lba = MCSFS1_INODE_TABLE_LBA + (index / per_block);
    uint32_t off = (index % per_block) * (uint32_t)sizeof(struct mcsfs1_inode_disk);
    if (lba >= MCSFS1_DATA_START_LBA) {
        return MCSFS1_ERR_CORRUPT;
    }
    int rc = dev_read(dev, lba, block);
    if (rc != 0) {
        return rc;
    }
    mcsfs_memcpy(inode, block + off, (uint32_t)sizeof(*inode));
    return MCSFS1_ERR_OK;
}

static int write_inode(struct mcsfs1_blkdev *dev, uint32_t ino, const struct mcsfs1_inode_disk *inode) {
    if (ino == 0u || ino > MCSFS1_MAX_INODES || inode == 0) {
        return MCSFS1_ERR_INVAL;
    }
    uint8_t block[MCSFS1_BLOCK_SIZE];
    uint32_t index = ino - 1u;
    uint32_t per_block = MCSFS1_BLOCK_SIZE / (uint32_t)sizeof(struct mcsfs1_inode_disk);
    uint32_t lba = MCSFS1_INODE_TABLE_LBA + (index / per_block);
    uint32_t off = (index % per_block) * (uint32_t)sizeof(struct mcsfs1_inode_disk);
    if (lba >= MCSFS1_DATA_START_LBA) {
        return MCSFS1_ERR_CORRUPT;
    }
    int rc = dev_read(dev, lba, block);
    if (rc != 0) {
        return rc;
    }
    mcsfs_memcpy(block + off, inode, (uint32_t)sizeof(*inode));
    return dev_write(dev, lba, block);
}

static int load_bmaps(struct mcsfs1_blkdev *dev, uint8_t *ib, uint8_t *bb) {
    int rc = dev_read(dev, MCSFS1_INODE_BMAP_LBA, ib);
    if (rc != 0) {
        return rc;
    }
    return dev_read(dev, MCSFS1_BLOCK_BMAP_LBA, bb);
}

static int store_bmaps(struct mcsfs1_blkdev *dev, const uint8_t *ib, const uint8_t *bb) {
    int rc = dev_write(dev, MCSFS1_INODE_BMAP_LBA, ib);
    if (rc != 0) {
        return rc;
    }
    return dev_write(dev, MCSFS1_BLOCK_BMAP_LBA, bb);
}
EOF

cat >> fs/mcsfs1/mcsfs1.c <<'EOF'

static int find_dirent(struct mcsfs1_blkdev *dev, const char *name, uint32_t *slot_out, uint32_t *ino_out) {
    uint8_t block[MCSFS1_BLOCK_SIZE];
    uint32_t name_len = 0;
    int rc = valid_name(name, &name_len);
    if (rc != 0) {
        return rc;
    }
    rc = dev_read(dev, MCSFS1_ROOT_DIR_LBA, block);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_dirent_disk *de = (struct mcsfs1_dirent_disk *)block;
    for (uint32_t i = 0; i < MCSFS1_DIRENT_COUNT; i++) {
        if (de[i].ino != 0u && mcsfs_strlen_bound(de[i].name, MCSFS1_MAX_NAME + 1u) == name_len && mcsfs_memcmp(de[i].name, name, name_len) == 0) {
            if (slot_out != 0) {
                *slot_out = i;
            }
            if (ino_out != 0) {
                *ino_out = de[i].ino;
            }
            return MCSFS1_ERR_OK;
        }
    }
    return MCSFS1_ERR_NOENT;
}

static int alloc_inode_block(struct mcsfs1_blkdev *dev, uint32_t *ino_out, uint32_t *data_lba_out) {
    uint8_t ib[MCSFS1_BLOCK_SIZE];
    uint8_t bb[MCSFS1_BLOCK_SIZE];
    int rc = load_bmaps(dev, ib, bb);
    if (rc != 0) {
        return rc;
    }
    uint32_t ino = 0;
    for (uint32_t i = 2u; i <= MCSFS1_MAX_INODES; i++) {
        if (!bit_test(ib, i)) {
            ino = i;
            break;
        }
    }
    if (ino == 0u) {
        return MCSFS1_ERR_NOSPC;
    }
    uint32_t lba = 0;
    for (uint32_t b = MCSFS1_DATA_START_LBA; b < dev->block_count; b++) {
        if (!bit_test(bb, b)) {
            lba = b;
            break;
        }
    }
    if (lba == 0u) {
        return MCSFS1_ERR_NOSPC;
    }
    bit_set(ib, ino);
    bit_set(bb, lba);
    rc = store_bmaps(dev, ib, bb);
    if (rc != 0) {
        return rc;
    }
    *ino_out = ino;
    *data_lba_out = lba;
    return MCSFS1_ERR_OK;
}

static int alloc_data_block(struct mcsfs1_blkdev *dev, uint32_t *data_lba_out) {
    uint8_t ib[MCSFS1_BLOCK_SIZE];
    uint8_t bb[MCSFS1_BLOCK_SIZE];
    int rc = load_bmaps(dev, ib, bb);
    if (rc != 0) {
        return rc;
    }
    for (uint32_t b = MCSFS1_DATA_START_LBA; b < dev->block_count; b++) {
        if (!bit_test(bb, b)) {
            bit_set(bb, b);
            rc = store_bmaps(dev, ib, bb);
            if (rc != 0) {
                return rc;
            }
            *data_lba_out = b;
            return MCSFS1_ERR_OK;
        }
    }
    return MCSFS1_ERR_NOSPC;
}

static int free_inode_and_blocks(struct mcsfs1_blkdev *dev, uint32_t ino, const struct mcsfs1_inode_disk *inode) {
    uint8_t ib[MCSFS1_BLOCK_SIZE];
    uint8_t bb[MCSFS1_BLOCK_SIZE];
    int rc = load_bmaps(dev, ib, bb);
    if (rc != 0) {
        return rc;
    }
    bit_clear(ib, ino);
    for (uint32_t i = 0; i < MCSFS1_DIRECT_BLOCKS; i++) {
        if (inode->direct[i] != 0u && inode->direct[i] < dev->block_count) {
            bit_clear(bb, inode->direct[i]);
        }
    }
    return store_bmaps(dev, ib, bb);
}
EOF

cat >> fs/mcsfs1/mcsfs1.c <<'EOF'

int mcsfs1_format(struct mcsfs1_blkdev *dev) {
    if (dev == 0 || dev->block_count < MCSFS1_MIN_BLOCKS || dev->block_count > (MCSFS1_BLOCK_SIZE * 8u)) {
        return MCSFS1_ERR_INVAL;
    }
    uint8_t zero[MCSFS1_BLOCK_SIZE];
    mcsfs_memset(zero, 0, MCSFS1_BLOCK_SIZE);
    for (uint32_t lba = 0; lba < dev->block_count; lba++) {
        int rc0 = dev_write(dev, lba, zero);
        if (rc0 != 0) {
            return rc0;
        }
    }

    struct mcsfs1_super_disk sb;
    mcsfs_memset(&sb, 0, (uint32_t)sizeof(sb));
    sb.magic = MCSFS1_MAGIC;
    sb.version = MCSFS1_VERSION;
    sb.block_size = MCSFS1_BLOCK_SIZE;
    sb.block_count = dev->block_count;
    sb.inode_count = MCSFS1_MAX_INODES;
    sb.inode_bmap_lba = MCSFS1_INODE_BMAP_LBA;
    sb.block_bmap_lba = MCSFS1_BLOCK_BMAP_LBA;
    sb.inode_table_lba = MCSFS1_INODE_TABLE_LBA;
    sb.inode_table_blocks = MCSFS1_INODE_TABLE_BLOCKS;
    sb.root_ino = MCSFS1_ROOT_INO;
    sb.root_dir_lba = MCSFS1_ROOT_DIR_LBA;
    sb.data_start_lba = MCSFS1_DATA_START_LBA;
    sb.clean = 1u;
    int rc = dev_write(dev, MCSFS1_SB_LBA, &sb);
    if (rc != 0) {
        return rc;
    }

    uint8_t ib[MCSFS1_BLOCK_SIZE];
    uint8_t bb[MCSFS1_BLOCK_SIZE];
    mcsfs_memset(ib, 0, MCSFS1_BLOCK_SIZE);
    mcsfs_memset(bb, 0, MCSFS1_BLOCK_SIZE);
    bit_set(ib, 0u);
    bit_set(ib, MCSFS1_ROOT_INO);
    for (uint32_t b = 0; b < MCSFS1_DATA_START_LBA; b++) {
        bit_set(bb, b);
    }
    bit_set(bb, MCSFS1_ROOT_DIR_LBA);
    rc = store_bmaps(dev, ib, bb);
    if (rc != 0) {
        return rc;
    }

    struct mcsfs1_inode_disk root;
    mcsfs_memset(&root, 0, (uint32_t)sizeof(root));
    root.mode = MCSFS1_MODE_DIR;
    root.links = 1u;
    root.size = MCSFS1_BLOCK_SIZE;
    root.direct[0] = MCSFS1_ROOT_DIR_LBA;
    rc = write_inode(dev, MCSFS1_ROOT_INO, &root);
    if (rc != 0) {
        return rc;
    }
    return dev_flush(dev);
}

int mcsfs1_mount(struct mcsfs1_mount *mnt, struct mcsfs1_blkdev *dev) {
    if (mnt == 0 || dev == 0) {
        return MCSFS1_ERR_INVAL;
    }
    struct mcsfs1_super_disk sb;
    int rc = load_super(dev, &sb);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_inode_disk root;
    rc = read_inode(dev, MCSFS1_ROOT_INO, &root);
    if (rc != 0) {
        return rc;
    }
    if (root.mode != MCSFS1_MODE_DIR || root.direct[0] != MCSFS1_ROOT_DIR_LBA) {
        return MCSFS1_ERR_CORRUPT;
    }
    mnt->dev = dev;
    mnt->block_count = sb.block_count;
    mnt->data_start = sb.data_start_lba;
    return MCSFS1_ERR_OK;
}

int mcsfs1_create(struct mcsfs1_mount *mnt, const char *name) {
    if (mnt == 0 || mnt->dev == 0) {
        return MCSFS1_ERR_INVAL;
    }
    uint32_t name_len = 0;
    int rc = valid_name(name, &name_len);
    if (rc != 0) {
        return rc;
    }
    if (find_dirent(mnt->dev, name, 0, 0) == 0) {
        return MCSFS1_ERR_EXIST;
    }
    uint8_t dir_block[MCSFS1_BLOCK_SIZE];
    rc = dev_read(mnt->dev, MCSFS1_ROOT_DIR_LBA, dir_block);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_dirent_disk *de = (struct mcsfs1_dirent_disk *)dir_block;
    uint32_t free_slot = MCSFS1_DIRENT_COUNT;
    for (uint32_t i = 0; i < MCSFS1_DIRENT_COUNT; i++) {
        if (de[i].ino == 0u) {
            free_slot = i;
            break;
        }
    }
    if (free_slot == MCSFS1_DIRENT_COUNT) {
        return MCSFS1_ERR_NOSPC;
    }
    uint32_t ino = 0;
    uint32_t first_data = 0;
    rc = alloc_inode_block(mnt->dev, &ino, &first_data);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_inode_disk inode;
    mcsfs_memset(&inode, 0, (uint32_t)sizeof(inode));
    inode.mode = MCSFS1_MODE_FILE;
    inode.links = 1u;
    inode.size = 0u;
    inode.direct[0] = first_data;
    rc = write_inode(mnt->dev, ino, &inode);
    if (rc != 0) {
        return rc;
    }
    de[free_slot].ino = ino;
    de[free_slot].type = MCSFS1_MODE_FILE;
    mcsfs_memset(de[free_slot].name, 0, MCSFS1_MAX_NAME);
    mcsfs_memcpy(de[free_slot].name, name, name_len);
    rc = dev_write(mnt->dev, MCSFS1_ROOT_DIR_LBA, dir_block);
    if (rc != 0) {
        return rc;
    }
    return dev_flush(mnt->dev);
}

int mcsfs1_write(struct mcsfs1_mount *mnt, const char *name, const uint8_t *buf, uint32_t len) {
    if (mnt == 0 || mnt->dev == 0 || (buf == 0 && len != 0u)) {
        return MCSFS1_ERR_INVAL;
    }
    if (len > MCSFS1_DIRECT_BLOCKS * MCSFS1_BLOCK_SIZE) {
        return MCSFS1_ERR_RANGE;
    }
    uint32_t ino = 0;
    int rc = find_dirent(mnt->dev, name, 0, &ino);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_inode_disk inode;
    rc = read_inode(mnt->dev, ino, &inode);
    if (rc != 0) {
        return rc;
    }
    if (inode.mode != MCSFS1_MODE_FILE) {
        return MCSFS1_ERR_ISDIR;
    }
    uint32_t blocks_needed = (len + MCSFS1_BLOCK_SIZE - 1u) / MCSFS1_BLOCK_SIZE;
    if (blocks_needed == 0u) {
        blocks_needed = 1u;
    }
    for (uint32_t i = 0; i < blocks_needed; i++) {
        if (inode.direct[i] == 0u) {
            rc = alloc_data_block(mnt->dev, &inode.direct[i]);
            if (rc != 0) {
                return rc;
            }
        }
    }
    uint8_t block[MCSFS1_BLOCK_SIZE];
    uint32_t written = 0;
    for (uint32_t i = 0; i < blocks_needed; i++) {
        mcsfs_memset(block, 0, MCSFS1_BLOCK_SIZE);
        uint32_t remain = len - written;
        uint32_t chunk = remain > MCSFS1_BLOCK_SIZE ? MCSFS1_BLOCK_SIZE : remain;
        if (chunk != 0u) {
            mcsfs_memcpy(block, buf + written, chunk);
        }
        rc = dev_write(mnt->dev, inode.direct[i], block);
        if (rc != 0) {
            return rc;
        }
        written += chunk;
    }
    inode.size = len;
    rc = write_inode(mnt->dev, ino, &inode);
    if (rc != 0) {
        return rc;
    }
    return dev_flush(mnt->dev);
}
EOF

cat >> fs/mcsfs1/mcsfs1.c <<'EOF'

int mcsfs1_read(struct mcsfs1_mount *mnt, const char *name, uint8_t *buf, uint32_t cap, uint32_t *out_len) {
    if (mnt == 0 || mnt->dev == 0 || buf == 0 || out_len == 0) {
        return MCSFS1_ERR_INVAL;
    }
    uint32_t ino = 0;
    int rc = find_dirent(mnt->dev, name, 0, &ino);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_inode_disk inode;
    rc = read_inode(mnt->dev, ino, &inode);
    if (rc != 0) {
        return rc;
    }
    if (inode.mode != MCSFS1_MODE_FILE) {
        return MCSFS1_ERR_ISDIR;
    }
    if (cap < inode.size) {
        return MCSFS1_ERR_RANGE;
    }
    uint32_t blocks_needed = (inode.size + MCSFS1_BLOCK_SIZE - 1u) / MCSFS1_BLOCK_SIZE;
    uint32_t copied = 0;
    uint8_t block[MCSFS1_BLOCK_SIZE];
    for (uint32_t i = 0; i < blocks_needed; i++) {
        if (inode.direct[i] == 0u || inode.direct[i] >= mnt->block_count) {
            return MCSFS1_ERR_CORRUPT;
        }
        rc = dev_read(mnt->dev, inode.direct[i], block);
        if (rc != 0) {
            return rc;
        }
        uint32_t remain = inode.size - copied;
        uint32_t chunk = remain > MCSFS1_BLOCK_SIZE ? MCSFS1_BLOCK_SIZE : remain;
        mcsfs_memcpy(buf + copied, block, chunk);
        copied += chunk;
    }
    *out_len = inode.size;
    return MCSFS1_ERR_OK;
}

int mcsfs1_unlink(struct mcsfs1_mount *mnt, const char *name) {
    if (mnt == 0 || mnt->dev == 0) {
        return MCSFS1_ERR_INVAL;
    }
    uint32_t slot = 0;
    uint32_t ino = 0;
    int rc = find_dirent(mnt->dev, name, &slot, &ino);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_inode_disk inode;
    rc = read_inode(mnt->dev, ino, &inode);
    if (rc != 0) {
        return rc;
    }
    if (inode.mode != MCSFS1_MODE_FILE) {
        return MCSFS1_ERR_ISDIR;
    }
    uint8_t dir_block[MCSFS1_BLOCK_SIZE];
    rc = dev_read(mnt->dev, MCSFS1_ROOT_DIR_LBA, dir_block);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_dirent_disk *de = (struct mcsfs1_dirent_disk *)dir_block;
    mcsfs_memset(&de[slot], 0, (uint32_t)sizeof(de[slot]));
    rc = dev_write(mnt->dev, MCSFS1_ROOT_DIR_LBA, dir_block);
    if (rc != 0) {
        return rc;
    }
    rc = free_inode_and_blocks(mnt->dev, ino, &inode);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_inode_disk zero_inode;
    mcsfs_memset(&zero_inode, 0, (uint32_t)sizeof(zero_inode));
    rc = write_inode(mnt->dev, ino, &zero_inode);
    if (rc != 0) {
        return rc;
    }
    return dev_flush(mnt->dev);
}

int mcsfs1_fsck(struct mcsfs1_blkdev *dev) {
    if (dev == 0) {
        return MCSFS1_ERR_INVAL;
    }
    struct mcsfs1_super_disk sb;
    int rc = load_super(dev, &sb);
    if (rc != 0) {
        return rc;
    }
    uint8_t ib[MCSFS1_BLOCK_SIZE];
    uint8_t bb[MCSFS1_BLOCK_SIZE];
    rc = load_bmaps(dev, ib, bb);
    if (rc != 0) {
        return rc;
    }
    if (!bit_test(ib, MCSFS1_ROOT_INO) || !bit_test(bb, MCSFS1_ROOT_DIR_LBA)) {
        return MCSFS1_ERR_CORRUPT;
    }
    for (uint32_t b = 0; b < MCSFS1_DATA_START_LBA; b++) {
        if (!bit_test(bb, b)) {
            return MCSFS1_ERR_CORRUPT;
        }
    }
    struct mcsfs1_inode_disk root;
    rc = read_inode(dev, MCSFS1_ROOT_INO, &root);
    if (rc != 0) {
        return rc;
    }
    if (root.mode != MCSFS1_MODE_DIR || root.direct[0] != MCSFS1_ROOT_DIR_LBA) {
        return MCSFS1_ERR_CORRUPT;
    }
    uint8_t dir_block[MCSFS1_BLOCK_SIZE];
    rc = dev_read(dev, MCSFS1_ROOT_DIR_LBA, dir_block);
    if (rc != 0) {
        return rc;
    }
    struct mcsfs1_dirent_disk *de = (struct mcsfs1_dirent_disk *)dir_block;
    for (uint32_t i = 0; i < MCSFS1_DIRENT_COUNT; i++) {
        if (de[i].ino == 0u) {
            continue;
        }
        if (de[i].ino > MCSFS1_MAX_INODES || de[i].type != MCSFS1_MODE_FILE || !bit_test(ib, de[i].ino)) {
            return MCSFS1_ERR_CORRUPT;
        }
        struct mcsfs1_inode_disk inode;
        rc = read_inode(dev, de[i].ino, &inode);
        if (rc != 0) {
            return rc;
        }
        if (inode.mode != MCSFS1_MODE_FILE || inode.size > MCSFS1_DIRECT_BLOCKS * MCSFS1_BLOCK_SIZE) {
            return MCSFS1_ERR_CORRUPT;
        }
        uint32_t needed = (inode.size + MCSFS1_BLOCK_SIZE - 1u) / MCSFS1_BLOCK_SIZE;
        if (needed == 0u) {
            needed = 1u;
        }
        for (uint32_t j = 0; j < needed; j++) {
            uint32_t lba = inode.direct[j];
            if (lba < MCSFS1_DATA_START_LBA || lba >= dev->block_count || !bit_test(bb, lba)) {
                return MCSFS1_ERR_CORRUPT;
            }
        }
    }
    return MCSFS1_ERR_OK;
}
EOF

wc -l fs/mcsfs1/mcsfs1.c
tail -5 fs/mcsfs1/mcsfs1.c
cat > tests/m15/test_mcsfs1.c <<'EOF'
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "../../fs/mcsfs1/mcsfs1.h"

#define RAMBLK_BLOCKS 128u
static uint8_t disk[RAMBLK_BLOCKS][MCSFS1_BLOCK_SIZE];
static unsigned flush_count;

static int ram_read(void *ctx, uint32_t lba, void *buf512) {
    (void)ctx;
    if (lba >= RAMBLK_BLOCKS) return -1;
    memcpy(buf512, disk[lba], MCSFS1_BLOCK_SIZE);
    return 0;
}

static int ram_write(void *ctx, uint32_t lba, const void *buf512) {
    (void)ctx;
    if (lba >= RAMBLK_BLOCKS) return -1;
    memcpy(disk[lba], buf512, MCSFS1_BLOCK_SIZE);
    return 0;
}

static int ram_flush(void *ctx) {
    (void)ctx;
    flush_count++;
    return 0;
}

static int expect_int(const char *label, int got, int want) {
    if (got != want) {
        printf("FAIL %s got=%d want=%d\n", label, got, want);
        return 1;
    }
    return 0;
}

int main(void) {
    struct mcsfs1_blkdev dev = {0};
    struct mcsfs1_mount mnt = {0};
    uint8_t out[4096];
    uint32_t out_len = 0;
    int fails = 0;

    dev.block_count = RAMBLK_BLOCKS;
    dev.read = ram_read;
    dev.write = ram_write;
    dev.flush = ram_flush;

    fails += expect_int("format", mcsfs1_format(&dev), MCSFS1_ERR_OK);
    fails += expect_int("mount", mcsfs1_mount(&mnt, &dev), MCSFS1_ERR_OK);
    fails += expect_int("fsck-empty", mcsfs1_fsck(&dev), MCSFS1_ERR_OK);
    fails += expect_int("create-alpha", mcsfs1_create(&mnt, "alpha.txt"), MCSFS1_ERR_OK);
    fails += expect_int("create-duplicate", mcsfs1_create(&mnt, "alpha.txt"), MCSFS1_ERR_EXIST);

    const char msg[] = "MCSOS M15 persistent file payload";
    fails += expect_int("write-alpha", mcsfs1_write(&mnt, "alpha.txt", (const uint8_t *)msg, (uint32_t)strlen(msg)), MCSFS1_ERR_OK);
    memset(out, 0, sizeof(out));
    fails += expect_int("read-alpha", mcsfs1_read(&mnt, "alpha.txt", out, sizeof(out), &out_len), MCSFS1_ERR_OK);
    if (out_len != strlen(msg) || memcmp(out, msg, strlen(msg)) != 0) {
        printf("FAIL read-data len=%u\n", out_len);
        fails++;
    }

    uint8_t big[1400];
    for (unsigned i = 0; i < sizeof(big); i++) big[i] = (uint8_t)(i & 0xffu);
    fails += expect_int("write-big", mcsfs1_write(&mnt, "alpha.txt", big, sizeof(big)), MCSFS1_ERR_OK);
    memset(out, 0, sizeof(out));
    fails += expect_int("read-big", mcsfs1_read(&mnt, "alpha.txt", out, sizeof(out), &out_len), MCSFS1_ERR_OK);
    if (out_len != sizeof(big) || memcmp(out, big, sizeof(big)) != 0) {
        printf("FAIL read-big-data len=%u\n", out_len);
        fails++;
    }

    fails += expect_int("read-small-cap", mcsfs1_read(&mnt, "alpha.txt", out, 8, &out_len), MCSFS1_ERR_RANGE);
    fails += expect_int("missing", mcsfs1_read(&mnt, "missing", out, sizeof(out), &out_len), MCSFS1_ERR_NOENT);
    fails += expect_int("fsck-populated", mcsfs1_fsck(&dev), MCSFS1_ERR_OK);
    fails += expect_int("unlink", mcsfs1_unlink(&mnt, "alpha.txt"), MCSFS1_ERR_OK);
    fails += expect_int("read-after-unlink", mcsfs1_read(&mnt, "alpha.txt", out, sizeof(out), &out_len), MCSFS1_ERR_NOENT);
    fails += expect_int("fsck-after-unlink", mcsfs1_fsck(&dev), MCSFS1_ERR_OK);

    disk[0][0] ^= 0x55u;
    fails += expect_int("corrupt-super", mcsfs1_fsck(&dev), MCSFS1_ERR_CORRUPT);

    if (flush_count == 0) {
        printf("FAIL flush-count zero\n");
        fails++;
    }

    if (fails != 0) {
        printf("M15 host test failed: %d failures\n", fails);
        return 1;
    }
    printf("M15 host test passed: flush_count=%u\n", flush_count);
    return 0;
}

EOF

ls tests/m15
wc -l tests/m15/test_mcsfs1.c
head -50 Makefile
tail -80 Makefile
find . -maxdepth 3 -name "Makefile"
find . -iname "makefile"
head -50 makefile
tail -80 makefile
head -50 makefile
tail -80 makefile
cp Makefile Makefile.bak
cd ~/mcsos
ls -la
ls -la | grep -i makefile
find . -iname "makefile" 2>/dev/null
cp makefile makefile.bak
cp makefile.m14 makefile.m14.bak
cd ~/mcsos
cat makefile
cat makefile.m14
cd ~/mcsos
cp makefile makefile.bak
nano makefile
make -n m15-all
find fs -iname "mcsfs1*"
find tests -iname "*mcsfs1*"
make m15-all
make clean
make CC=clang m15-all
cat kmain.c
ls -la /usr/share/OVMF/ 2>/dev/null || echo "OVMF tidak ada"
git log --oneline -10 2>/dev/null || echo "belum git repo"
git tag 2>/dev/null
cat fs/mcsfs1/mcsfs1.h
cat include/mcsos/block.h
cat kernel/block/ramblk.c
cat kernel/block/block_demo.c
nano kernel/block/block_demo.c
nano fs/mcsfs1/mcsfs1_blkdev_adapter.c
nano fs/mcsfs1/mcsfs1_blkdev_adapter.h
nano kmain.c
nano makefile
make -n m15-smoke
make m15-smoke
grep -n "m15-smoke" makefile
tail -20 makefile
nano makefile
grep -n "m15-smoke" makefile
make -n m15-smoke
make m15-smoke
ls artifacts/m15
cat artifacts/m15/qemu_serial.log
qemu-system-x86_64   -machine q35   -m 256M   -serial stdio   -display none   -s -S   -cdrom build/mcsos.iso
make m15-smoke
cd ~/mcsos
ls build/kernel.elf
qemu-system-x86_64   -machine q35   -m 256M   -serial stdio   -display none   -s -S   -cdrom build/mcsos.iso
grep -n "int mcsfs1_create" -A20 fs/mcsfs1/mcsfs1.c
grep -n "int mcsfs1_write" -A20 fs/mcsfs1/mcsfs1.c
grep -n "int mcsfs1_fsck" -A40 fs/mcsfs1/mcsfs1.c
cat tests/m15/test_mcsfs1.c
tail -40 tests/m15/test_mcsfs1.c
nl -ba tests/m15/test_mcsfs1.c | tail -60
cd~/mcsos
xxd build/kernel.elf | grep -A1 "ad b0"
cd ~/mcsos
xxd build/kernel.elf | grep -A1 "ad b0"
python3 -c "
data = open('build/kernel.elf','rb').read()
idx = data.find(b'\x02\xb0\xad\x1b')
print('magic found at offset:', idx)
"
readelf -S build/kernel.elf | grep -A1 multiboot
sed -i 's/^\.section \.multiboot$/.section .multiboot, "a"/' src/kernel/arch/x86_64/boot.s
head -5 src/kernel/arch/x86_64/boot.s
make clean
make all
readelf -S build/kernel.elf | grep -A1 multiboot
readelf -l build/kernel.elf
make iso
timeout 8 qemu-system-x86_64 -machine q35 -m 256M -nographic -cdrom build/mcsos.iso < /dev/null > artifacts/m14/qemu_m14.log 2>&1
cat artifacts/m14/qemu_m14.log
cat artifacts/m14/qemu_m14.log 
ls build
ls artifacts/m14
cat artifacts/m14/qemu_m14.log
cd ~/mcsos
qemu-system-x86_64   -machine q35   -m 256M   -serial stdio   -no-reboot   -no-shutdown   -S -s   -cdrom build/mcsos.iso
mkdir -p artifacts/m14
timeout 8 qemu-system-x86_64 -machine q35 -m 256M -nographic -cdrom build/mcsos.iso < /dev/null > artifacts/m14/qemu_m14.log 2>&1
cat artifacts/m14/qemu_m14.log
grep -n "700\|power" tests/host/test_m14_block.c
git add include/mcsos/block.h kernel/block/block.c kernel/block/bcache.c tests/host/test_m14_block.c artifacts/m14/qemu_m14.log
git commit -m "M14 pengayaan: stats, write-through, negative test"
git status
git add -A kernel/block/ include/mcsos/block.h tests/host/test_m14_block.c artifacts/m14/qemu_m14.log
git commit -m "M14 pengayaan lengkap: stats, write-through, negative test"
git log --oneline -3
git add -A kernel/block/ include/mcsos/block.h tests/host/test_m14_block.c artifacts/m14/qemu_m14.log
git commit -m "M14 pengayaan lengkap: stats, write-through, negative test"
git log --oneline -3                                                                                                                                                                                  
git rm --cached artifacts/m14/gdb_m14_session.txt artifacts/m14/kernel_build.log artifacts/m14/m14_make_all.log artifacts/m14/m14_nm_undefined.txt artifacts/m14/m14_objdump.txt artifacts/m14/m14_readelf.txt artifacts/m14/m14_sha256.txt artifacts/m14/qemu_debug.log
git commit -m "cleanup: remove stale M14 log artifacts"
mkdir -p artifacts/m14
./scripts/m14_preflight.sh
make -f makefile.m14 clean || true
make -f makefile.m14 all 2>&1 | tee artifacts/m14/m14_make_all.log
cat artifacts/m14_nm_undefined.txt
head -n 30 artifacts/m14_readelf_block.txt
grep -E "Class:|Machine:|Type:" artifacts/m14_readelf_block.txt
sha256sum build/m14_block_layer.o build/test_m14_block | tee artifacts/m14_final_sha256.txt
git status --short | tee artifacts/m14_git_status_after_m14.txt
mkdir -p artifacts/m14
make -f makefile.m14 all 2>&1 | tee artifacts/m14/m14_make_all.log
git add artifacts/m14_nm_undefined.txt artifacts/m14_readelf_block.txt artifacts/m14_final_sha256.txt artifacts/m14_git_status_after_m14.txt artifacts/m14/m14_make_all.log
git commit -m "M14: full grading test artifacts (preflight, audit, sha256)"
git add -f artifacts/m14_nm_undefined.txt artifacts/m14_readelf_block.txt
git commit -m "M14: include nm/readelf audit artifacts (force-add, ignored by gitignore rule)"
git check-ignore -v artifacts/m14_nm_undefined.txt
git log --oneline -5
git status --short
mkdir -p artifacts/m14
timeout 8 qemu-system-x86_64 -machine q35 -m 256M -nographic -cdrom build/mcsos.iso < /dev/null > artifacts/m14/qemu_m14.log 2>&1
cat artifacts/m14/qemu_m14.log
git add artifacts/m14/qemu_m14.log
git commit -m "M14: restore final qemu boot log"
mkdir -p artifacts/m14
timeout 8 qemu-system-x86_64 -machine q35 -m 256M -nographic -cdrom build/mcsos.iso < /dev/null > artifacts/m14/qemu_m14.log 2>&1
cat artifacts/m14/qemu_m14.log
git add artifacts/m14/qemu_m14.log
git commit -m "M14: restore final qemu boot log"
mkdir -p artifacts/m14
timeout 8 qemu-system-x86_64 -machine q35 -m 256M -nographic -cdrom build/mcsos.iso < /dev/null > artifacts/m14/qemu_m14.log 2>&1
cat artifacts/m14/qemu_m14.log
git add artifacts/m14/qemu_m14.log
git commit -m "M14: restore final qemu boot log"
ls -lh artifacts/m14/qemu_m14.log
cat artifacts/m14/qemu_m14.log
ls -lh build
ls -lh build/*.iso
cat artifacts/m14/m14_nm_undefined.txt
./build/test_m14_block
mkdir -p artifacts/m14
nm -u build/m14_block_layer.o > artifacts/m14/m14_nm_undefined.txt
cat artifacts/m14/m14_nm_undefined.txt
readelf -h build/m14_block_layer.o > artifacts/m14/m14_readelf_block.txt
head -30 artifacts/m14/m14_readelf_block.txt
grep -E "Class:|Machine:|Type:" artifacts/m14/m14_readelf_block.txt
sha256sum build/m14_block_layer.o build/test_m14_block | tee artifacts/m14/m14_final_sha256.txt
git status --short | tee artifacts/m14/git_status_after_m14.txt
ls -lh artifacts/m14
git add artifacts/m14
git commit -m "M14: add final grading artifacts"
cd ~/mcsos
ls -lh artifacts/m14/m14_objdump_block.txt
head -20 artifacts/m14/m14_objdump_block.txt
cd ~/mcsos
ls -lh artifacts/m14
head -20 artifacts/m14/m14_objdump_block.txt
cd ~/mcsos
objdump -dr build/m14_block_layer.o | tee artifacts/m14/m14_objdump_block.txt
git add artifacts/m14/m14_objdump_block.txt
git commit -m "M14: add objdump artifact"
git log --oneline -3
cd ~/mcsos
make clean
make all
make iso
mkdir -p artifacts/m14
timeout 8 qemu-system-x86_64 -machine q35 -m 256M -nographic -cdrom build/mcsos.iso < /dev/null > artifacts/m14/qemu_m14.log 2>&1
cat artifacts/m14/qemu_m14.log
git log --oneline --all | grep -i "M14"
git show eabdc1b:mcsos/artifacts/m14/qemu_m14.log 2>/dev/null || git show eabdc1b:artifacts/m14/qemu_m14.log 2>/dev/null
cd ~/mcsos
git status
cat artifacts/m14/qemu_m14.log
git restore ../.bash_history
rm -f linker.ld.backup_m14
rm -f linker.ld.bak
rm -f makefile.backup_m14
rm -f makefile.bak
rm -f src/kernel/arch/x86_64/boot.s.bak
git status
cat artifacts/m14/qemu_m14.log
git add artifacts/m14/qemu_m14.log
git commit -m "M14: update final QEMU smoke test log"
git status
git remote -v
git push -u origin praktikum-m14-block-device
git branch -vv
git log --oneline -5
git tag m14-final
git push origin m14-final
cd ~/mcsos
gdb build/m9/kernel_m9.elf
cd ~/mcsos
gdb build/m9/kernel_m9.elf
make m9-gdb
file build/m9/kernel_m9.elf
readelf -S build/m9/kernel_m9.elf | grep -i debug
grep -n 'ld.lld\|LDFLAGS' Makefile | head -10
grep -n 'm9-gdb' -A 5 Makefile
grep -n 'idt_src.o\|kmain.o' Makefile
grep -n 'KERNEL_CFLAGS' Makefile | head -5
sed -n '61,63p' Makefile
sed -n '64p' Makefile
file build/m9/kernel_m9.elf
readelf -S build/m9/kernel_m9.elf | grep -i debug
cd ~/mcsos
gdb build/m9/kernel_m9.elf   -ex "set architecture i386:x86-64"   -ex "target remote localhost:1234"
cd ~/mcsos
ls Makefile
cd ~/mcsos
pkill -f qemu-system-x86_64
make m9-qemu-debug
grep -R "mcs_sys_open" -n .
grep -R "fd_table" -n kernel include
grep -R "kernel_ramfs" -n .
grep -n "g_fs" kernel/kmain.c
git status --short
git diff -- include/mcs_vfs.h kernel/vfs tests Makefile.m13 > build/m13/m13-rollback-diff.patch
ls -l build/m13/m13-rollback-diff.patch
clang --version
ld --version
objdump --version
readelf --version
nm --version
qemu-system-x86_64 --version
gdb --version
git rev-parse HEAD
make -f Makefile.m13 clean
make -f Makefile.m13 m13-all
sha256sum build/m13/* > build/m13/ci-artifacts.sha256
cat build/m13/ci-artifacts.sha256
ls -l build/m13
git status
git add Makefile
git add Makefile.m13
git add kernel/kmain.c
git add include/mcs_vfs.h
git add kernel/vfs
git add tests/m13_vfs_host_test.c
git status
git commit -m "M13: Implement VFS, RAMFS, FD table and host tests"
git remote -v
git push -u origin praktikum-m13-vfs-ramfs
git status
git checkout praktikum-m13-vfs-ramfs
git status
git checkout -b praktikum-m14
cd ~/mcsos
gdb build/m9/kernel_m9.elf
