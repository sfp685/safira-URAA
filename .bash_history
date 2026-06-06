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
cat > src/vmm.c << 'ENDOFFILE'
#include "vmm.h"

static void vmm_zero_page(uint64_t *page) {
    for (size_t i = 0; i < VMM_ENTRIES_PER_TABLE; i++) {
        page[i] = 0;
    }
}

bool vmm_is_aligned_4k(uint64_t value) {
    return (value & (VMM_PAGE_SIZE - 1ULL)) == 0;
}

bool vmm_is_canonical(uint64_t vaddr) {
    uint64_t sign = (vaddr >> 47) & 1ULL;
    uint64_t upper = vaddr >> 48;
    return sign ? (upper == 0xFFFFULL) : (upper == 0ULL);
}

static unsigned idx_pml4(uint64_t vaddr) { return (unsigned)((vaddr >> 39) & 0x1FFULL); }
static unsigned idx_pdpt(uint64_t vaddr) { return (unsigned)((vaddr >> 30) & 0x1FFULL); }
static unsigned idx_pd(uint64_t vaddr)   { return (unsigned)((vaddr >> 21) & 0x1FFULL); }
static unsigned idx_pt(uint64_t vaddr)   { return (unsigned)((vaddr >> 12) & 0x1FFULL); }

static uint64_t *table_from_phys(struct vmm_space *space, uint64_t paddr) {
    if (space == 0 || space->phys_to_virt == 0 || !vmm_is_aligned_4k(paddr)) return 0;
    return (uint64_t *)space->phys_to_virt(space->ctx, paddr);
}

static int get_or_alloc_next_table(struct vmm_space *space, uint64_t *table,
                                   unsigned index, uint64_t **out) {
    uint64_t entry = table[index];
    if ((entry & VMM_PTE_PRESENT) != 0) {
        if ((entry & VMM_PTE_HUGE) != 0) return VMM_ERR_EXISTS;
        uint64_t next_paddr = entry & VMM_PTE_ADDR_MASK;
        uint64_t *next = table_from_phys(space, next_paddr);
        if (next == 0) return VMM_ERR_INVAL;
        *out = next;
        return VMM_MAP_OK;
    }
    if (space->alloc_frame == 0) return VMM_ERR_NOMEM;
    uint64_t new_paddr = space->alloc_frame(space->ctx);
    if (new_paddr == VMM_INVALID_PHYS || !vmm_is_aligned_4k(new_paddr)) return VMM_ERR_NOMEM;
    uint64_t *new_table = table_from_phys(space, new_paddr);
    if (new_table == 0) {
        if (space->free_frame != 0) space->free_frame(space->ctx, new_paddr);
        return VMM_ERR_INVAL;
    }
    vmm_zero_page(new_table);
    table[index] = (new_paddr & VMM_PTE_ADDR_MASK) | VMM_PTE_PRESENT | VMM_PTE_WRITABLE;
    *out = new_table;
    return VMM_MAP_OK;
}

int vmm_space_init(struct vmm_space *space, uint64_t root_paddr, void *ctx,
                   vmm_alloc_frame_fn alloc_frame, vmm_free_frame_fn free_frame,
                   vmm_phys_to_virt_fn phys_to_virt) {
    if (space == 0 || phys_to_virt == 0 || !vmm_is_aligned_4k(root_paddr)) return VMM_ERR_INVAL;
    space->root_paddr  = root_paddr;
    space->ctx         = ctx;
    space->alloc_frame = alloc_frame;
    space->free_frame  = free_frame;
    space->phys_to_virt = phys_to_virt;
    return VMM_MAP_OK;
}

int vmm_map_page(struct vmm_space *space, uint64_t vaddr, uint64_t paddr, uint64_t flags) {
    if (space == 0 || !vmm_is_canonical(vaddr) ||
        !vmm_is_aligned_4k(vaddr) || !vmm_is_aligned_4k(paddr))
        return VMM_ERR_INVAL;
    uint64_t *pml4 = table_from_phys(space, space->root_paddr);
    if (pml4 == 0) return VMM_ERR_INVAL;
    uint64_t *pdpt = 0, *pd = 0, *pt = 0;
    int rc;
    rc = get_or_alloc_next_table(space, pml4, idx_pml4(vaddr), &pdpt); if (rc != VMM_MAP_OK) return rc;
    rc = get_or_alloc_next_table(space, pdpt, idx_pdpt(vaddr), &pd);   if (rc != VMM_MAP_OK) return rc;
    rc = get_or_alloc_next_table(space, pd,   idx_pd(vaddr),   &pt);   if (rc != VMM_MAP_OK) return rc;
    unsigned pti = idx_pt(vaddr);
    if ((pt[pti] & VMM_PTE_PRESENT) != 0) return VMM_ERR_EXISTS;
    uint64_t allowed = VMM_PTE_WRITABLE | VMM_PTE_USER | VMM_PTE_WRITE_THROUGH |
                       VMM_PTE_CACHE_DISABLE | VMM_PTE_GLOBAL | VMM_PTE_NO_EXECUTE;
    pt[pti] = (paddr & VMM_PTE_ADDR_MASK) | VMM_PTE_PRESENT | (flags & allowed);
    return VMM_MAP_OK;
}

int vmm_query_page(struct vmm_space *space, uint64_t vaddr, struct vmm_mapping *out) {
    if (space == 0 || out == 0 || !vmm_is_canonical(vaddr) || !vmm_is_aligned_4k(vaddr))
        return VMM_ERR_INVAL;
    uint64_t *pml4 = table_from_phys(space, space->root_paddr);
    if (pml4 == 0) return VMM_ERR_INVAL;
    uint64_t e = pml4[idx_pml4(vaddr)];
    if ((e & VMM_PTE_PRESENT) == 0 || (e & VMM_PTE_HUGE) != 0) return VMM_ERR_NOT_FOUND;
    uint64_t *pdpt = table_from_phys(space, e & VMM_PTE_ADDR_MASK);
    if (pdpt == 0) return VMM_ERR_INVAL;
    e = pdpt[idx_pdpt(vaddr)];
    if ((e & VMM_PTE_PRESENT) == 0 || (e & VMM_PTE_HUGE) != 0) return VMM_ERR_NOT_FOUND;
    uint64_t *pd = table_from_phys(space, e & VMM_PTE_ADDR_MASK);
    if (pd == 0) return VMM_ERR_INVAL;
    e = pd[idx_pd(vaddr)];
    if ((e & VMM_PTE_PRESENT) == 0 || (e & VMM_PTE_HUGE) != 0) return VMM_ERR_NOT_FOUND;
    uint64_t *pt = table_from_phys(space, e & VMM_PTE_ADDR_MASK);
    if (pt == 0) return VMM_ERR_INVAL;
    e = pt[idx_pt(vaddr)];
    if ((e & VMM_PTE_PRESENT) == 0) return VMM_ERR_NOT_FOUND;
    out->vaddr = vaddr;
    out->paddr = e & VMM_PTE_ADDR_MASK;
    out->flags = e & ~VMM_PTE_ADDR_MASK;
    return VMM_MAP_OK;
}

int vmm_unmap_page(struct vmm_space *space, uint64_t vaddr) {
    if (space == 0 || !vmm_is_canonical(vaddr) || !vmm_is_aligned_4k(vaddr))
        return VMM_ERR_INVAL;
    uint64_t *pml4 = table_from_phys(space, space->root_paddr);
    if (pml4 == 0) return VMM_ERR_INVAL;
    uint64_t e = pml4[idx_pml4(vaddr)];
    if ((e & VMM_PTE_PRESENT) == 0 || (e & VMM_PTE_HUGE) != 0) return VMM_ERR_NOT_FOUND;
    uint64_t *pdpt = table_from_phys(space, e & VMM_PTE_ADDR_MASK);
    if (pdpt == 0) return VMM_ERR_INVAL;
    e = pdpt[idx_pdpt(vaddr)];
    if ((e & VMM_PTE_PRESENT) == 0 || (e & VMM_PTE_HUGE) != 0) return VMM_ERR_NOT_FOUND;
    uint64_t *pd = table_from_phys(space, e & VMM_PTE_ADDR_MASK);
    if (pd == 0) return VMM_ERR_INVAL;
    e = pd[idx_pd(vaddr)];
    if ((e & VMM_PTE_PRESENT) == 0 || (e & VMM_PTE_HUGE) != 0) return VMM_ERR_NOT_FOUND;
    uint64_t *pt = table_from_phys(space, e & VMM_PTE_ADDR_MASK);
    if (pt == 0) return VMM_ERR_INVAL;
    unsigned pti = idx_pt(vaddr);
    if ((pt[pti] & VMM_PTE_PRESENT) == 0) return VMM_ERR_NOT_FOUND;
    pt[pti] = 0;
    vmm_invalidate_page(vaddr);
    return VMM_MAP_OK;
}

#if defined(__x86_64__) && !defined(MCSOS_HOST_TEST)
void vmm_invalidate_page(uint64_t vaddr) {
    __asm__ volatile("invlpg (%0)" :: "r"((void *)vaddr) : "memory");
}
uint64_t vmm_read_cr3(void) {
    uint64_t v;
    __asm__ volatile("mov %%cr3, %0" : "=r"(v) :: "memory");
    return v;
}
void vmm_write_cr3(uint64_t value) {
    __asm__ volatile("mov %0, %%cr3" :: "r"(value) : "memory");
}
uint64_t vmm_read_cr2(void) {
    uint64_t v;
    __asm__ volatile("mov %%cr2, %0" : "=r"(v) :: "memory");
    return v;
}
#else
void vmm_invalidate_page(uint64_t vaddr) { (void)vaddr; }
uint64_t vmm_read_cr3(void) { return 0; }
void vmm_write_cr3(uint64_t value) { (void)value; }
uint64_t vmm_read_cr2(void) { return 0; }
#endif
ENDOFFILE

cat > src/vmm.c << 'ENDOFFILE'
#include "vmm.h"

static void vmm_zero_page(uint64_t *page) {
    for (size_t i = 0; i < VMM_ENTRIES_PER_TABLE; i++) {
        page[i] = 0;
    }
}

bool vmm_is_aligned_4k(uint64_t value) {
    return (value & (VMM_PAGE_SIZE - 1ULL)) == 0;
}

bool vmm_is_canonical(uint64_t vaddr) {
    uint64_t sign = (vaddr >> 47) & 1ULL;
    uint64_t upper = vaddr >> 48;
    return sign ? (upper == 0xFFFFULL) : (upper == 0ULL);
}

static unsigned idx_pml4(uint64_t vaddr) { return (unsigned)((vaddr >> 39) & 0x1FFULL); }
static unsigned idx_pdpt(uint64_t vaddr) { return (unsigned)((vaddr >> 30) & 0x1FFULL); }
static unsigned idx_pd(uint64_t vaddr)   { return (unsigned)((vaddr >> 21) & 0x1FFULL); }
static unsigned idx_pt(uint64_t vaddr)   { return (unsigned)((vaddr >> 12) & 0x1FFULL); }

static uint64_t *table_from_phys(struct vmm_space *space, uint64_t paddr) {
    if (space == 0 || space->phys_to_virt == 0 || !vmm_is_aligned_4k(paddr)) return 0;
    return (uint64_t *)space->phys_to_virt(space->ctx, paddr);
}

static int get_or_alloc_next_table(struct vmm_space *space, uint64_t *table,
                                   unsigned index, uint64_t **out) {
    uint64_t entry = table[index];
    if ((entry & VMM_PTE_PRESENT) != 0) {
        if ((entry & VMM_PTE_HUGE) != 0) return VMM_ERR_EXISTS;
        uint64_t next_paddr = entry & VMM_PTE_ADDR_MASK;
        uint64_t *next = table_from_phys(space, next_paddr);
        if (next == 0) return VMM_ERR_INVAL;
        *out = next;
        return VMM_MAP_OK;
    }
    if (space->alloc_frame == 0) return VMM_ERR_NOMEM;
    uint64_t new_paddr = space->alloc_frame(space->ctx);
    if (new_paddr == VMM_INVALID_PHYS || !vmm_is_aligned_4k(new_paddr)) return VMM_ERR_NOMEM;
    uint64_t *new_table = table_from_phys(space, new_paddr);
    if (new_table == 0) {
        if (space->free_frame != 0) space->free_frame(space->ctx, new_paddr);
        return VMM_ERR_INVAL;
    }
    vmm_zero_page(new_table);
    table[index] = (new_paddr & VMM_PTE_ADDR_MASK) | VMM_PTE_PRESENT | VMM_PTE_WRITABLE;
    *out = new_table;
    return VMM_MAP_OK;
}

int vmm_space_init(struct vmm_space *space, uint64_t root_paddr, void *ctx,
                   vmm_alloc_frame_fn alloc_frame, vmm_free_frame_fn free_frame,
                   vmm_phys_to_virt_fn phys_to_virt) {
    if (space == 0 || phys_to_virt == 0 || !vmm_is_aligned_4k(root_paddr)) return VMM_ERR_INVAL;
    space->root_paddr  = root_paddr;
    space->ctx         = ctx;
    space->alloc_frame = alloc_frame;
    space->free_frame  = free_frame;
    space->phys_to_virt = phys_to_virt;
    return VMM_MAP_OK;
}

int vmm_map_page(struct vmm_space *space, uint64_t vaddr, uint64_t paddr, uint64_t flags) {
    if (space == 0 || !vmm_is_canonical(vaddr) ||
        !vmm_is_aligned_4k(vaddr) || !vmm_is_aligned_4k(paddr))
        return VMM_ERR_INVAL;
    uint64_t *pml4 = table_from_phys(space, space->root_paddr);
    if (pml4 == 0) return VMM_ERR_INVAL;
    uint64_t *pdpt = 0, *pd = 0, *pt = 0;
    int rc;
    rc = get_or_alloc_next_table(space, pml4, idx_pml4(vaddr), &pdpt); if (rc != VMM_MAP_OK) return rc;
    rc = get_or_alloc_next_table(space, pdpt, idx_pdpt(vaddr), &pd);   if (rc != VMM_MAP_OK) return rc;
    rc = get_or_alloc_next_table(space, pd,   idx_pd(vaddr),   &pt);   if (rc != VMM_MAP_OK) return rc;
    unsigned pti = idx_pt(vaddr);
    if ((pt[pti] & VMM_PTE_PRESENT) != 0) return VMM_ERR_EXISTS;
    uint64_t allowed = VMM_PTE_WRITABLE | VMM_PTE_USER | VMM_PTE_WRITE_THROUGH |
                       VMM_PTE_CACHE_DISABLE | VMM_PTE_GLOBAL | VMM_PTE_NO_EXECUTE;
    pt[pti] = (paddr & VMM_PTE_ADDR_MASK) | VMM_PTE_PRESENT | (flags & allowed);
    return VMM_MAP_OK;
}

int vmm_query_page(struct vmm_space *space, uint64_t vaddr, struct vmm_mapping *out) {
    if (space == 0 || out == 0 || !vmm_is_canonical(vaddr) || !vmm_is_aligned_4k(vaddr))
        return VMM_ERR_INVAL;
    uint64_t *pml4 = table_from_phys(space, space->root_paddr);
    if (pml4 == 0) return VMM_ERR_INVAL;
    uint64_t e = pml4[idx_pml4(vaddr)];
    if ((e & VMM_PTE_PRESENT) == 0 || (e & VMM_PTE_HUGE) != 0) return VMM_ERR_NOT_FOUND;
    uint64_t *pdpt = table_from_phys(space, e & VMM_PTE_ADDR_MASK);
    if (pdpt == 0) return VMM_ERR_INVAL;
    e = pdpt[idx_pdpt(vaddr)];
    if ((e & VMM_PTE_PRESENT) == 0 || (e & VMM_PTE_HUGE) != 0) return VMM_ERR_NOT_FOUND;
    uint64_t *pd = table_from_phys(space, e & VMM_PTE_ADDR_MASK);
    if (pd == 0) return VMM_ERR_INVAL;
    e = pd[idx_pd(vaddr)];
    if ((e & VMM_PTE_PRESENT) == 0 || (e & VMM_PTE_HUGE) != 0) return VMM_ERR_NOT_FOUND;
    uint64_t *pt = table_from_phys(space, e & VMM_PTE_ADDR_MASK);
    if (pt == 0) return VMM_ERR_INVAL;
    e = pt[idx_pt(vaddr)];
    if ((e & VMM_PTE_PRESENT) == 0) return VMM_ERR_NOT_FOUND;
    out->vaddr = vaddr;
    out->paddr = e & VMM_PTE_ADDR_MASK;
    out->flags = e & ~VMM_PTE_ADDR_MASK;
    return VMM_MAP_OK;
}

int vmm_unmap_page(struct vmm_space *space, uint64_t vaddr) {
    if (space == 0 || !vmm_is_canonical(vaddr) || !vmm_is_aligned_4k(vaddr))
        return VMM_ERR_INVAL;
    uint64_t *pml4 = table_from_phys(space, space->root_paddr);
    if (pml4 == 0) return VMM_ERR_INVAL;
    uint64_t e = pml4[idx_pml4(vaddr)];
    if ((e & VMM_PTE_PRESENT) == 0 || (e & VMM_PTE_HUGE) != 0) return VMM_ERR_NOT_FOUND;
    uint64_t *pdpt = table_from_phys(space, e & VMM_PTE_ADDR_MASK);
    if (pdpt == 0) return VMM_ERR_INVAL;
    e = pdpt[idx_pdpt(vaddr)];
    if ((e & VMM_PTE_PRESENT) == 0 || (e & VMM_PTE_HUGE) != 0) return VMM_ERR_NOT_FOUND;
    uint64_t *pd = table_from_phys(space, e & VMM_PTE_ADDR_MASK);
    if (pd == 0) return VMM_ERR_INVAL;
    e = pd[idx_pd(vaddr)];
    if ((e & VMM_PTE_PRESENT) == 0 || (e & VMM_PTE_HUGE) != 0) return VMM_ERR_NOT_FOUND;
    uint64_t *pt = table_from_phys(space, e & VMM_PTE_ADDR_MASK);
    if (pt == 0) return VMM_ERR_INVAL;
    unsigned pti = idx_pt(vaddr);
    if ((pt[pti] & VMM_PTE_PRESENT) == 0) return VMM_ERR_NOT_FOUND;
    pt[pti] = 0;
    vmm_invalidate_page(vaddr);
    return VMM_MAP_OK;
}

#if defined(__x86_64__) && !defined(MCSOS_HOST_TEST)
void vmm_invalidate_page(uint64_t vaddr) {
    __asm__ volatile("invlpg (%0)" :: "r"((void *)vaddr) : "memory");
}
uint64_t vmm_read_cr3(void) {
    uint64_t v;
    __asm__ volatile("mov %%cr3, %0" : "=r"(v) :: "memory");
    return v;
}
void vmm_write_cr3(uint64_t value) {
    __asm__ volatile("mov %0, %%cr3" :: "r"(value) : "memory");
}
uint64_t vmm_read_cr2(void) {
    uint64_t v;
    __asm__ volatile("mov %%cr2, %0" : "=r"(v) :: "memory");
    return v;
}
#else
void vmm_invalidate_page(uint64_t vaddr) { (void)vaddr; }
uint64_t vmm_read_cr3(void) { return 0; }
void vmm_write_cr3(uint64_t value) { (void)value; }
uint64_t vmm_read_cr2(void) { return 0; }
#endif
ENDOFFILE

wc -l src/vmm.c
tail -10 src/vmm.c
make clean && make check
./scripts/grade_m7.sh
git add include/vmm.h src/vmm.c tests/test_vmm_host.c Makefile scripts/
git commit -m "m7-vmm-core: Virtual Memory Manager awal, page table 4-level, host unit test"
git checkout -b praktikum/m7-vmm
git push origin praktikum/m7-vmm
git ls-files | grep -i ssh
git ls-files | grep "\.ssh"
git rm --cached .ssh/id_ed25519
git rm --cached .ssh/id_ed25519.pub 2>/dev/null || true
git rm --cached .ssh/id_ed25519
git rm --cached .ssh/id_ed25519.pub 2>/dev/null || true
echo ".ssh/" >> .gitignore
git add .gitignore
git commit --amend --no-edit
git push origin praktikum/m7-vmm --force
ssh-keygen -t ed25519 -C "email_kamu@example.com"
# lalu daftarkan public key baru di GitHub Settings → SSH Keys
ssh-keygen -t ed25519 -C "email@gmail.com" -f ~/.ssh/id_ed25519 -N ""
git rm --cached .ssh/id_ed25519
git rm --cached .ssh/id_ed25519.pub 2>/dev/null || true
echo ".ssh/" >> .gitignore
git add .gitignore
git commit --amend --no-edit
git push origin praktikum/m7-vmm --force
git filter-branch --force --index-filter   "git rm --cached --ignore-unmatch .ssh/id_ed25519 .ssh/id_ed25519.pub"   --prune-empty --tag-name-filter cat -- --all
git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push origin praktikum/m7-vmm --force
git log --oneline | head -20
git show c481ec840b3901a01f4de0c199bb762ec08f3051 --name-only | head -20
git log --oneline
git rebase -i 3a880c9
pick c481ec8 M6: implement PMM with bitmap allocator
pick 4ebd60f M6: add .gitignore, remove build artifacts from tracking
pick 5609694 m7-vmm-core: ...
edit c481ec8 M6: implement PMM with bitmap allocator
pick 4ebd60f M6: add .gitignore, remove build artifacts from tracking
pick 5609694 m7-vmm-core: ...
git rm --cached --ignore-unmatch .ssh/id_ed25519 .ssh/id_ed25519.pub
echo ".ssh/" >> .gitignore
git add .gitignore
git commit --amend --no-edit
git rebase --continue
git push origin praktikum/m7-vmm --force
git stash
GIT_EDITOR=nano git rebase -i 3a880c9
git rebase --abort
git rebase -i 3a880c9 --exec "true"
GIT_SEQUENCE_EDITOR="sed -i 's/pick c481ec8/edit c481ec8/'" git rebase -i 3a880c9
git rm --cached --ignore-unmatch .ssh/id_ed25519 .ssh/id_ed25519.pub
git commit --amend --no-edit
git rebase --continue
git push origin praktikum/m7-vmm --force
ssh-keyscan github.com >> ~/.ssh/known_hosts
cat ~/.ssh/id_ed25519.pub
ssh -T git@github.com
git push origin praktikum/m7-vmm --force
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
ssh -T git@github.com
git push origin praktikum/m7-vmm --force
git status --short
make m6-all || true
make m7-all || true
cat Makefile
find . -maxdepth 4 -type f | grep -v ".git" | sort
make check
cat makefile
./build/test_vmm_host
nm -u build/vmm.o
[200~git switch -c praktikum-m8-kernel-heap
mkdir -p include/mcsos kernel/mm tests scripts build/m8~
cat > include/mcsos/kmem.h << 'EOF'
#ifndef MCSOS_KMEM_H
#define MCSOS_KMEM_H

#include <stddef.h>
#include <stdint.h>

#define KMEM_ALIGN 16u
#define KMEM_MAGIC 0x4d43534f53484541ull

typedef struct kmem_stats {
    size_t total_bytes;
    size_t used_bytes;
    size_t free_bytes;
    size_t block_count;
    size_t free_count;
    size_t largest_free;
} kmem_stats_t;

int   kmem_init(void *base, size_t bytes);
void *kmem_alloc(size_t bytes);
void *kmem_calloc(size_t count, size_t bytes);
int   kmem_free_checked(void *ptr);
void  kmem_get_stats(kmem_stats_t *out);
int   kmem_validate(void);

#endif /* MCSOS_KMEM_H */
EOF

cat > kernel/mm/kmem.c << 'EOF'
#include "mcsos/kmem.h"

#define KMEM_MIN_SPLIT 32u

typedef struct kmem_block {
    uint64_t magic;
    size_t   size;
    int      free;
    struct kmem_block *prev;
    struct kmem_block *next;
} kmem_block_t;

static unsigned char  *g_heap_base  = (unsigned char *)0;
static unsigned char  *g_heap_end   = (unsigned char *)0;
static kmem_block_t   *g_head       = (kmem_block_t *)0;
static int             g_initialized = 0;

static void *kmem_memset(void *dst, int val, size_t n) {
    unsigned char *p = (unsigned char *)dst;
    while (n--) *p++ = (unsigned char)val;
    return dst;
}

static uintptr_t kmem_align_up_ptr(uintptr_t v, size_t align) {
    return (v + (uintptr_t)(align - 1u)) & ~(uintptr_t)(align - 1u);
}

static size_t kmem_align_up_size(size_t v, size_t align) {
    return (v + (align - 1u)) & ~(align - 1u);
}

static unsigned char *kmem_payload(kmem_block_t *b) {
    return (unsigned char *)b + sizeof(kmem_block_t);
}

static kmem_block_t *kmem_header_from_payload(void *ptr) {
    return (kmem_block_t *)((unsigned char *)ptr - sizeof(kmem_block_t));
}

static int kmem_ptr_in_heap(void *ptr) {
    return (unsigned char *)ptr >= g_heap_base &&
           (unsigned char *)ptr <  g_heap_end;
}

static void kmem_split_if_useful(kmem_block_t *block, size_t wanted) {
    uintptr_t new_addr = kmem_align_up_ptr(
        (uintptr_t)(kmem_payload(block) + wanted), KMEM_ALIGN);
    if (new_addr + sizeof(kmem_block_t) >= (uintptr_t)g_heap_end) return;
    const size_t consumed = (size_t)(new_addr - (uintptr_t)kmem_payload(block));
    if (block->size <= consumed + sizeof(kmem_block_t) + KMEM_MIN_SPLIT) return;
    kmem_block_t *nb = (kmem_block_t *)new_addr;
    nb->magic = KMEM_MAGIC;
    nb->size  = block->size - consumed - sizeof(kmem_block_t);
    nb->free  = 1;
    nb->prev  = block;
    nb->next  = block->next;
    if (block->next) block->next->prev = nb;
EOF

cat > kernel/mm/kmem.c << 'EOF'
#include "mcsos/kmem.h"

#define KMEM_MIN_SPLIT 32u

typedef struct kmem_block {
    uint64_t magic;
    size_t   size;
    int      free;
    struct kmem_block *prev;
    struct kmem_block *next;
} kmem_block_t;

static unsigned char  *g_heap_base  = (unsigned char *)0;
static unsigned char  *g_heap_end   = (unsigned char *)0;
static kmem_block_t   *g_head       = (kmem_block_t *)0;
static int             g_initialized = 0;

static void *kmem_memset(void *dst, int val, size_t n) {
    unsigned char *p = (unsigned char *)dst;
    while (n--) *p++ = (unsigned char)val;
    return dst;
}

static uintptr_t kmem_align_up_ptr(uintptr_t v, size_t align) {
    return (v + (uintptr_t)(align - 1u)) & ~(uintptr_t)(align - 1u);
}

static size_t kmem_align_up_size(size_t v, size_t align) {
    return (v + (align - 1u)) & ~(align - 1u);
}

static unsigned char *kmem_payload(kmem_block_t *b) {
    return (unsigned char *)b + sizeof(kmem_block_t);
}

static kmem_block_t *kmem_header_from_payload(void *ptr) {
    return (kmem_block_t *)((unsigned char *)ptr - sizeof(kmem_block_t));
}

static int kmem_ptr_in_heap(void *ptr) {
    return (unsigned char *)ptr >= g_heap_base &&
           (unsigned char *)ptr <  g_heap_end;
}

static void kmem_split_if_useful(kmem_block_t *block, size_t wanted) {
    uintptr_t new_addr = kmem_align_up_ptr(
        (uintptr_t)(kmem_payload(block) + wanted), KMEM_ALIGN);
    if (new_addr + sizeof(kmem_block_t) >= (uintptr_t)g_heap_end) return;
    const size_t consumed = (size_t)(new_addr - (uintptr_t)kmem_payload(block));
    if (block->size <= consumed + sizeof(kmem_block_t) + KMEM_MIN_SPLIT) return;
    kmem_block_t *nb = (kmem_block_t *)new_addr;
    nb->magic = KMEM_MAGIC;
    nb->size  = block->size - consumed - sizeof(kmem_block_t);
    nb->free  = 1;
    nb->prev  = block;
    nb->next  = block->next;
    if (block->next) block->next->prev = nb;
    block->next = nb;
    block->size = wanted;
}

static void kmem_coalesce_forward(kmem_block_t *block) {
    while (block && block->next && block->next->free) {
        kmem_block_t *next = block->next;
        unsigned char *expected = (unsigned char *)kmem_align_up_ptr(
            (uintptr_t)(kmem_payload(block) + block->size), KMEM_ALIGN);
        if (expected != (unsigned char *)next) return;
        block->size += sizeof(kmem_block_t) + next->size;
        block->next  = next->next;
        if (next->next) next->next->prev = block;
        next->magic = 0u;
        next->size  = 0u;
        next->prev  = (kmem_block_t *)0;
        next->next  = (kmem_block_t *)0;
    }
}

int kmem_init(void *base, size_t bytes) {
    if (!base || bytes < sizeof(kmem_block_t) + KMEM_MIN_SPLIT) return -1;
    uintptr_t start = kmem_align_up_ptr((uintptr_t)base, KMEM_ALIGN);
    if (!start || start < (uintptr_t)base) return -2;
    const size_t lost = (size_t)(start - (uintptr_t)base);
    if (bytes <= lost + sizeof(kmem_block_t) + KMEM_MIN_SPLIT) return -3;
    size_t usable = (bytes - lost) & ~(size_t)(KMEM_ALIGN - 1u);
    if (usable <= sizeof(kmem_block_t) + KMEM_MIN_SPLIT) return -4;
    g_heap_base = (unsigned char *)start;
    g_heap_end  = g_heap_base + usable;
    g_head = (kmem_block_t *)g_heap_base;
    g_head->magic = KMEM_MAGIC;
    g_head->size  = usable - sizeof(kmem_block_t);
    g_head->free  = 1;
    g_head->prev  = (kmem_block_t *)0;
    g_head->next  = (kmem_block_t *)0;
    g_initialized = 1;
    return kmem_validate();
}

void *kmem_alloc(size_t bytes) {
    if (!g_initialized || !bytes) return (void *)0;
    const size_t wanted = kmem_align_up_size(bytes, KMEM_ALIGN);
    if (!wanted) return (void *)0;
    for (kmem_block_t *cur = g_head; cur; cur = cur->next) {
        if (cur->magic != KMEM_MAGIC) return (void *)0;
        if (cur->free && cur->size >= wanted) {
            kmem_split_if_useful(cur, wanted);
            cur->free = 0;
            return (void *)kmem_payload(cur);
        }
    }
    return (void *)0;
}

void *kmem_calloc(size_t count, size_t bytes) {
    if (count && bytes > (size_t)-1 / count) return (void *)0;
    const size_t total = count * bytes;
    void *ptr = kmem_alloc(total);
    if (ptr) kmem_memset(ptr, 0, total);
    return ptr;
}

int kmem_free_checked(void *ptr) {
    if (!ptr) return 0;
    if (!kmem_ptr_in_heap(ptr)) return -1;
    if ((uintptr_t)ptr & (KMEM_ALIGN - 1u)) return -2;
    kmem_block_t *block = kmem_header_from_payload(ptr);
    if (!kmem_ptr_in_heap(block) || block->magic != KMEM_MAGIC) return -3;
    if (block->free) return -4;
    block->free = 1;
    kmem_coalesce_forward(block);
    if (block->prev && block->prev->free) kmem_coalesce_forward(block->prev);
    return kmem_validate();
}

void kmem_get_stats(kmem_stats_t *out) {
    if (!out) return;
    kmem_memset(out, 0, sizeof(*out));
    if (!g_initialized) return;
    out->total_bytes = (size_t)(g_heap_end - g_heap_base);
    for (kmem_block_t *cur = g_head; cur; cur = cur->next) {
        out->block_count++;
        if (cur->free) {
            out->free_count++;
            out->free_bytes += cur->size;
            if (cur->size > out->largest_free) out->largest_free = cur->size;
        } else {
            out->used_bytes += cur->size;
        }
    }
}

int kmem_validate(void) {
    if (!g_initialized || !g_heap_base || g_heap_end <= g_heap_base || !g_head) return -1;
    if ((unsigned char *)g_head != g_heap_base) return -2;
    kmem_block_t  *prev   = (kmem_block_t *)0;
EOF

# Host unit test
clang -std=c17 -Wall -Wextra -Werror -Iinclude   tests/test_kmem.c kernel/mm/kmem.c -o build/m8/test_kmem
./build/m8/test_kmem | tee build/m8/test_kmem.log
# Freestanding audit
clang -std=c17 -Wall -Wextra -Werror -ffreestanding -fno-builtin   -Iinclude -c kernel/mm/kmem.c -o build/m8/kmem.freestanding.o
nm -u build/m8/kmem.freestanding.o | tee build/m8/nm_u.txt
readelf -h build/m8/kmem.freestanding.o
mkdir -p include/mcsos kernel/mm tests scripts build/m8
cat kernel/mm/kmem.c
cat >> kernel/mm/kmem.c << 'EOF'
    unsigned char *cursor = g_heap_base;
    size_t guard = 0u;
    for (kmem_block_t *cur = g_head; cur; cur = cur->next) {
        if (++guard > 1048576u) return -3;
        if ((unsigned char *)cur != cursor) return -4;
        if ((unsigned char *)cur < g_heap_base ||
            (unsigned char *)cur + sizeof(kmem_block_t) > g_heap_end) return -5;
        if (cur->magic != KMEM_MAGIC) return -6;
        if (cur->prev != prev) return -7;
        if (cur->size > (size_t)(g_heap_end - kmem_payload(cur))) return -8;
        cursor = (unsigned char *)kmem_align_up_ptr(
            (uintptr_t)(kmem_payload(cur) + cur->size), KMEM_ALIGN);
        if (!cursor || cursor > g_heap_end) return -9;
        prev = cur;
    }
    return 0;
}
EOF

tail -20 kernel/mm/kmem.c
cat > tests/test_kmem.c << 'EOF'
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "mcsos/kmem.h"

static unsigned char arena[4096u * 8u];

static void test_basic_alloc_free(void) {
    assert(kmem_init(arena, sizeof(arena)) == 0);
    void *a = kmem_alloc(24);
    void *b = kmem_alloc(128);
    void *c = kmem_alloc(4096);
    assert(a && b && c);
    assert(((uintptr_t)a & (KMEM_ALIGN-1u)) == 0u);
    assert(((uintptr_t)b & (KMEM_ALIGN-1u)) == 0u);
    assert(((uintptr_t)c & (KMEM_ALIGN-1u)) == 0u);
    memset(a, 0x11, 24); memset(b, 0x22, 128); memset(c, 0x33, 4096);
    assert(kmem_validate() == 0);
    assert(kmem_free_checked(b) == 0);
    assert(kmem_free_checked(a) == 0);
    assert(kmem_free_checked(c) == 0);
    assert(kmem_validate() == 0);
}

static void test_calloc_and_overflow(void) {
    assert(kmem_init(arena, sizeof(arena)) == 0);
    unsigned char *z = (unsigned char *)kmem_calloc(64, 4);
    assert(z != NULL);
    for (size_t i = 0; i < 256; ++i) assert(z[i] == 0u);
    assert(kmem_calloc((size_t)-1, 2) == NULL);
    assert(kmem_free_checked(z) == 0);
}

static void test_double_free_rejected(void) {
    assert(kmem_init(arena, sizeof(arena)) == 0);
    void *p = kmem_alloc(512);
    assert(p != NULL);
    assert(kmem_free_checked(p) == 0);
    assert(kmem_free_checked(p) < 0);
}

static void test_fragmentation_and_coalesce(void) {
    assert(kmem_init(arena, sizeof(arena)) == 0);
    void *p[16];
    for (size_t i = 0; i < 16; ++i) { p[i] = kmem_alloc(256+i); assert(p[i]); }
    for (size_t i = 0; i < 16; i+=2) assert(kmem_free_checked(p[i]) == 0);
    for (size_t i = 1; i < 16; i+=2) assert(kmem_free_checked(p[i]) == 0);
    kmem_stats_t st;
    kmem_get_stats(&st);
    assert(st.free_count == 1u);
    assert(st.block_count == 1u);
    assert(st.largest_free > 4096u);
}

int main(void) {
    test_basic_alloc_free();
    test_calloc_and_overflow();
    test_double_free_rejected();
    test_fragmentation_and_coalesce();
    puts("M8 kmem host tests: PASS");
    return 0;
}
EOF

python3 << 'PYEOF'
content = r"""#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "mcsos/kmem.h"

static unsigned char arena[4096u * 8u];

static void test_basic_alloc_free(void) {
    assert(kmem_init(arena, sizeof(arena)) == 0);
    void *a = kmem_alloc(24);
    void *b = kmem_alloc(128);
    void *c = kmem_alloc(4096);
    assert(a && b && c);
    assert(((uintptr_t)a & (KMEM_ALIGN-1u)) == 0u);
    assert(((uintptr_t)b & (KMEM_ALIGN-1u)) == 0u);
    assert(((uintptr_t)c & (KMEM_ALIGN-1u)) == 0u);
    assert(kmem_validate() == 0);
    assert(kmem_free_checked(b) == 0);
    assert(kmem_free_checked(a) == 0);
    assert(kmem_free_checked(c) == 0);
    assert(kmem_validate() == 0);
}

static void test_calloc_and_overflow(void) {
    assert(kmem_init(arena, sizeof(arena)) == 0);
    unsigned char *z = (unsigned char *)kmem_calloc(64, 4);
    assert(z != NULL);
    for (size_t i = 0; i < 256; ++i) assert(z[i] == 0u);
    assert(kmem_calloc((size_t)-1, 2) == NULL);
    assert(kmem_free_checked(z) == 0);
}

static void test_double_free_rejected(void) {
    assert(kmem_init(arena, sizeof(arena)) == 0);
    void *p = kmem_alloc(512);
    assert(p != NULL);
    assert(kmem_free_checked(p) == 0);
    assert(kmem_free_checked(p) < 0);
}

static void test_fragmentation_and_coalesce(void) {
    assert(kmem_init(arena, sizeof(arena)) == 0);
    void *p[16];
    for (size_t i = 0; i < 16; ++i) { p[i] = kmem_alloc(256+i); assert(p[i]); }
    for (size_t i = 0; i < 16; i+=2) assert(kmem_free_checked(p[i]) == 0);
    for (size_t i = 1; i < 16; i+=2) assert(kmem_free_checked(p[i]) == 0);
    kmem_stats_t st;
    kmem_get_stats(&st);
    assert(st.free_count == 1u);
    assert(st.block_count == 1u);
    assert(st.largest_free > 4096u);
}

int main(void) {
    test_basic_alloc_free();
    test_calloc_and_overflow();
    test_double_free_rejected();
    test_fragmentation_and_coalesce();
    puts("M8 kmem host tests: PASS");
    return 0;
}
"""
with open("tests/test_kmem.c", "w") as f:
    f.write(content)
print("OK: tests/test_kmem.c written")
PYEOF

tail -5 tests/test_kmem.c
clang -std=c17 -Wall -Wextra -Werror -Iinclude   tests/test_kmem.c kernel/mm/kmem.c -o build/m8/test_kmem &&   ./build/m8/test_kmem | tee build/m8/test_kmem.log
python3 << 'PYEOF'
content = r"""#include "mcsos/kmem.h"

#define KMEM_MIN_SPLIT 32u

typedef struct kmem_block {
    uint64_t magic;
    size_t   size;
    int      free;
    int      _pad;
    struct kmem_block *prev;
    struct kmem_block *next;
    uint8_t  _align[0];
} __attribute__((aligned(16))) kmem_block_t;

static unsigned char  *g_heap_base   = (unsigned char *)0;
static unsigned char  *g_heap_end    = (unsigned char *)0;
static kmem_block_t   *g_head        = (kmem_block_t *)0;
static int             g_initialized = 0;

static void *kmem_memset(void *dst, int val, size_t n) {
    unsigned char *p = (unsigned char *)dst;
    while (n--) *p++ = (unsigned char)val;
    return dst;
}

static uintptr_t kmem_align_up_ptr(uintptr_t v, size_t align) {
    return (v + (uintptr_t)(align - 1u)) & ~(uintptr_t)(align - 1u);
}

static size_t kmem_align_up_size(size_t v, size_t align) {
    return (v + (align - 1u)) & ~(align - 1u);
}

static unsigned char *kmem_payload(kmem_block_t *b) {
    return (unsigned char *)b + sizeof(kmem_block_t);
}

static kmem_block_t *kmem_header_from_payload(void *ptr) {
    return (kmem_block_t *)((unsigned char *)ptr - sizeof(kmem_block_t));
}

static int kmem_ptr_in_heap(void *ptr) {
    return (unsigned char *)ptr >= g_heap_base &&
           (unsigned char *)ptr <  g_heap_end;
}

static void kmem_split_if_useful(kmem_block_t *block, size_t wanted) {
    uintptr_t new_addr = (uintptr_t)kmem_payload(block) + wanted;
    new_addr = kmem_align_up_ptr(new_addr, KMEM_ALIGN);
    if (new_addr + sizeof(kmem_block_t) >= (uintptr_t)g_heap_end) return;
    const size_t consumed = (size_t)(new_addr - (uintptr_t)kmem_payload(block));
    if (block->size <= consumed + sizeof(kmem_block_t) + KMEM_MIN_SPLIT) return;
    kmem_block_t *nb = (kmem_block_t *)new_addr;
    nb->magic = KMEM_MAGIC;
    nb->size  = block->size - consumed - sizeof(kmem_block_t);
    nb->free  = 1;
    nb->_pad  = 0;
    nb->prev  = block;
    nb->next  = block->next;
    if (block->next) block->next->prev = nb;
    block->next = nb;
    block->size = wanted;
}

static void kmem_coalesce_forward(kmem_block_t *block) {
    while (block && block->next && block->next->free) {
        kmem_block_t *next = block->next;
        unsigned char *expected = kmem_payload(block) + block->size;
        expected = (unsigned char *)kmem_align_up_ptr((uintptr_t)expected, KMEM_ALIGN);
        if (expected != (unsigned char *)next) return;
        block->size += sizeof(kmem_block_t) + next->size;
        block->next  = next->next;
        if (next->next) next->next->prev = block;
        next->magic = 0u;
        next->size  = 0u;
        next->prev  = (kmem_block_t *)0;
        next->next  = (kmem_block_t *)0;
    }
}

int kmem_init(void *base, size_t bytes) {
    if (!base || bytes < sizeof(kmem_block_t) + KMEM_MIN_SPLIT) return -1;
    uintptr_t start = kmem_align_up_ptr((uintptr_t)base, KMEM_ALIGN);
    if (!start || start < (uintptr_t)base) return -2;
    const size_t lost = (size_t)(start - (uintptr_t)base);
    if (bytes <= lost + sizeof(kmem_block_t) + KMEM_MIN_SPLIT) return -3;
    size_t usable = (bytes - lost) & ~(size_t)(KMEM_ALIGN - 1u);
    if (usable <= sizeof(kmem_block_t) + KMEM_MIN_SPLIT) return -4;
    g_heap_base = (unsigned char *)start;
    g_heap_end  = g_heap_base + usable;
    g_head = (kmem_block_t *)g_heap_base;
    g_head->magic = KMEM_MAGIC;
    g_head->size  = usable - sizeof(kmem_block_t);
    g_head->free  = 1;
    g_head->_pad  = 0;
    g_head->prev  = (kmem_block_t *)0;
    g_head->next  = (kmem_block_t *)0;
    g_initialized = 1;
    return kmem_validate();
}

void *kmem_alloc(size_t bytes) {
    if (!g_initialized || !bytes) return (void *)0;
    const size_t wanted = kmem_align_up_size(bytes, KMEM_ALIGN);
    if (!wanted) return (void *)0;
    for (kmem_block_t *cur = g_head; cur; cur = cur->next) {
        if (cur->magic != KMEM_MAGIC) return (void *)0;
        if (cur->free && cur->size >= wanted) {
            kmem_split_if_useful(cur, wanted);
            cur->free = 0;
            return (void *)kmem_payload(cur);
        }
    }
    return (void *)0;
}

void *kmem_calloc(size_t count, size_t bytes) {
    if (count && bytes > (size_t)-1 / count) return (void *)0;
    const size_t total = count * bytes;
    void *ptr = kmem_alloc(total);
    if (ptr) kmem_memset(ptr, 0, total);
    return ptr;
}

int kmem_free_checked(void *ptr) {
    if (!ptr) return 0;
    if (!kmem_ptr_in_heap(ptr)) return -1;
    if ((uintptr_t)ptr & (KMEM_ALIGN - 1u)) return -2;
    kmem_block_t *block = kmem_header_from_payload(ptr);
    if (!kmem_ptr_in_heap(block) || block->magic != KMEM_MAGIC) return -3;
    if (block->free) return -4;
    block->free = 1;
    kmem_coalesce_forward(block);
    if (block->prev && block->prev->free) kmem_coalesce_forward(block->prev);
    return kmem_validate();
}

void kmem_get_stats(kmem_stats_t *out) {
    if (!out) return;
    kmem_memset(out, 0, sizeof(*out));
    if (!g_initialized) return;
    out->total_bytes = (size_t)(g_heap_end - g_heap_base);
    for (kmem_block_t *cur = g_head; cur; cur = cur->next) {
        out->block_count++;
        if (cur->free) {
            out->free_count++;
            out->free_bytes += cur->size;
            if (cur->size > out->largest_free) out->largest_free = cur->size;
        } else {
            out->used_bytes += cur->size;
        }
    }
}

int kmem_validate(void) {
    if (!g_initialized || !g_heap_base || g_heap_end <= g_heap_base || !g_head) return -1;
    if ((unsigned char *)g_head != g_heap_base) return -2;
    kmem_block_t  *prev   = (kmem_block_t *)0;
    unsigned char *cursor = g_heap_base;
    size_t guard = 0u;
    for (kmem_block_t *cur = g_head; cur; cur = cur->next) {
        if (++guard > 1048576u) return -3;
        if ((unsigned char *)cur != cursor) return -4;
        if ((unsigned char *)cur < g_heap_base ||
            (unsigned char *)cur + sizeof(kmem_block_t) > g_heap_end) return -5;
        if (cur->magic != KMEM_MAGIC) return -6;
        if (cur->prev != prev) return -7;
        if (cur->size > (size_t)(g_heap_end - kmem_payload(cur))) return -8;
        cursor = (unsigned char *)kmem_align_up_ptr(
            (uintptr_t)(kmem_payload(cur) + cur->size), KMEM_ALIGN);
        if (!cursor || cursor > g_heap_end) return -9;
        prev = cur;
    }
    return 0;
}
"""
with open("kernel/mm/kmem.c", "w") as f:
    f.write(content)
print("OK: kernel/mm/kmem.c rewritten")
PYEOF

clang -std=c17 -Wall -Wextra -Werror -Iinclude   tests/test_kmem.c kernel/mm/kmem.c -o build/m8/test_kmem &&   ./build/m8/test_kmem | tee build/m8/test_kmem.log
clang -std=c17 -Wall -Wextra -Werror -ffreestanding -fno-builtin   -Iinclude -c kernel/mm/kmem.c -o build/m8/kmem.freestanding.o
nm -u build/m8/kmem.freestanding.o | tee build/m8/nm_u.txt
readelf -h build/m8/kmem.freestanding.o | tee build/m8/readelf_h.txt
# Buat script preflight
cat > scripts/check_m8_kmem.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo '[M8] checking files...'
for f in include/mcsos/kmem.h kernel/mm/kmem.c tests/test_kmem.c Makefile; do
  [[ -f "$f" ]] || { echo "[FAIL] missing $f"; exit 1; }
done
echo '[M8] checking toolchain...'
command -v clang && command -v nm && command -v readelf && command -v objdump
echo '[M8] freestanding audit...'
mkdir -p build/m8
clang -std=c17 -Wall -Wextra -Werror -ffreestanding -fno-builtin \
  -Iinclude -c kernel/mm/kmem.c -o build/m8/kmem.freestanding.o
nm -u build/m8/kmem.freestanding.o | tee build/m8/nm_u.txt
[[ -s build/m8/nm_u.txt ]] && { echo '[FAIL] unresolved symbols'; exit 1; }
readelf -h build/m8/kmem.freestanding.o > build/m8/readelf_h.txt
echo '[M8] host unit test...'
clang -std=c17 -Wall -Wextra -Werror -Iinclude \
  tests/test_kmem.c kernel/mm/kmem.c -o build/m8/test_kmem
./build/m8/test_kmem | tee build/m8/test_kmem.log
grep -q 'PASS' build/m8/test_kmem.log
echo '[PASS] M8 preflight completed.'
EOF

chmod +x scripts/check_m8_kmem.sh
# Commit semua hasil M8
git add include/mcsos/kmem.h kernel/mm/kmem.c tests/test_kmem.c scripts/check_m8_kmem.sh
git add build/m8/test_kmem.log build/m8/nm_u.txt build/m8/readelf_h.txt 2>/dev/null || true
git commit -m "M8: add early kernel heap allocator"
git log --oneline -3
#include "mcsos/kmem.h"
#define M8_BOOT_HEAP_SIZE (64u * 1024u)
static unsigned char m8_boot_heap[M8_BOOT_HEAP_SIZE] __attribute__((aligned(4096)));
// panggil setelah PMM/VMM init:
int rc = kmem_init(m8_boot_heap, sizeof(m8_boot_heap));
if (rc != 0) kernel_panic("M8 kmem_init failed");
cat kernel/kernel.c
cat kmain.c
python3 << 'PYEOF'
content = r"""#include <stdint.h>
#include <stddef.h>
#include "mcsos/kmem.h"

void x86_64_idt_init(void);

static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile ("outb %b0, %w1" : : "a"(val), "Nd"(port));
}

void early_serial_init() {
    outb(0x3f8 + 1, 0x00);
    outb(0x3f8 + 3, 0x80);
    outb(0x3f8 + 0, 0x03);
    outb(0x3f8 + 1, 0x00);
    outb(0x3f8 + 3, 0x03);
}

void early_serial_puts(const char* s) {
    for (size_t i = 0; s[i] != '\0'; i++) {
        outb(0x3f8, s[i]);
    }
}

#define M8_BOOT_HEAP_SIZE (64u * 1024u)
static unsigned char m8_boot_heap[M8_BOOT_HEAP_SIZE] __attribute__((aligned(4096)));

void kmain(void) {
    early_serial_init();
    early_serial_puts("MCSOS 260502 M2 boot path entered\n");
    early_serial_puts("[M2] early serial online\n");

    x86_64_idt_init();
    early_serial_puts("[M4] Triggering manual int3 breakpoint test execution...\n");
    __asm__ __volatile__("int $3");
    early_serial_puts("[M4 SUCCESS] System successfully recovered from breakpoint and continued execution!\n");

    /* M8: inisialisasi kernel heap awal */
    int rc = kmem_init(m8_boot_heap, sizeof(m8_boot_heap));
    if (rc != 0) {
        early_serial_puts("[M8 FAIL] kmem_init failed\n");
        for (;;) { __asm__ ("hlt"); }
    }
    early_serial_puts("[M8] heap initialized\n");

    void *probe = kmem_alloc(128);
    if (probe == (void*)0) {
        early_serial_puts("[M8 FAIL] kmem_alloc probe failed\n");
        for (;;) { __asm__ ("hlt"); }
    }
    if (kmem_free_checked(probe) != 0) {
        early_serial_puts("[M8 FAIL] kmem_free_checked probe failed\n");
        for (;;) { __asm__ ("hlt"); }
    }
    early_serial_puts("[M8 SUCCESS] kernel heap alloc/free probe OK\n");

    early_serial_puts("[M2] kernel reached controlled halt loop\n");
    for (;;) { __asm__ ("hlt"); }
}
"""
with open("kmain.c", "w") as f:
    f.write(content)
print("OK: kmain.c updated")
PYEOF

make
git add kmain.c
git commit -m "M8: integrate heap bootstrap into kmain"
make -f makefile run 2>/dev/null || qemu-system-x86_64 -kernel build/kernel.elf -serial stdio -display none 2>&1 | head -30
grep -i "qemu\|run\|iso" makefile Makefile | head -20
ls *.iso *.sh 2>/dev/null
cat jalankan_m5.sh
which xorriso mformat mcopy 2>/dev/null || echo "missing"
ls limine/
cat limine.cfg
# Buat struktur ISO
mkdir -p iso_root/boot/limine iso_root/EFI/BOOT
# Copy kernel dan Limine files
cp build/kernel.elf iso_root/boot/kernel.elf
cp limine.cfg iso_root/boot/limine/limine.cfg
cp limine/limine-bios.sys limine/limine-bios-cd.bin limine/limine-uefi-cd.bin iso_root/boot/limine/
cp limine/BOOTX64.EFI iso_root/EFI/BOOT/
# Buat ISO
xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   -o build/mcsos_m8.iso iso_root
# Install Limine ke ISO
./limine/limine bios-install build/mcsos_m8.iso
# Jalankan QEMU
qemu-system-x86_64 -M q35 -m 512M   -cdrom build/mcsos_m8.iso   -serial stdio -display none   -no-reboot -no-shutdown 2>&1 | tee build/m8/qemu_m8.log | head -30
cat kernel/kernel.c
python3 << 'PYEOF'
content = open("kernel/kernel.c").read()

old = 'void kernel_main(void) {\n    serial_init();\n    idt_init();\n    kernel_memory_init();\n    asm volatile ("sti");\n    for (;;) asm volatile ("hlt");\n}'

new = '''#include "mcsos/kmem.h"

#define M8_BOOT_HEAP_SIZE (64u * 1024u)
static unsigned char m8_boot_heap[M8_BOOT_HEAP_SIZE] __attribute__((aligned(4096)));

void kernel_main(void) {
    serial_init();
    idt_init();
    kernel_memory_init();

    /* M8: kernel heap bootstrap */
    int rc = kmem_init(m8_boot_heap, sizeof(m8_boot_heap));
    if (rc != 0) {
        serial_write_string("[M8 FAIL] kmem_init failed\\n");
        for (;;) asm volatile ("hlt");
    }
    serial_write_string("[M8] heap initialized\\n");

    void *probe = kmem_alloc(128);
    if (probe == (void*)0) {
        serial_write_string("[M8 FAIL] kmem_alloc probe failed\\n");
        for (;;) asm volatile ("hlt");
    }
    if (kmem_free_checked(probe) != 0) {
        serial_write_string("[M8 FAIL] kmem_free_checked failed\\n");
        for (;;) asm volatile ("hlt");
    }
    serial_write_string("[M8 SUCCESS] kernel heap alloc/free probe OK\\n");

    asm volatile ("sti");
    for (;;) asm volatile ("hlt");
}'''

if old in content:
    content = content.replace(old, new)
    open("kernel/kernel.c", "w").write(content)
    print("OK: kernel/kernel.c updated")
else:
    print("ERROR: pattern not found, print manually")
PYEOF

make && cp build/kernel.elf iso_root/boot/kernel.elf && xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   -o build/mcsos_m8.iso iso_root 2>/dev/null && ./limine/limine bios-install build/mcsos_m8.iso 2>/dev/null && qemu-system-x86_64 -M q35 -m 512M   -cdrom build/mcsos_m8.iso   -serial stdio -display none   -no-reboot -no-shutdown 2>&1 | tee build/m8/qemu_m8.log | head -20
git add kernel/kernel.c
git commit -m "M8: integrate heap bootstrap into kernel_main, QEMU log OK"
git log --oneline -4
mkdir -p include kernel arch/x86_64 tests evidence/m9 build/m9
git add .
git commit -m "checkpoint before M9 scheduler" || true
git switch -c m9-kernel-thread-scheduler
#ifndef MCSOS_THREAD_H
#define MCSOS_THREAD_H
#include <stddef.h>
#include <stdint.h>
#define MCSOS_THREAD_MAGIC    UINT64_C(0x4d43534f53544852)
#define MCSOS_THREAD_NAME_MAX 32u
#define MCSOS_STACK_ALIGN     16u
#define MCSOS_MIN_KERNEL_STACK 4096u
typedef enum mcsos_thread_state {
} mcsos_thread_state_t;
typedef enum mcsos_sched_result {
} mcsos_sched_result_t;
typedef void (*mcsos_thread_entry_t)(void *arg);
typedef struct mcsos_context {
} mcsos_context_t;
typedef struct mcsos_thread {
} mcsos_thread_t;
typedef struct mcsos_scheduler {
} mcsos_scheduler_t;
/* Assembly — context switch */
void mcsos_context_switch(mcsos_context_t *old_context,
void mcsos_thread_trampoline(void);
/* Scheduler API */
int              mcsos_scheduler_init(mcsos_scheduler_t *sched,
int              mcsos_thread_prepare(mcsos_thread_t *thread,
int              mcsos_sched_enqueue(mcsos_scheduler_t *sched,
mcsos_thread_t  *mcsos_sched_pick_next(mcsos_scheduler_t *sched);
int              mcsos_sched_yield(mcsos_scheduler_t *sched);
int              mcsos_sched_tick(mcsos_scheduler_t *sched);
int              mcsos_thread_block_current(mcsos_scheduler_t *sched);
int              mcsos_thread_mark_ready(mcsos_scheduler_t *sched,
int              mcsos_sched_validate(const mcsos_scheduler_t *sched);
size_t           mcsos_sched_ready_count(const mcsos_scheduler_t *sched);
#endif /* MCSOS_THREAD_H */
#ifndef MCSOS_THREAD_H
#define MCSOS_THREAD_H
#include <stddef.h>
#include <stdint.h>
#define MCSOS_THREAD_MAGIC    UINT64_C(0x4d43534f53544852)
#define MCSOS_THREAD_NAME_MAX 32u
#define MCSOS_STACK_ALIGN     16u
#define MCSOS_MIN_KERNEL_STACK 4096u
typedef enum mcsos_thread_state {
} mcsos_thread_state_t;
typedef enum mcsos_sched_result {
} mcsos_sched_result_t;
typedef void (*mcsos_thread_entry_t)(void *arg);
typedef struct mcsos_context {
} mcsos_context_t;
typedef struct mcsos_thread {
} mcsos_thread_t;
typedef struct mcsos_scheduler {
} mcsos_scheduler_t;
/* Assembly — context switch */
void mcsos_context_switch(mcsos_context_t *old_context,
void mcsos_thread_trampoline(void);
/* Scheduler API */
int              mcsos_scheduler_init(mcsos_scheduler_t *sched,
int              mcsos_thread_prepare(mcsos_thread_t *thread,
int              mcsos_sched_enqueue(mcsos_scheduler_t *sched,
mcsos_thread_t  *mcsos_sched_pick_next(mcsos_scheduler_t *sched);
int              mcsos_sched_yield(mcsos_scheduler_t *sched);
int              mcsos_sched_tick(mcsos_scheduler_t *sched);
int              mcsos_thread_block_current(mcsos_scheduler_t *sched);
int              mcsos_thread_mark_ready(mcsos_scheduler_t *sched,
int              mcsos_sched_validate(const
