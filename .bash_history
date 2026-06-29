python3 << 'PYEOF'
with open("src/kernel/arch/x86_64/boot.s") as f:
    content = f.read()

# Ganti inisialisasi COM1 yang lebih agresif - tulis tanpa tunggu
old = "\t/* Inisialisasi COM1 */"
new = "\t/* Inisialisasi COM1 - tulis langsung tanpa cek status */"

# Tambah output ke port 0xe9 (QEMU debug port) yang tidak perlu inisialisasi
content = content.replace(
    "\t/* Inisialisasi COM1 */",
    "\t/* Port 0xe9 = QEMU debug port, langsung tanpa init */\n\tmovl $0xe9, %edx\n\tmovb $65, %al\n\toutb %al, %dx\n\t/* Inisialisasi COM1 */"
)

with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null && grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null && timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -device isa-debug-exit   -debugcon file:build/m9/debug_port.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== DEBUG PORT ==="
xxd build/m9/debug_port.log | head -3
echo "=== SERIAL ==="
xxd build/m9/serial.log | head -3
# Install GRUB EFI support
sudo apt-get install -y grub-efi-amd64-bin ovmf
# Test dengan UEFI QEMU
ls /usr/share/ovmf/OVMF.fd 2>/dev/null || ls /usr/share/OVMF/OVMF_CODE.fd 2>/dev/null || find /usr -name "OVMF*.fd" 2>/dev/null | head -3
# Buat ISO dengan GRUB EFI
mkdir -p build/m9/iso/EFI/BOOT
grub-mkstandalone   --format=x86_64-efi   --output=build/m9/iso/EFI/BOOT/BOOTX64.EFI   --modules="part_gpt part_msdos fat iso9660 multiboot2 normal echo"   "boot/grub/grub.cfg=build/m9/iso/boot/grub/grub.cfg" 2>/dev/null
grub-mkrescue   --modules="part_gpt part_msdos fat iso9660 multiboot2"   -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
echo "ISO built"
# Jalankan dengan UEFI
timeout 30 qemu-system-x86_64   -bios /usr/share/ovmf/OVMF.fd   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
xxd build/m9/serial.log | head -5
strings build/m9/serial.log | grep -E "EARLY|M9|Loading|MCSOS|A$|^A"
python3 -c "
open('build/m9/iso/boot/grub/grub.cfg','w').write('set timeout=0\nset default=0\nmenuentry \"MCSOS M9\" {\n  multiboot2 /boot/kernel_m9.elf\n  boot\n}\n')
"
# Rebuild dengan EFI
grub-mkstandalone   --format=x86_64-efi   --output=build/m9/iso/EFI/BOOT/BOOTX64.EFI   --modules="part_gpt part_msdos fat iso9660 multiboot2 normal echo"   "boot/grub/grub.cfg=build/m9/iso/boot/grub/grub.cfg" 2>/dev/null
grub-mkrescue   --modules="part_gpt part_msdos fat iso9660 multiboot2"   -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
timeout 30 qemu-system-x86_64   -bios /usr/share/ovmf/OVMF.fd   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial.log | grep -v "^\[" | head -20
timeout 30 qemu-system-x86_64   -machine pc   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M   -d guest_errors   -D build/m9/qemu_guest_errors.log 2>/dev/null
echo "=== SERIAL ==="
xxd build/m9/serial.log | head -3
echo "=== GUEST ERRORS ==="
cat build/m9/qemu_guest_errors.log | head -20
# Cek apakah ada cross-compiler 32-bit
which ld.lld
ld.lld --help 2>&1 | grep "i386\|elf32" | head -3
python3 << 'PYEOF'
with open("Makefile") as f:
    content = f.read()

# Tambah flag elf32 ke linker
content = content.replace(
    "\tld.lld -T linker.ld --no-dynamic-linker",
    "\tld.lld -T linker.ld --no-dynamic-linker -m elf_i386"
)

with open("Makefile", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>&1 | tail -5
python3 << 'PYEOF'
with open("Makefile") as f:
    content = f.read()
content = content.replace(
    "\tld.lld -T linker.ld --no-dynamic-linker -m elf_i386",
    "\tld.lld -T linker.ld --no-dynamic-linker"
)
with open("Makefile", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null
cp build/m9/test_scheduler.log evidence/m9/
echo "Host unit test: PASS
Freestanding compile: OK  
Kernel ELF built: OK
QEMU: GRUB load kernel tapi ELF64+Multiboot2 execution terkendala mode CPU
grub-file --is-x86-multiboot2: exit 0 (header valid)" > evidence/m9/qemu_status.log
git add -A
git commit -m "M9: QEMU boot investigation, grub-file validates header"
timeout 15 qemu-system-x86_64   -kernel build/m9/kernel_m9.elf   -serial file:build/m9/serial_direct.log   -display none   -no-reboot   -m 128M   -append "console=ttyS0" 2>&1 | head -5
xxd build/m9/serial_direct.log | head -5
python3 << 'PYEOF'
# Tambahkan PVH ELF note ke linker script
content = """ENTRY(_start)
SECTIONS
{
    . = 0x100000;
    .note.gnu.build-id : { *(.note.gnu.build-id) }
    .text : { *(.text) }
    .rodata : { *(.rodata) }
    .data : { *(.data) }
    .bss : {
        *(.bss)
        *(COMMON)
    }
}
"""
with open("linker.ld", "w") as f:
    f.write(content)
print("Done")
PYEOF

python3 << 'PYEOF'
with open("src/kernel/arch/x86_64/boot.s") as f:
    content = f.read()

pvh_note = """\t.section .note.gnu.build-id, "a"
\t.align 4
\t.long 4          /* namesz */
\t.long 4          /* descsz */
\t.long 0x1        /* type: NT_GNU_BUILD_ID */
\t.ascii "GNU\\0"
\t.long 0x0

"""

content = pvh_note + content

with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null && timeout 15 qemu-system-x86_64   -kernel build/m9/kernel_m9.elf   -serial file:build/m9/serial_direct.log   -display none   -no-reboot   -m 128M   -append "console=ttyS0" 2>&1 | head -3
xxd build/m9/serial_direct.log | head -5
timeout 15 qemu-system-x86_64   -M microvm,x-option-roms=off,pic=off,pit=off   -kernel build/m9/kernel_m9.elf   -serial file:build/m9/serial_direct.log   -display none   -no-reboot   -m 128M 2>&1 | head -5
echo "exit: $?"
xxd build/m9/serial_direct.log | head -3
timeout 15 qemu-system-x86_64   -device loader,file=build/m9/kernel_m9.elf,cpu-num=0   -serial file:build/m9/serial_direct.log   -display none   -no-reboot   -m 128M 2>&1 | head -5
xxd build/m9/serial_direct.log | head -3
xxd build/m9/serial_direct.log | head -10
wc -c build/m9/serial_direct.log
timeout 15 qemu-system-x86_64   -device loader,file=build/m9/kernel_m9.elf,cpu-num=0   -device loader,addr=0x100018,cpu-num=0   -serial file:build/m9/serial_direct.log   -display none   -no-reboot   -m 128M 2>&1 | head -5
xxd build/m9/serial_direct.log | head -5
wc -c build/m9/serial_direct.log
git add -A
git commit -m "M9: all scheduler code complete, host test PASS, QEMU boot WIP"
git log --oneline -5
grep -i "qemu\|serial\|boot\|run" /mnt/user-data/uploads/OS_panduan_M9.md | head -30
# Cek apakah Limine tersedia
which limine 2>/dev/null
apt-cache search limine 2>/dev/null | head -5
ls ~/mcsos/limine* 2>/dev/null
find ~ -name "limine*" 2>/dev/null | head -5
ls ~/iso_root/
ls ~/iso_root/boot/limine/
cat ~/limine.cfg
ls ~/iso_root/boot/
find ~/iso_root -name "*.elf" 2>/dev/null
which limine
ls ~/limine* 2>/dev/null
# Copy kernel M9
cp build/m9/kernel_m9.elf ~/iso_root/boot/kernel.elf
# Update limine.cfg untuk M9
cat > ~/limine.cfg << 'EOF'
TIMEOUT=0
:MCSOS M9
    PROTOCOL=limine
    KERNEL_PATH=boot:///boot/kernel.elf
EOF

cat ~/limine.cfg
file ~/iso_root/boot/kernel.elf
readelf -h ~/iso_root/boot/kernel.elf | grep -E "Class|Machine|Entry"
# Buat ISO dengan Limine
xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null
# Deploy limine ke ISO
~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null
echo "ISO built"
# Jalankan QEMU
timeout 15 qemu-system-x86_64   -bios /usr/share/ovmf/OVMF.fd   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial_limine.log
python3 << 'PYEOF'
content = """\t.section .text
\t.global _start
\t.code64
_start:
\t/* Limine sudah setup long mode, langsung panggil kmain */
\tmovabsq $stack_top, %rsp
\txorq %rbp, %rbp
\tcall kmain
hang:
\thlt
\tjmp hang

\t.section .bss
\t.align 16
stack_bottom:
\t.skip 16384
stack_top:
"""
with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null && cp build/m9/kernel_m9.elf ~/iso_root/boot/kernel.elf && xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null && timeout 15 qemu-system-x86_64   -bios /usr/share/ovmf/OVMF.fd   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial_limine.log
# Limine.cfg harus ada di iso_root
cp ~/limine.cfg ~/iso_root/boot/limine/limine.cfg
cat ~/iso_root/boot/limine/limine.cfg
xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null && timeout 15 qemu-system-x86_64   -bios /usr/share/ovmf/OVMF.fd   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial_limine.log
nano kernel/kmain.c
make m9-kernel 2>/dev/null && cp build/m9/kernel_m9.elf ~/iso_root/boot/kernel.elf && xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null && timeout 15 qemu-system-x86_64   -bios /usr/share/ovmf/OVMF.fd   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial_limine.log
timeout 15 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial_limine.log
timeout 15 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -no-reboot   -m 128M   -d guest_errors   -D build/m9/limine_debug.log 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial_limine.log
echo "=== GUEST ERRORS ==="
head -10 build/m9/limine_debug.log
python3 << 'PYEOF'
content = """ENTRY(_start)
SECTIONS
{
    . = 0xFFFFFFFF80100000;
    .text : { *(.text) }
    .rodata : { *(.rodata) }
    .data : { *(.data) }
    .bss : {
        *(.bss)
        *(COMMON)
    }
}
"""
with open("linker.ld", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null && cp build/m9/kernel_m9.elf ~/iso_root/boot/kernel.elf && xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null && timeout 15 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial_limine.log
timeout 10 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -no-reboot   -m 128M 2>/dev/null &
sleep 8
kill %1 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial_limine.log
timeout 10 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -no-reboot   -m 128M &
timeout 10 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>build/m9/limine_stderr.log
cat build/m9/serial_limine.log
cat build/m9/limine_stderr.log
timeout 10 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>build/m9/limine_stderr.log
cat build/m9/serial_limine.log
cat build/m9/limine_stderr.log
cd ~/mcsos
cat build/m9/serial_limine.log
cat build/m9/limine_stderr.log 2>/dev/null
readelf -h build/m9/kernel_m9.elf | grep Entry
nm build/m9/kernel_m9.elf | grep stack_top
python3 << 'PYEOF'
content = """\t.section .text
\t.global _start
\t.code64
_start:
\t/* Setup stack dulu */
\tmovabsq $stack_top, %rsp
\txorq %rbp, %rbp

\t/* Init COM1 dan tulis 'A' langsung */
\tmovw $0x3F9, %dx
\tmovb $0x00, %al
\toutb %al, %dx
\tmovw $0x3FB, %dx
\tmovb $0x80, %al
\toutb %al, %dx
\tmovw $0x3F8, %dx
\tmovb $0x03, %al
\toutb %al, %dx
\tmovw $0x3F9, %dx
\tmovb $0x00, %al
\toutb %al, %dx
\tmovw $0x3FB, %dx
\tmovb $0x03, %al
\toutb %al, %dx
\tmovw $0x3FA, %dx
\tmovb $0xC7, %al
\toutb %al, %dx
\tmovw $0x3FC, %dx
\tmovb $0x0B, %al
\toutb %al, %dx

\t/* Tulis 'A' */
\tmovw $0x3F8, %dx
\tmovb $65, %al
\toutb %al, %dx
\tmovb $13, %al
\toutb %al, %dx
\tmovb $10, %al
\toutb %al, %dx

\tcall kmain
hang:
\thlt
\tjmp hang

\t.section .bss
\t.align 16
stack_bottom:
\t.skip 16384
stack_top:
"""
with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null && cp build/m9/kernel_m9.elf ~/iso_root/boot/kernel.elf && xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null && timeout 15 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
xxd build/m9/serial_limine.log | head -5
nano include/limine.h
python3 << 'PYEOF'
with open("kernel/kmain.c") as f:
    content = f.read()

# Tambah limine base revision di awal file setelah includes
content = content.replace(
    '#include "mcsos_thread.h"',
    '#include "mcsos_thread.h"\n#include "limine.h"\n\nLIMINE_BASE_REVISION(2)'
)

with open("kernel/kmain.c", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null && cp build/m9/kernel_m9.elf ~/iso_root/boot/kernel.elf && xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null && timeout 15 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
xxd build/m9/serial_limine.log | head -5
~/limine/limine --version 2>/dev/null || ~/limine/limine version 2>/dev/null
ls ~/limine/
cat ~/limine/limine.h | head -50
cp ~/limine/limine.h include/limine.h
python3 << 'PYEOF'
with open("kernel/kmain.c") as f:
    content = f.read()

content = content.replace(
    '#include "limine.h"\n\nLIMINE_BASE_REVISION(2)',
    '#include "limine.h"\n\nLIMINE_REQUESTS_START_MARKER;\nLIMINE_BASE_REVISION(3);\nLIMINE_REQUESTS_END_MARKER;'
)

with open("kernel/kmain.c", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null && cp build/m9/kernel_m9.elf ~/iso_root/boot/kernel.elf && xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null && timeout 15 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
xxd build/m9/serial_limine.log | head -5
ls ~/iso_root/boot/limine/
# Limine v7 pakai format baru
cat > ~/iso_root/boot/limine/limine.cfg << 'EOF'
/MCSOS M9
    PROTOCOL=limine
    PATH=boot():/boot/kernel.elf
EOF

cat ~/iso_root/boot/limine/limine.cfg
xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null && timeout 15 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
xxd build/m9/serial_limine.log | head -5
timeout 15 qemu-system-x86_64   -bios /usr/share/ovmf/OVMF.fd   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
xxd build/m9/serial_limine.log | head -5
strings build/m9/serial_limine.log | grep -v "^\[" | grep -v "^$" | head -30
# Limine v7 format baru - pakai timeout dan entry berbeda
cat > ~/iso_root/boot/limine/limine.cfg << 'EOF'
TIMEOUT=0
GRAPHICS=no
SERIAL=yes

/MCSOS M9
    PROTOCOL=limine
    PATH=boot():/boot/kernel.elf
EOF

cat ~/iso_root/boot/limine/limine.cfg
xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null && timeout 15 qemu-system-x86_64   -bios /usr/share/ovmf/OVMF.fd   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial_limine.log | grep -v "^\[" | head -20
wc -c build/m9/serial_limine.log
strings build/m9/serial_limine.log | head -40
# Coba format path yang berbeda
cat > ~/iso_root/boot/limine/limine.cfg << 'EOF'
TIMEOUT=0
GRAPHICS=no
SERIAL=yes

/MCSOS M9
    PROTOCOL=limine
    PATH=boot():/boot/kernel.elf
    KASLR=no
EOF

# Juga coba tanpa boot()
cat > /tmp/limine_alt.cfg << 'EOF'
TIMEOUT=0
GRAPHICS=no
SERIAL=yes

/MCSOS M9
    PROTOCOL=limine
    PATH=:/boot/kernel.elf
    KASLR=no
EOF

cat ~/iso_root/boot/limine/limine.cfg
find ~/limine -name "*.cfg" 2>/dev/null
cat ~/limine/limine.h | grep -A5 "PATH\|KERNEL_PATH" | head -20
find ~/limine -name "*.cfg" 2>/dev/null
cat ~/limine/limine.h | grep -A5 "PATH\|KERNEL_PATH" | head -20
cat > ~/iso_root/boot/limine/limine.cfg << 'EOF'
TIMEOUT=0
SERIAL=yes

/MCSOS M9
    PROTOCOL=limine
    KERNEL_PATH=boot():/boot/kernel.elf
    KASLR=no
EOF

xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null && timeout 15 qemu-system-x86_64   -bios /usr/share/ovmf/OVMF.fd   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial_limine.log | grep -v "^\[" | grep -v "^$" | head -20
# Cek apakah ada limine binary lain
find ~ -name "limine" -type f 2>/dev/null
# Cek versi limine di iso_root
file ~/iso_root/boot/limine/limine-bios-cd.bin
# Lihat bagaimana M2 dulu build ISO
find ~ -name "Makefile" | xargs grep -l "limine\|xorriso" 2>/dev/null | head -5
cat ~/limine/Makefile
history | grep -E "qemu|limine|xorriso|iso" | head -30
history | grep -E "limine|xorriso" | head -20
git log --oneline | head -10
git show 04b56ec --stat | head -20
git show d18dc71 --stat | head -10
git show d18dc71 -- mcsos/Makefile 2>/dev/null | head -50
git show d18dc71 -- Makefile 2>/dev/null | head -50
git show d18dc71 -- kernel/kernel.c
git show d18dc71 --name-only | head -20
git log --oneline -15
git show d18dc71:kernel/kernel.c
cd ~/mcsos
git log --oneline -5
git show d18dc71 --name-only | grep -i "linker\|ld\|link"
find . -name "*.ld" | head -5
git log --all --oneline | head -20
git show d18dc71:linker.ld 2>/dev/null || git show 04b56ec:linker.ld 2>/dev/null
python3 << 'PYEOF'
content = """OUTPUT_FORMAT("elf64-x86-64")
ENTRY(kmain)
SECTIONS
{
    . = 0xffffffff80000000;
    .text : ALIGN(0x1000) { *(.text .text.*) }
    .rodata : ALIGN(0x1000) { *(.rodata .rodata.*) }
    .requests_start_marker : ALIGN(0x1000) { *(.requests_start_marker) }
    .requests : { *(.requests) }
    .requests_end_marker : { *(.requests_end_marker) }
    .data : ALIGN(0x1000) { *(.data .data.*) }
    .bss : ALIGN(0x1000) {
        *(.bss .bss.*)
        *(COMMON)
    }
}
"""
with open("linker.ld", "w") as f:
    f.write(content)
print("Done")
PYEOF

python3 << 'PYEOF'
content = """\t.section .text
\t.global kmain
"""
with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

nano kernel/kmain.c
make m9-kernel 2>&1 | tail -5
cp build/m9/kernel_m9.elf ~/iso_root/boot/kernel.elf && xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null && timeout 15 qemu-system-x86_64   -bios /usr/share/ovmf/OVMF.fd   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial_limine.log | grep -v "^\[" | grep -v "^$" | head -20
ls ~/iso_root/EFI/BOOT/ 2>/dev/null || echo "EFI dir tidak ada"
cp ~/limine/BOOTX64.EFI ~/iso_root/EFI/BOOT/BOOTX64.EFI
# Rebuild ISO
xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null && timeout 15 qemu-system-x86_64   -bios /usr/share/ovmf/OVMF.fd   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial_limine.log | grep -v "^\[" | grep -v "^$" | head -20
# Cek isi ISO
isoinfo -l -i build/m9/mcsos_m9_limine.iso 2>/dev/null | grep -i "efi\|boot\|limine" | head -20
# Mount ISO dan cek isinya
sudo mkdir -p /mnt/iso
sudo mount -o loop build/m9/mcsos_m9_limine.iso /mnt/iso 2>/dev/null
find /mnt/iso -type f | head -20
sudo umount /mnt/iso 2>/dev/null
timeout 15 qemu-system-x86_64   -bios /usr/share/ovmf/OVMF.fd   -drive file=build/m9/mcsos_m9_limine.iso,media=cdrom   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial_limine.log | grep -v "^\[" | grep -v "^$" | head -20
ls /usr/share/OVMF/ 2>/dev/null
ls /usr/share/ovmf/ 2>/dev/null
find /usr -name "OVMF*.fd" 2>/dev/null
cp /usr/share/OVMF/OVMF_VARS_4M.fd /tmp/OVMF_VARS.fd
timeout 15 qemu-system-x86_64   -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd   -drive if=pflash,format=raw,file=/tmp/OVMF_VARS.fd   -drive file=build/m9/mcsos_m9_limine.iso,media=cdrom   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial_limine.log | grep -v "^\[" | grep -v "^$" | head -20
# Buat disk image dengan partisi EFI
dd if=/dev/zero of=build/m9/disk.img bs=1M count=64 2>/dev/null
parted build/m9/disk.img --script mklabel gpt mkpart ESP fat32 1MiB 63MiB set 1 esp on 2>/dev/null
# Mount dan isi dengan file Limine
sudo losetup -fP build/m9/disk.img
LOOP=$(sudo losetup -j build/m9/disk.img | cut -d: -f1)
echo "Loop: $LOOP"
sudo mkfs.fat -F32 ${LOOP}p1 2>/dev/null
sudo mkdir -p /mnt/efi
sudo mount ${LOOP}p1 /mnt/efi
sudo mkdir -p /mnt/efi/EFI/BOOT
sudo mkdir -p /mnt/efi/boot/limine
sudo cp ~/limine/BOOTX64.EFI /mnt/efi/EFI/BOOT/
sudo cp ~/iso_root/boot/limine/limine.cfg /mnt/efi/boot/limine/
sudo cp ~/iso_root/boot/limine/limine-bios.sys /mnt/efi/boot/limine/
sudo cp ~/iso_root/boot/kernel.elf /mnt/efi/boot/
sudo umount /mnt/efi
sudo losetup -d $LOOP
timeout 15 qemu-system-x86_64   -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd   -drive if=pflash,format=raw,file=/tmp/OVMF_VARS.fd   -drive file=build/m9/disk.img,format=raw   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial_limine.log | grep -v "^\[" | grep -v "^$" | head -20
# Format langsung tanpa partisi
dd if=/dev/zero of=build/m9/efi.img bs=1M count=32 2>/dev/null
mkfs.fat -F32 build/m9/efi.img 2>/dev/null
sudo mkdir -p /mnt/efi
sudo mount build/m9/efi.img /mnt/efi
sudo mkdir -p /mnt/efi/EFI/BOOT
sudo mkdir -p /mnt/efi/boot/limine
sudo cp ~/limine/BOOTX64.EFI /mnt/efi/EFI/BOOT/
sudo cp ~/iso_root/boot/limine/limine.cfg /mnt/efi/boot/limine/
sudo cp ~/iso_root/boot/kernel.elf /mnt/efi/boot/
sudo umount /mnt/efi
timeout 15 qemu-system-x86_64   -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd   -drive if=pflash,format=raw,file=/tmp/OVMF_VARS.fd   -drive file=build/m9/efi.img,format=raw,if=virtio   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial_limine.log | grep -v "^\[" | grep -v "^$" | head -20
cd ~/mcsos
git branch
git status
ls
mkdir -p kernel/user include/mcsos/user tests/m11 scripts build
ls include/mcsos/user
cat > scripts/m11_preflight.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "[M11] Preflight lingkungan dan artefak M0-M10"
for tool in git make clang nm readelf objdump sha256sum; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[FAIL] tool tidak ditemukan: $tool" >&2
    exit 1
  fi
  echo "[OK] $tool -> $(command -v "$tool")"
done

clang --version | sed -n '1,3p'
make --version | sed -n '1p'

required_dirs=(kernel arch include scripts tests)
for d in "${required_dirs[@]}"; do
  if [ ! -d "$d" ]; then
    echo "[WARN] direktori $d belum ada; sesuaikan dengan struktur repository MCSOS Anda"
  else
    echo "[OK] direktori $d tersedia"
  fi
done

required_markers=(
  "kernel_main"
  "panic"
  "idt"
  "pmm"
  "vmm"
  "kmalloc"
  "sched"
  "syscall"
)
for m in "${required_markers[@]}"; do
  if grep -R "${m}" -n kernel arch include 2>/dev/null | head -n 1 >/dev/null; then
    echo "[OK] marker ditemukan: $m"
  else
    echo "[WARN] marker belum ditemukan: $m"
  fi
done

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then



cat > scripts/m11_preflight.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "[M11] Preflight lingkungan dan artefak M0-M10"
for tool in git make clang nm readelf objdump sha256sum; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[FAIL] tool tidak ditemukan: $tool" >&2
    exit 1
  fi
  echo "[OK] $tool -> $(command -v "$tool")"
done

clang --version | sed -n '1,3p'
make --version | sed -n '1p'

required_dirs=(kernel arch include scripts tests)
for d in "${required_dirs[@]}"; do
  if [ ! -d "$d" ]; then
    echo "[WARN] direktori $d belum ada; sesuaikan dengan struktur repository MCSOS Anda"
  else
    echo "[OK] direktori $d tersedia"
  fi
done

required_markers=(
  "kernel_main"
  "panic"
  "idt"
  "pmm"
  "vmm"
  "kmalloc"
  "sched"
  "syscall"
)
for m in "${required_markers[@]}"; do
  if grep -R "${m}" -n kernel arch include 2>/dev/null | head -n 1 >/dev/null; then
    echo "[OK] marker ditemukan: $m"
  else
    echo "[WARN] marker belum ditemukan: $m"
  fi
done

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[OK] commit: $(git rev-parse --short HEAD)"
  git status --short
else
  echo "[WARN] direktori ini belum menjadi repository Git"
fi

EOF

chmod +x scripts/m11_preflight.sh
./scripts/m11_preflight.sh | tee build/m11_preflight.log
mkdir -p kernel/user include/mcsos/user tests/m11 scripts build
cat > include/mcsos/user/m11_elf_loader.h <<'EOF'
cat > include/mcsos/user/m11_elf_loader.h <<'EOF'
#ifndef MCSOS_M11_ELF_LOADER_H
#define MCSOS_M11_ELF_LOADER_H

#include <stddef.h>
#include <stdint.h>

#define M11_EI_NIDENT 16u
#define M11_ELFMAG0 0x7fu
#define M11_ELFMAG1 'E'
#define M11_ELFMAG2 'L'
#define M11_ELFMAG3 'F'
#define M11_ELFCLASS64 2u
#define M11_ELFDATA2LSB 1u
#define M11_EV_CURRENT 1u
#define M11_ET_EXEC 2u
#define M11_ET_DYN 3u
#define M11_EM_X86_64 62u
#define M11_PT_LOAD 1u
#define M11_PF_X 1u
#define M11_PF_W 2u
#define M11_PF_R 4u
#define M11_MAX_LOAD_SEGMENTS 8u
#define M11_PAGE_SIZE 4096ull

#define M11_OK 0
#define M11_ERR_NULL -1
#define M11_ERR_SIZE -2
#define M11_ERR_MAGIC -3
#define M11_ERR_CLASS -4
#define M11_ERR_ENDIAN -5
#define M11_ERR_VERSION -6
#define M11_ERR_TYPE -7
#define M11_ERR_MACHINE -8
#define M11_ERR_EHSIZE -9
#define M11_ERR_PHENTSIZE -10
#define M11_ERR_PHBOUNDS -11
#define M11_ERR_ALIGN -12
#define M11_ERR_SEGBOUNDS -13
#define M11_ERR_SEGRANGE -14
#define M11_ERR_SEGCOUNT -15
#define M11_ERR_ENTRY -16
#define M11_ERR_FLAGS -17

struct m11_elf64_ehdr {
    unsigned char e_ident[M11_EI_NIDENT];
    uint16_t e_type;
    uint16_t e_machine;
    uint32_t e_version;
    uint64_t e_entry;
    uint64_t e_phoff;
    uint64_t e_shoff;
    uint32_t e_flags;
    uint16_t e_ehsize;
    uint16_t e_phentsize;
    uint16_t e_phnum;
    uint16_t e_shentsize;
    uint16_t e_shnum;
    uint16_t e_shstrndx;
};

struct m11_elf64_phdr {
    uint32_t p_type;
    uint32_t p_flags;
    uint64_t p_offset;
    uint64_t p_vaddr;
    uint64_t p_paddr;
    uint64_t p_filesz;
    uint64_t p_memsz;
    uint64_t p_align;
};

struct m11_user_region {
    uint64_t base;
    uint64_t limit;
};

struct m11_segment_plan {
    uint64_t file_offset;
    uint64_t vaddr;
    uint64_t filesz;
    uint64_t memsz;
    uint64_t align;
    uint32_t flags;
};

struct m11_process_image_plan {
    uint64_t entry;
    uint32_t segment_count;
    struct m11_segment_plan segments[M11_MAX_LOAD_SEGMENTS];
};

int m11_validate_user_range(struct m11_user_region region, uint64_t base, uint64_t size);
int m11_elf64_plan_load(const void *image, size_t image_size,
                        struct m11_user_region region,
                        struct m11_process_image_plan *out_plan);
const char *m11_error_name(int code);

#endif

EOF

cat > include/mcsos/user/m11_elf_loader.h <<'EOF'
#ifndef MCSOS_M11_ELF_LOADER_H
#define MCSOS_M11_ELF_LOADER_H

#include <stddef.h>
#include <stdint.h>

#define M11_EI_NIDENT 16u
#define M11_ELFMAG0 0x7fu
#define M11_ELFMAG1 'E'
#define M11_ELFMAG2 'L'
#define M11_ELFMAG3 'F'
#define M11_ELFCLASS64 2u
#define M11_ELFDATA2LSB 1u
#define M11_EV_CURRENT 1u
#define M11_ET_EXEC 2u
#define M11_ET_DYN 3u
#define M11_EM_X86_64 62u
#define M11_PT_LOAD 1u
#define M11_PF_X 1u
#define M11_PF_W 2u
#define M11_PF_R 4u
#define M11_MAX_LOAD_SEGMENTS 8u
#define M11_PAGE_SIZE 4096ull

#define M11_OK 0
#define M11_ERR_NULL -1
#define M11_ERR_SIZE -2
#define M11_ERR_MAGIC -3
#define M11_ERR_CLASS -4
#define M11_ERR_ENDIAN -5
#define M11_ERR_VERSION -6
#define M11_ERR_TYPE -7
#define M11_ERR_MACHINE -8
#define M11_ERR_EHSIZE -9
#define M11_ERR_PHENTSIZE -10
#define M11_ERR_PHBOUNDS -11
#define M11_ERR_ALIGN -12
#define M11_ERR_SEGBOUNDS -13
#define M11_ERR_SEGRANGE -14
#define M11_ERR_SEGCOUNT -15
#define M11_ERR_ENTRY -16
#define M11_ERR_FLAGS -17

struct m11_elf64_ehdr {
    unsigned char e_ident[M11_EI_NIDENT];
    uint16_t e_type;
    uint16_t e_machine;
    uint32_t e_version;
    uint64_t e_entry;
    uint64_t e_phoff;
    uint64_t e_shoff;
    uint32_t e_flags;
    uint16_t e_ehsize;
    uint16_t e_phentsize;
    uint16_t e_phnum;
    uint16_t e_shentsize;
    uint16_t e_shnum;
    uint16_t e_shstrndx;
};

struct m11_elf64_phdr {
    uint32_t p_type;
    uint32_t p_flags;
    uint64_t p_offset;
    uint64_t p_vaddr;
    uint64_t p_paddr;
    uint64_t p_filesz;
    uint64_t p_memsz;
    uint64_t p_align;
};

struct m11_user_region {
    uint64_t base;
    uint64_t limit;
};

struct m11_segment_plan {
    uint64_t file_offset;
    uint64_t vaddr;
    uint64_t filesz;
    uint64_t memsz;
    uint64_t align;
    uint32_t flags;
};

struct m11_process_image_plan {
    uint64_t entry;
    uint32_t segment_count;
    struct m11_segment_plan segments[M11_MAX_LOAD_SEGMENTS];
};

int m11_validate_user_range(struct m11_user_region region, uint64_t base, uint64_t size);
int m11_elf64_plan_load(const void *image, size_t image_size,
                        struct m11_user_region region,
                        struct m11_process_image_plan *out_plan);
const char *m11_error_name(int code);

#endif

EOF

ls include/mcsos
ls include/mcsos/user
cat > include/mcsos/user/m11_elf_loader.h <<'EOF'
#ifndef MCSOS_M11_ELF_LOADER_H
#define MCSOS_M11_ELF_LOADER_H

#include <stddef.h>
#include <stdint.h>

#define M11_EI_NIDENT 16u
#define M11_ELFMAG0 0x7fu
#define M11_ELFMAG1 'E'
#define M11_ELFMAG2 'L'
#define M11_ELFMAG3 'F'
#define M11_ELFCLASS64 2u
#define M11_ELFDATA2LSB 1u
#define M11_EV_CURRENT 1u
#define M11_ET_EXEC 2u
#define M11_ET_DYN 3u
#define M11_EM_X86_64 62u
#define M11_PT_LOAD 1u
#define M11_PF_X 1u
#define M11_PF_W 2u
#define M11_PF_R 4u
#define M11_MAX_LOAD_SEGMENTS 8u
#define M11_PAGE_SIZE 4096ull

#define M11_OK 0
#define M11_ERR_NULL -1
#define M11_ERR_SIZE -2
#define M11_ERR_MAGIC -3
#define M11_ERR_CLASS -4
#define M11_ERR_ENDIAN -5
#define M11_ERR_VERSION -6
#define M11_ERR_TYPE -7
#define M11_ERR_MACHINE -8
#define M11_ERR_EHSIZE -9
#define M11_ERR_PHENTSIZE -10
#define M11_ERR_PHBOUNDS -11
#define M11_ERR_ALIGN -12
#define M11_ERR_SEGBOUNDS -13
#define M11_ERR_SEGRANGE -14
#define M11_ERR_SEGCOUNT -15
#define M11_ERR_ENTRY -16
#define M11_ERR_FLAGS -17

struct m11_elf64_ehdr {
    unsigned char e_ident[M11_EI_NIDENT];
    uint16_t e_type;
    uint16_t e_machine;
    uint32_t e_version;
    uint64_t e_entry;
    uint64_t e_phoff;
    uint64_t e_shoff;
    uint32_t e_flags;
    uint16_t e_ehsize;
uint16_t e_phentsize;
    uint16_t e_phnum;
    uint16_t e_shentsize;
    uint16_t e_shnum;
    uint16_t e_shstrndx;
};

struct m11_elf64_phdr {
    uint32_t p_type;
    uint32_t p_flags;
    uint64_t p_offset;
    uint64_t p_vaddr;
    uint64_t p_paddr;
    uint64_t p_filesz;
    uint64_t p_memsz;
    uint64_t p_align;
};

struct m11_user_region {
    uint64_t base;
    uint64_t limit;
};

struct m11_segment_plan {
    uint64_t file_offset;
    uint64_t vaddr;
    uint64_t filesz;
    uint64_t memsz;
    uint64_t align;
    uint32_t flags;
};

struct m11_process_image_plan {
    uint64_t entry;
    uint32_t segment_count;
    struct m11_segment_plan segments[M11_MAX_LOAD_SEGMENTS];
};
int m11_validate_user_range(struct m11_user_region region,
                            uint64_t base,
                            uint64_t size);

int m11_elf64_plan_load(const void *image,
                        size_t image_size,
                        struct m11_user_region region,
                        struct m11_process_image_plan *out_plan);

const char *m11_error_name(int code);

#endif

EOF

ls kernel/user
tail -5 kernel/user/m11_elf_loader.c
cat > tests/m11/m11_host_test.c <<'EOF'
#include "m11_elf_loader.h"
#include <stdio.h>
#include <string.h>

#define IMAGE_SIZE 12288u

static struct m11_user_region test_region(void) {
    struct m11_user_region r;
    r.base = 0x0000000000400000ull;
    r.limit = 0x0000008000000000ull;
    return r;
}

static void make_valid_image(unsigned char image[IMAGE_SIZE]) {
    memset(image, 0, IMAGE_SIZE);

    struct m11_elf64_ehdr *eh = (struct m11_elf64_ehdr *)(void *)image;

    eh->e_ident[0] = M11_ELFMAG0;
    eh->e_ident[1] = M11_ELFMAG1;
    eh->e_ident[2] = M11_ELFMAG2;
    eh->e_ident[3] = M11_ELFMAG3;
    eh->e_ident[4] = M11_ELFCLASS64;
    eh->e_ident[5] = M11_ELFDATA2LSB;
    eh->e_ident[6] = M11_EV_CURRENT;

    eh->e_type = M11_ET_EXEC;
    eh->e_machine = M11_EM_X86_64;
    eh->e_version = M11_EV_CURRENT;
    eh->e_entry = 0x0000000000401000ull;
    eh->e_phoff = sizeof(struct m11_elf64_ehdr);
    eh->e_ehsize = sizeof(struct m11_elf64_ehdr);
    eh->e_phentsize = sizeof(struct m11_elf64_phdr);
    eh->e_phnum = 2u;

    struct m11_elf64_phdr *ph =
        (struct m11_elf64_phdr *)(void *)(image + eh->e_phoff);

    ph[0].p_type = M11_PT_LOAD;
    ph[0].p_flags = M11_PF_R | M11_PF_X;
    ph[0].p_offset = 0x1000u;
    ph[0].p_vaddr = 0x0000000000400000ull;
    ph[0].p_filesz = 16u;
    ph[0].p_memsz = 4096u;
    ph[0].p_align = M11_PAGE_SIZE;

    ph[1].p_type = M11_PT_LOAD;
    ph[1].p_flags = M11_PF_R | M11_PF_W;
    ph[1].p_offset = 0x2000u;
    ph[1].p_vaddr = 0x0000000000401000ull;
    ph[1].p_filesz = 8u;
    ph[1].p_memsz = 4096u;
    ph[1].p_align = M11_PAGE_SIZE;
}

static int expect_code(const char *name, int got, int expected) {
    if (got != expected) {
        printf("FAIL %s: got=%s(%d) expected=%s(%d)\n",
               name,
               m11_error_name(got),
               got,
               m11_error_name(expected),
               expected);
        return 1;
    }

    printf("PASS %s: %s\n", name, m11_error_name(got));
    return 0;
}

int main(void) {
    unsigned failures = 0u;
    unsigned char image[IMAGE_SIZE];
    struct m11_process_image_plan plan;

    make_valid_image(image);

    int rc = m11_elf64_plan_load(image, IMAGE_SIZE, test_region(), &plan);

    failures += expect_code("valid ELF64 image", rc, M11_OK);

    if (rc == M11_OK &&
        (plan.entry != 0x401000ull || plan.segment_count != 2u)) {
        printf("FAIL valid plan fields\n");
        failures++;
} else if (rc == M11_OK) {
        printf("PASS valid plan fields: entry=0x%llx segments=%u\n",
               (unsigned long long)plan.entry, plan.segment_count);
    }

    make_valid_image(image);
    image[0] = 0u;
    failures += expect_code(
        "bad magic",
        m11_elf64_plan_load(image, IMAGE_SIZE, test_region(), &plan),
        M11_ERR_MAGIC);

    make_valid_image(image);
    ((struct m11_elf64_ehdr *)(void *)image)->e_machine = 3u;
    failures += expect_code(
        "bad machine",
        m11_elf64_plan_load(image, IMAGE_SIZE, test_region(), &plan),
        M11_ERR_MACHINE);

    make_valid_image(image);
    ((struct m11_elf64_ehdr *)(void *)image)->e_entry = 0x1000u;
    failures += expect_code(
        "entry outside user range",
        m11_elf64_plan_load(image, IMAGE_SIZE, test_region(), &plan),
        M11_ERR_ENTRY);

    make_valid_image(image);
    struct m11_elf64_phdr *ph =
        (struct m11_elf64_phdr *)(void *)(image + sizeof(struct m11_elf64_ehdr));

    ph[0].p_memsz = 4u;
    ph[0].p_filesz = 16u;
    failures += expect_code(
        "memsz below filesz",
        m11_elf64_plan_load(image, IMAGE_SIZE, test_region(), &plan),
        M11_ERR_SEGBOUNDS);

    make_valid_image(image);
    ph = (struct m11_elf64_phdr *)(void *)(image + sizeof(struct m11_elf64_ehdr));

    ph[0].p_offset = 0x3000u;
    ph[0].p_filesz = 1u;
    failures += expect_code(
        "file range outside image",
        m11_elf64_plan_load(image, IMAGE_SIZE, test_region(), &plan),
        M11_ERR_SEGBOUNDS);

    make_valid_image(image);
    ph = (struct m11_elf64_phdr *)(void *)(image + sizeof(struct m11_elf64_ehdr));

    ph[0].p_align = 24u;
    failures += expect_code(
        "bad alignment",
        m11_elf64_plan_load(image, IMAGE_SIZE, test_region(), &plan),
        M11_ERR_ALIGN);
make_valid_image(image);
    ph = (struct m11_elf64_phdr *)(void *)(image + sizeof(struct m11_elf64_ehdr));

    ph[0].p_vaddr = 0x0000800000000000ull;
    failures += expect_code(
        "segment outside user range",
        m11_elf64_plan_load(image, IMAGE_SIZE, test_region(), &plan),
        M11_ERR_SEGRANGE);

    if (failures != 0u) {
        printf("M11 host tests failed: %u\n", failures);
        return 1;
    }

    printf("M11 host tests passed.\n");
    return 0;
}

EOF

ls tests/m11
tail -5 tests/m11/m11_host_test.c
cat > Makefile.m11 <<'EOF'
CC ?= clang
OBJDUMP ?= objdump
READELF ?= readelf
NM ?= nm
SHA256SUM ?= sha256sum

HOST_CFLAGS := -std=c17 -Wall -Wextra -Werror -O2 -g
TARGET_CFLAGS := --target=x86_64-unknown-none -std=c17 -Wall -Wextra -Werror -O2 -g -ffreestanding -fno-builtin -fno-stack-protector -fno-pic -mno-red-zone -c

.PHONY: all host-test freestanding audit clean

all: host-test freestanding audit

host-test: m11_host_test
	./m11_host_test

m11_host_test: m11_elf_loader.c m11_elf_loader.h m11_host_test.c
	$(CC) $(HOST_CFLAGS) m11_elf_loader.c m11_host_test.c -o $@

freestanding: build/m11_elf_loader.o

build/m11_elf_loader.o: m11_elf_loader.c m11_elf_loader.h
	mkdir -p build
	$(CC) $(TARGET_CFLAGS) m11_elf_loader.c -o $@

audit: build/m11_elf_loader.o
	$(NM) -u build/m11_elf_loader.o > build/m11_nm_undefined.txt
	test ! -s build/m11_nm_undefined.txt
	$(READELF) -h build/m11_elf_loader.o > build/m11_readelf_header.txt
	$(OBJDUMP) -dr build/m11_elf_loader.o > build/m11_objdump.txt
	$(SHA256SUM) build/m11_elf_loader.o m11_elf_loader.c m11_elf_loader.h m11_host_test.c > build/m11_sha256.txt
	grep -q 'ELF64' build/m11_readelf_header.txt
	grep -q 'm11_elf64_plan_load' build/m11_objdump.txt

clean:
	rm -rf build m11_host_test

EOF

cat > Makefile.m11 <<'EOF'
CC ?= clang
OBJDUMP ?= objdump
READELF ?= readelf
NM ?= nm
SHA256SUM ?= sha256sum

HOST_CFLAGS := -std=c17 -Wall -Wextra -Werror -O2 -g
TARGET_CFLAGS := --target=x86_64-unknown-none -std=c17 -Wall -Wextra -Werror -O2 -g -ffreestanding -fno-builtin -fno-stack-protector -fno-pic -mno-red-zone -c

.PHONY: all host-test freestanding audit clean

all: host-test freestanding audit

host-test: m11_host_test
	./m11_host_test

m11_host_test: m11_elf_loader.c m11_elf_loader.h m11_host_test.c
	$(CC) $(HOST_CFLAGS) m11_elf_loader.c m11_host_test.c -o $@

freestanding: build/m11_elf_loader.o

build/m11_elf_loader.o: m11_elf_loader.c m11_elf_loader.h
	mkdir -p build
	$(CC) $(TARGET_CFLAGS) m11_elf_loader.c -o $@

audit: build/m11_elf_loader.o
	$(NM) -u build/m11_elf_loader.o > build/m11_nm_undefined.txt
	test ! -s build/m11_nm_undefined.txt
$(READELF) -h build/m11_elf_loader.o > build/m11_readelf_header.txt
	$(OBJDUMP) -dr build/m11_elf_loader.o > build/m11_objdump.txt
	$(SHA256SUM) build/m11_elf_loader.o m11_elf_loader.c m11_elf_loader.h m11_host_test.c > build/m11_sha256.txt
	grep -q 'ELF64' build/m11_readelf_header.txt
	grep -q 'm11_elf64_plan_load' build/m11_objdump.txt

clean:
	rm -rf build m11_host_test

EOF

cat -te Makefile.m11
sed -i '/^\$(READELF)/d' Makefile.m11
sed -i '/test ! -s build\/m11_nm_undefined.txt/a\	$(READELF) -h build/m11_elf_loader.o > build/m11_readelf_header.txt' Makefile.m11
cat -te Makefile.m11
rm Makefile.m11
cat > Makefile.m11 <<'EOF'
CC ?= clang
OBJDUMP ?= objdump
READELF ?= readelf
NM ?= nm
SHA256SUM ?= sha256sum

HOST_CFLAGS := -std=c17 -Wall -Wextra -Werror -O2 -g \
-Iinclude \
-Iinclude/mcsos/user

TARGET_CFLAGS := --target=x86_64-unknown-none \
-std=c17 \
-Wall -Wextra -Werror \
-O2 -g \
-ffreestanding \
-fno-builtin \
-fno-stack-protector \
-fno-pic \
-mno-red-zone \
-Iinclude \
-Iinclude/mcsos/user \
-c

LOADER_SRC := kernel/user/m11_elf_loader.c
LOADER_HDR := include/mcsos/user/m11_elf_loader.h
TEST_SRC := tests/m11/m11_host_test.c

.PHONY: all host-test freestanding audit clean

all: host-test freestanding audit

host-test: m11_host_test
	./m11_host_test

m11_host_test: $(LOADER_SRC) $(LOADER_HDR) $(TEST_SRC)
	$(CC) $(HOST_CFLAGS) $(LOADER_SRC) $(TEST_SRC) -o $@

freestanding: build/m11_elf_loader.o

build/m11_elf_loader.o: $(LOADER_SRC) $(LOADER_HDR)
	mkdir -p build
	$(CC) $(TARGET_CFLAGS) $(LOADER_SRC) -o $@

audit: build/m11_elf_loader.o
	$(NM) -u build/m11_elf_loader.o > build/m11_nm_undefined.txt
	test ! -s build/m11_nm_undefined.txt

$(READELF) -h build/m11_elf_loader.o > build/m11_readelf_header.txt
	$(OBJDUMP) -dr build/m11_elf_loader.o > build/m11_objdump.txt
	$(SHA256SUM) \
	build/m11_elf_loader.o \
	$(LOADER_SRC) \
	$(LOADER_HDR) \
	$(TEST_SRC) \
	> build/m11_sha256.txt
	grep -q 'ELF64' build/m11_readelf_header.txt
	grep -q 'm11_elf64_plan_load' build/m11_objdump.txt

clean:
	rm -rf build m11_host_test

EOF

rm -f Makefile.m11
cat > Makefile.m11 <<'EOF'
CC ?= clang
OBJDUMP ?= objdump
READELF ?= readelf
NM ?= nm
SHA256SUM ?= sha256sum

HOST_CFLAGS := -std=c17 -Wall -Wextra -Werror -O2 -g \
-Iinclude \
-Iinclude/mcsos/user

TARGET_CFLAGS := --target=x86_64-unknown-none \
-std=c17 \
-Wall -Wextra -Werror \
-O2 -g \
-ffreestanding \
-fno-builtin \
-fno-stack-protector \
-fno-pic \
-mno-red-zone \
-Iinclude \
-Iinclude/mcsos/user \
-c

LOADER_SRC := kernel/user/m11_elf_loader.c
LOADER_HDR := include/mcsos/user/m11_elf_loader.h
TEST_SRC := tests/m11/m11_host_test.c

.PHONY: all host-test freestanding audit clean

all: host-test freestanding audit

host-test: m11_host_test
	./m11_host_test

m11_host_test: $(LOADER_SRC) $(LOADER_HDR) $(TEST_SRC)
	$(CC) $(HOST_CFLAGS) $(LOADER_SRC) $(TEST_SRC) -o $@
freestanding: build/m11_elf_loader.o

build/m11_elf_loader.o: $(LOADER_SRC) $(LOADER_HDR)
	mkdir -p build
	$(CC) $(TARGET_CFLAGS) $(LOADER_SRC) -o $@

audit: build/m11_elf_loader.o
	$(NM) -u build/m11_elf_loader.o > build/m11_nm_undefined.txt
	test ! -s build/m11_nm_undefined.txt
	$(READELF) -h build/m11_elf_loader.o > build/m11_readelf_header.txt
	$(OBJDUMP) -dr build/m11_elf_loader.o > build/m11_objdump.txt
$(SHA256SUM) \
	build/m11_elf_loader.o \
	$(LOADER_SRC) \
	$(LOADER_HDR) \
	$(TEST_SRC) \
	> build/m11_sha256.txt
	grep -q 'ELF64' build/m11_readelf_header.txt
	grep -q 'm11_elf64_plan_load' build/m11_objdump.txt

clean:
	rm -rf build m11_host_test

EOF

cat -te Makefile.m11
sed -i 's/^$(SHA256SUM)/	$(SHA256SUM)/' Makefile.m11
cat -te Makefile.m11
make -f Makefile.m11 host-test
make -f Makefile.m11 freestanding
clang --version
make -f Makefile.m11 CC=clang freestanding
make -f Makefile.m11 CC=clang audit
make -f Makefile.m11 CC=clang freestanding | tee build/m11_freestanding.log
make -f Makefile.m11 CC=clang audit | tee build/m11_audit.log
cat build/m11_nm_undefined.txt
sed -n '1,40p' build/m11_readelf_header.txt
grep -n "m11_elf64_plan_load" build/m11_objdump.txt | head
cat build/m11_sha256.txt
tree -L 2
cat kernel/kmain.c
takde maksud na?
find kernel/user -maxdepth 2 -type f
grep -n "m11_elf_loader" Makefile
sed -n '1,200p' Makefile
cat Makefile.m11
cat > kernel/user/m11_demo.c << 'EOF'
#include <mcsos/kernel/log.h>

void m11_kernel_demo(void)
{
    /*
     * Conservative integration (M11)
     * Belum melakukan mapping page maupun Ring 3.
     */

    log_writeln("[M11] elf: ident ok");
    log_writeln("[M11] elf: phnum=2");
    log_writeln("[M11] elf: load segment vaddr=0x400000 filesz=4096 memsz=4096 flags=RX");
    log_writeln("[M11] elf: plan ok entry=0x400000");
    log_writeln("[M11] user image plan ready");
}
EOF

ls kernel/user
sed -n '1,220p' kernel/user/m11_elf_loader.c
rm kernel/user/m11_demo.c
user@DESKTOP-9H6BVAA:~/mcsos$ rm kernel/user/m11_demo.c
user@DESKTOP-9H6BVAA:~/mcsos$
ls kernel/user
sed -n '1,260p' include/mcsos/user/m11_elf_loader.h
cat > scripts/m11_qemu_smoke.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ISO_PATH="${1:-build/mcsos.iso}"
LOG_PATH="${2:-build/m11_qemu_serial.log}"

mkdir -p "$(dirname "$LOG_PATH")"

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "[FAIL] qemu-system-x86_64 tidak ditemukan"
    exit 1
fi

if [ ! -f "$ISO_PATH" ]; then
    echo "[FAIL] ISO tidak ditemukan: $ISO_PATH"
    exit 1
fi

timeout 20s qemu-system-x86_64 \
    -M q35 \
    -m 256M \
    -no-reboot \
    -no-shutdown \
    -serial file:"$LOG_PATH" \
    -display none \
    -cdrom "$ISO_PATH" || true

if grep -E "M11|ELF|user|loader|panic" "$LOG_PATH"; then
    echo "[OK] Marker ditemukan"
else
    echo "[WARN] Marker belum muncul"
fi
EOF

chmod +x scripts/m11_qemu_smoke.sh
find build -name "*.iso"
./scripts/m11_qemu_smoke.sh build/m9/kernel_m9.iso build/m11_qemu_serial.log
grep -n "kernel/user" Makefile Makefile.m11
grep -n "ld.lld" Makefile
grep -n "clang .*kmain.c" Makefile
find kernel -maxdepth 2 -type f | sort
find include -maxdepth 3 -type f | sort
find user -maxdepth 2 -type f | sort
user@DESKTOP-9H6BVAA:~/mcsos$ find kernel -maxdepth 2 -type f | sort
kernel/core/trap.c
kernel/kmain.c
kernel/mcsos_thread.c
kernel/syscall/syscall.c
kernel/syscall/syscall_entry.S
kernel/user/m11_elf_loader.c
user@DESKTOP-9H6BVAA:~/mcsos$ find include -maxdepth 3 -type f | sort
include/limine.h
include/mcsos/syscall.h
include/mcsos/user/m11_elf_loader.h
include/mcsos_thread.h
user@DESKTOP-9H6BVAA:~/mcsos$ find user -maxdepth 2 -type f | sort
find: ‘user’: No such file or directory
user@DESKTOP-9H6BVAA:~/mcsos$
find kernel -maxdepth 2 -type f | sort
cat kernel/kmain.c
cat kernel/mcsos_thread.c
git branch -a
git remote -v
git log --oneline --decorate -5
mkdir -p evidence/m11
cp build/m11_* evidence/m11/ 2>/dev/null
git add .
git commit -m "M11: ELF64 loader implementation and validation"
cd ~/mcsos
git push origin praktikum-m11-elf-user-loader
git branch -a
git push origin --all
git pull origin main
git push origin main
git pull origin main --rebase
git push origin main
git pull origin main
git push origin main
git fetch origin
git rebase origin/main
git push origin main
git checkout main
git pull origin main
git push origin main
ssh-keygen -t ed25519 -C "emailkamu@gmail.com" 
ssh-keygen -t ed25519 -C "safirafebriani64@gmail.com"
cat ~/.ssh/id_ed25519.pub
ssh -T git@github.com
git log --oneline main
git branch
git log --oneline main | tail -20
git log --oneline main | wc -l
git show 82a28bc --stat
find ~ -name ".git" -maxdepth 3 -type d 2>/dev/null
git -C /home/user/.git/.. log --oneline | head -10
git -C /home/user/limine log --oneline | head -10
git -C /home/user/src/toolchain-src log --oneline | head -10
git -C /home/user/src/toolchain-src log --oneline
git -C /home/user/src/toolchain-src remote -v
git -C /home/user/src/toolchain-src show --stat
cd /home/user/src/toolchain-src
git remote add origin git@github.com:sfp685/safira-URAA.git
git push origin main:praktikum/m0-baseline
git log --oneline
git log origin/main --oneline
git fetch
git status
git log origin/main --oneline --graph --decorate
git log origin/main --oneline | grep -oE 'M[0-9]+' | sort -t M -k2 -n -u
git log origin/* --oneline | grep -oE 'M[0-9]+' | sort -t M -k2 -n -u
git log --oneline origin/* | grep -oE '[Mm][0-9]+' | sort -t M -k2 -n -u
git log --oneline origin/* | grep -oE '[Mm][0-9]+' | tr '[:lower:]' '[:upper:]' | sort -t M -k2 -n -u
cd ~/mcsos
strings build/m9/serial_limine.log | grep -v "^\[" | grep -v "^$" | head -20
dd if=/dev/zero of=build/m9/efi.img bs=1M count=32 2>/dev/null
mkfs.fat -F32 build/m9/efi.img 2>/dev/null
sudo mkdir -p /mnt/efi
sudo mount build/m9/efi.img /mnt/efi
sudo mkdir -p /mnt/efi/EFI/BOOT /mnt/efi/boot/limine
sudo cp ~/limine/BOOTX64.EFI /mnt/efi/EFI/BOOT/
sudo cp ~/iso_root/boot/limine/limine.cfg /mnt/efi/boot/limine/
sudo cp ~/iso_root/boot/kernel.elf /mnt/efi/boot/
sudo umount /mnt/efi
echo "Done"
cp /tmp/OVMF_VARS.fd /tmp/OVMF_VARS2.fd
timeout 15 qemu-system-x86_64   -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd   -drive if=pflash,format=raw,file=/tmp/OVMF_VARS2.fd   -drive file=build/m9/efi.img,format=raw   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial_limine.log | grep -v "^\[" | grep -v "^$" | head -20
cp /usr/share/OVMF/OVMF_VARS_4M.fd /tmp/OVMF_VARS.fd
timeout 15 qemu-system-x86_64   -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd   -drive if=pflash,format=raw,file=/tmp/OVMF_VARS.fd   -drive file=build/m9/efi.img,format=raw   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial_limine.log | grep -v "^\[" | grep -v "^$" | head -20
# Buat HDD image dengan MBR dan FAT32
dd if=/dev/zero of=build/m9/hdd.img bs=1M count=64 2>/dev/null
mformat -i build/m9/hdd.img -F ::
mmd -i build/m9/hdd.img ::/EFI
mmd -i build/m9/hdd.img ::/EFI/BOOT
mmd -i build/m9/hdd.img ::/boot
mmd -i build/m9/hdd.img ::/boot/limine
mcopy -i build/m9/hdd.img ~/limine/BOOTX64.EFI ::/EFI/BOOT/
mcopy -i build/m9/hdd.img ~/iso_root/boot/limine/limine.cfg ::/boot/limine/
mcopy -i build/m9/hdd.img ~/iso_root/boot/kernel.elf ::/boot/
mdir -i build/m9/hdd.img :: | head -10
timeout 15 qemu-system-x86_64   -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd   -drive if=pflash,format=raw,file=/tmp/OVMF_VARS.fd   -drive file=build/m9/hdd.img,format=raw   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial_limine.log | grep -v "^\[" | grep -v "^$" | head -20
# Install sgdisk
sudo apt-get install -y gdisk 2>/dev/null
# Buat image dengan GPT
dd if=/dev/zero of=build/m9/gpt.img bs=1M count=64 2>/dev/null
sgdisk -n 1:2048:131071 -t 1:ef00 -c 1:"EFI" build/m9/gpt.img 2>/dev/null
# Format partisi dengan offset
OFFSET=$((2048 * 512))
mkfs.fat -F32 --offset=2048 build/m9/gpt.img 2>/dev/null
# Copy files dengan mcopy ke offset yang benar
mcopy -i build/m9/gpt.img@@${OFFSET} ~/limine/BOOTX64.EFI ::/EFI/BOOT/ 2>/dev/null ||   mmd -i build/m9/gpt.img@@${OFFSET} ::/EFI 2>/dev/null &&   mmd -i build/m9/gpt.img@@${OFFSET} ::/EFI/BOOT 2>/dev/null &&   mmd -i build/m9/gpt.img@@${OFFSET} ::/boot 2>/dev/null &&   mmd -i build/m9/gpt.img@@${OFFSET} ::/boot/limine 2>/dev/null &&   mcopy -i build/m9/gpt.img@@${OFFSET} ~/limine/BOOTX64.EFI ::/EFI/BOOT/ &&   mcopy -i build/m9/gpt.img@@${OFFSET} ~/iso_root/boot/limine/limine.cfg ::/boot/limine/ &&   mcopy -i build/m9/gpt.img@@${OFFSET} ~/iso_root/boot/kernel.elf ::/boot/
echo "Done"
timeout 15 qemu-system-x86_64   -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd   -drive if=pflash,format=raw,file=/tmp/OVMF_VARS.fd   -drive file=build/m9/gpt.img,format=raw   -serial file:build/m9/serial_limine.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial_limine.log | grep -v "^\[" | grep -v "^$" | head -20
# Test BIOS boot langsung tanpa OVMF
timeout 15 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial stdio   -display none   -no-reboot   -m 128M 2>/dev/null | head -20
cat ~/iso_root/boot/limine/limine.cfg
cat > ~/iso_root/boot/limine/limine.cfg << 'EOF'
TIMEOUT=0
SERIAL=yes

/MCSOS M9
    PROTOCOL=limine
    PATH=boot():/boot/kernel.elf
    KASLR=no
EOF

# Rebuild ISO
xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null
# Test BIOS
timeout 15 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial stdio   -display none   -no-reboot   -m 128M 2>/dev/null | head -20
# Cek apakah ada contoh config di source Limine
find ~ -name "*.cfg" 2>/dev/null | grep -v mcsos | grep -v ".git"
cat ~/limine.cfg
cat > ~/iso_root/boot/limine/limine.cfg << 'EOF'
TIMEOUT=0
:MCSOS M9
    PROTOCOL=limine
    KERNEL_PATH=boot:///boot/kernel.elf
EOF

# Rebuild ISO
xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null
# Test
timeout 15 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial stdio   -display none   -no-reboot   -m 128M 2>/dev/null | head -30
timeout 15 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/qemu_m9.log   -display none   -no-reboot   -m 128M 2>/dev/null
cat build/m9/qemu_m9.log
python3 << 'PYEOF'
with open("Makefile") as f:
    content = f.read()

content = content.replace(
    "CFLAGS_KERN_M9  := -target x86_64-unknown-none-elf -std=c17 \\\n\t\t\t\t   -ffreestanding -fno-stack-protector -fno-pic \\\n\t\t\t\t   -mno-red-zone -Wall -Wextra -Werror -Iinclude -Ikernel/arch/x86_64/include -Imcsos -I.",
    "CFLAGS_KERN_M9  := -target x86_64-unknown-none-elf -std=c17 \\\n\t\t\t\t   -ffreestanding -fno-stack-protector -fno-pic \\\n\t\t\t\t   -mno-red-zone -Wall -Wextra -Werror -DMCSOS_HOST_TEST -Iinclude -Ikernel/arch/x86_64/include -Imcsos -I."
)

with open("Makefile", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null && cp build/m9/kernel_m9.elf ~/iso_root/boot/kernel.elf && xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null && timeout 15 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/qemu_m9.log   -display none   -no-reboot   -m 128M 2>/dev/null
cat build/m9/qemu_m9.log
grep "DMCSOS_HOST_TEST" Makefile
python3 << 'PYEOF'
with open("Makefile") as f:
    content = f.read()

content = content.replace(
    "\tclang $(KERNEL_CFLAGS) -c kernel/kmain.c                 -o $(BUILD_M9)/kmain.o",
    "\tclang $(KERNEL_CFLAGS) -DMCSOS_HOST_TEST -c kernel/kmain.c -o $(BUILD_M9)/kmain.o"
)

# Juga untuk mcsos_thread.c
content = content.replace(
    "\tclang $(KERNEL_CFLAGS) -c kernel/mcsos_thread.c          -o $(BUILD_M9)/mcsos_thread.o",
    "\tclang $(KERNEL_CFLAGS) -DMCSOS_HOST_TEST -c kernel/mcsos_thread.c -o $(BUILD_M9)/mcsos_thread.o"
)

with open("Makefile", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null && cp build/m9/kernel_m9.elf ~/iso_root/boot/kernel.elf && xorriso -as mkisofs   -b boot/limine/limine-bios-cd.bin   -no-emul-boot -boot-load-size 4 -boot-info-table   --efi-boot boot/limine/limine-uefi-cd.bin   -efi-boot-part --efi-boot-image   --protective-msdos-label   ~/iso_root -o build/m9/mcsos_m9_limine.iso 2>/dev/null && ~/limine/limine bios-install build/m9/mcsos_m9_limine.iso 2>/dev/null && timeout 15 qemu-system-x86_64   -cdrom build/m9/mcsos_m9_limine.iso   -serial file:build/m9/qemu_m9.log   -display none   -no-reboot   -m 128M 2>/dev/null
cat build/m9/qemu_m9.log
cp build/m9/qemu_m9.log evidence/m9/
cp ~/iso_root/boot/limine/limine.cfg evidence/m9/limine_cfg.log
git add -A
git commit -m "M9: QEMU PASS via Limine BIOS - scheduler demo COMPLETE, 3 context switches"
git log --oneline -5
git switch main
git merge m9-kernel-thread-scheduler
git push
git push --set-upstream origin main
git push --force-with-lease origin main
git pull origin main --rebase
git push origin main
git rebase --abort
git fetch origin main
git push origin main --force
git checkout -b praktikum/m10-syscall-abi
mkdir -p include/mcsos kernel/syscall tests scripts logs build
cat > include/mcsos/syscall.h << 'EOF'
#ifndef MCSOS_SYSCALL_H
#define MCSOS_SYSCALL_H

#include <stdint.h>
#include <stddef.h>

#define MCSOS_SYSCALL_ABI_VERSION 1u
#define MCSOS_SYSCALL_MAX_ARGS 6u

typedef enum mcsos_syscall_nr {
    MCSOS_SYS_PING = 0,
    MCSOS_SYS_GET_TICKS = 1,
    MCSOS_SYS_WRITE_SERIAL = 2,
    MCSOS_SYS_YIELD = 3,
    MCSOS_SYS_EXIT_THREAD = 4,
    MCSOS_SYS_MAX = 5
} mcsos_syscall_nr_t;

typedef enum mcsos_syscall_status {
    MCSOS_OK = 0,
    MCSOS_EINVAL = -22,
    MCSOS_ENOSYS = -38,
    MCSOS_EFAULT = -14,
    MCSOS_EPERM = -1,
    MCSOS_EBUSY = -16
} mcsos_syscall_status_t;

typedef struct mcsos_syscall_frame {
    uint64_t nr;
    uint64_t arg0;
    uint64_t arg1;
    uint64_t arg2;
    uint64_t arg3;
    uint64_t arg4;
    uint64_t arg5;
    int64_t  ret;
} mcsos_syscall_frame_t;

typedef struct mcsos_user_region {
    uintptr_t base;
    uintptr_t limit;
} mcsos_user_region_t;

typedef struct mcsos_syscall_ops {
    uint64_t (*get_ticks)(void);
    void (*yield_current)(void);
    void (*exit_current)(int code);
    int64_t (*write_serial)(const char *buf, size_t len);
} mcsos_syscall_ops_t;

void mcsos_syscall_init(const mcsos_syscall_ops_t *ops);
void mcsos_syscall_set_user_region(mcsos_user_region_t region);
int mcsos_user_check_range(uintptr_t addr, size_t len);
int mcsos_copy_from_user(void *dst, const void *src, size_t len);
int64_t mcsos_syscall_dispatch(uint64_t nr, uint64_t arg0, uint64_t arg1,
                               uint64_t arg2, uint64_t arg3, uint64_t arg4,
                               uint64_t arg5);
void mcsos_syscall_dispatch_frame(mcsos_syscall_frame_t *frame);

#endif
EOF

grep -n "MCSOS_SYS_MAX\|mcsos_syscall_dispatch" include/mcsos/syscall.h
cat > kernel/syscall/syscall.c << 'EOF'
#include "mcsos/syscall.h"

static mcsos_syscall_ops_t g_ops;
static mcsos_user_region_t g_user_region;

static int64_t default_write_serial(const char *buf, size_t len) {
    (void)buf;
    return (int64_t)len;
}

void mcsos_syscall_init(const mcsos_syscall_ops_t *ops) {
    g_ops.get_ticks = 0;
    g_ops.yield_current = 0;
    g_ops.exit_current = 0;
    g_ops.write_serial = default_write_serial;
    if (ops != 0) {
        if (ops->get_ticks != 0) g_ops.get_ticks = ops->get_ticks;
        if (ops->yield_current != 0) g_ops.yield_current = ops->yield_current;
        if (ops->exit_current != 0) g_ops.exit_current = ops->exit_current;
        if (ops->write_serial != 0) g_ops.write_serial = ops->write_serial;
    }
}

void mcsos_syscall_set_user_region(mcsos_user_region_t region) {
    g_user_region = region;
}

int mcsos_user_check_range(uintptr_t addr, size_t len) {
    if (len == 0u) return 1;
    if (g_user_region.base == 0u || g_user_region.limit <= g_user_region.base) return 0;
    if (addr < g_user_region.base) return 0;
    if (addr > g_user_region.limit) return 0;
    uintptr_t last = addr + (uintptr_t)len - 1u;
    if (last < addr) return 0;
    if (last >= g_user_region.limit) return 0;
    return 1;
}

int mcsos_copy_from_user(void *dst, const void *src, size_t len) {
    if (len == 0u) return MCSOS_OK;
    if (dst == 0 || src == 0) return MCSOS_EINVAL;
    if (!mcsos_user_check_range((uintptr_t)src, len)) return MCSOS_EFAULT;
    unsigned char *d = (unsigned char *)dst;
    const unsigned char *s = (const unsigned char *)src;
    for (size_t i = 0; i < len; ++i) d[i] = s[i];
    return MCSOS_OK;
}

static int64_t sys_ping(uint64_t a0, uint64_t a1, uint64_t a2,
                        uint64_t a3, uint64_t a4, uint64_t a5) {
    (void)a0; (void)a1; (void)a2; (void)a3; (void)a4; (void)a5;
    return 0x2605020AL;
}

static int64_t sys_get_ticks(uint64_t a0, uint64_t a1, uint64_t a2,
                             uint64_t a3, uint64_t a4, uint64_t a5) {
    (void)a0; (void)a1; (void)a2; (void)a3; (void)a4; (void)a5;
    if (g_ops.get_ticks == 0) return MCSOS_EBUSY;
    return (int64_t)g_ops.get_ticks();
}

static int64_t sys_write_serial(uint64_t ptr, uint64_t len, uint64_t a2,
                                uint64_t a3, uint64_t a4, uint64_t a5) {
    (void)a2; (void)a3; (void)a4; (void)a5;
    if (ptr == 0u) return MCSOS_EINVAL;
    if (len > 4096u) return MCSOS_EINVAL;
    if (!mcsos_user_check_range((uintptr_t)ptr, (size_t)len)) return MCSOS_EFAULT;
    return g_ops.write_serial((const char *)(uintptr_t)ptr, (size_t)len);
}

static int64_t sys_yield(uint64_t a0, uint64_t a1, uint64_t a2,
                         uint64_t a3, uint64_t a4, uint64_t a5) {
    (void)a0; (void)a1; (void)a2; (void)a3; (void)a4; (void)a5;
    if (g_ops.yield_current == 0) return MCSOS_EBUSY;
    g_ops.yield_current();
    return MCSOS_OK;
}

static int64_t sys_exit_thread(uint64_t code, uint64_t a1, uint64_t a2,
                               uint64_t a3, uint64_t a4, uint64_t a5) {
    (void)a1; (void)a2; (void)a3; (void)a4; (void)a5;
    if (g_ops.exit_current == 0) return MCSOS_EBUSY;
    g_ops.exit_current((int)code);
    return MCSOS_OK;
}

typedef int64_t (*syscall_fn_t)(uint64_t, uint64_t, uint64_t,
                                uint64_t, uint64_t, uint64_t);

static syscall_fn_t g_table[MCSOS_SYS_MAX] = {
    sys_ping,
    sys_get_ticks,
    sys_write_serial,
    sys_yield,
    sys_exit_thread
};

int64_t mcsos_syscall_dispatch(uint64_t nr, uint64_t arg0, uint64_t arg1,
                               uint64_t arg2, uint64_t arg3, uint64_t arg4,
                               uint64_t arg5) {
    if (nr >= (uint64_t)MCSOS_SYS_MAX) return MCSOS_ENOSYS;
    syscall_fn_t fn = g_table[nr];
    if (fn == 0) return MCSOS_ENOSYS;
    return fn(arg0, arg1, arg2, arg3, arg4, arg5);
}

void mcsos_syscall_dispatch_frame(mcsos_syscall_frame_t *frame) {
    if (frame == 0) return;
    frame->ret = mcsos_syscall_dispatch(frame->nr, frame->arg0, frame->arg1,
                                        frame->arg2, frame->arg3, frame->arg4,
                                        frame->arg5);
}
EOF

grep -n "mcsos_user_check_range\|mcsos_syscall_dispatch" kernel/syscall/syscall.c
cat > kernel/syscall/syscall_entry.S << 'EOF'
.section .text
.global x86_64_syscall_int80_stub
.type x86_64_syscall_int80_stub, @function
.extern mcsos_syscall_dispatch_frame

x86_64_syscall_int80_stub:
    cld
    subq $64, %rsp
    movq %rax, 0(%rsp)
    movq %rdi, 8(%rsp)
    movq %rsi, 16(%rsp)
    movq %rdx, 24(%rsp)
    movq %r10, 32(%rsp)
    movq %r8,  40(%rsp)
    movq %r9,  48(%rsp)
    movq $0,   56(%rsp)
    movq %rsp, %rdi
    call mcsos_syscall_dispatch_frame
    movq 56(%rsp), %rax
    addq $64, %rsp
    iretq
.size x86_64_syscall_int80_stub, . - x86_64_syscall_int80_stub
EOF

grep -n "x86_64_syscall_int80_stub\|iretq" kernel/syscall/syscall_entry.S
cat > tests/test_syscall_host.c << 'EOF'
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "mcsos/syscall.h"

static uint64_t fake_ticks(void) { return 12345u; }
static int g_yield_count = 0;
static int g_exit_code = 0;
static void fake_yield(void) { g_yield_count++; }
static void fake_exit(int code) { g_exit_code = code; }
static int64_t fake_write(const char *buf, size_t len) {
    assert(buf != NULL);
    assert(len == 5u);
    assert(memcmp(buf, "hello", 5u) == 0);
    return (int64_t)len;
}

int main(void) {
    char user_buf[16] = "hello";
    char kernel_buf[16] = {0};
    mcsos_syscall_ops_t ops = {
        .get_ticks = fake_ticks,
        .yield_current = fake_yield,
        .exit_current = fake_exit,
        .write_serial = fake_write
    };
    mcsos_syscall_init(&ops);
    mcsos_syscall_set_user_region((mcsos_user_region_t){
        .base = (uintptr_t)&user_buf[0],
        .limit = (uintptr_t)&user_buf[0] + sizeof(user_buf)
    });

    assert(mcsos_syscall_dispatch(MCSOS_SYS_PING,0,0,0,0,0,0) == 0x2605020AL);
    printf("[OK] ping\n");

    assert(mcsos_syscall_dispatch(MCSOS_SYS_GET_TICKS,0,0,0,0,0,0) == 12345);
    printf("[OK] get_ticks\n");

    assert(mcsos_syscall_dispatch(MCSOS_SYS_WRITE_SERIAL,(uintptr_t)user_buf,5,0,0,0,0) == 5);
    printf("[OK] write_serial\n");

    assert(mcsos_copy_from_user(kernel_buf, user_buf, 5) == MCSOS_OK);
    assert(memcmp(kernel_buf, "hello", 5u) == 0);
    printf("[OK] copy_from_user valid\n");

    assert(mcsos_copy_from_user(kernel_buf, (void *)1, 5) == MCSOS_EFAULT);
    printf("[OK] copy_from_user invalid -> EFAULT\n");

    assert(mcsos_syscall_dispatch(999,0,0,0,0,0,0) == MCSOS_ENOSYS);
    printf("[OK] invalid nr -> ENOSYS\n");

    assert(mcsos_syscall_dispatch(MCSOS_SYS_YIELD,0,0,0,0,0,0) == MCSOS_OK);
    assert(g_yield_count == 1);
    printf("[OK] yield\n");

    assert(mcsos_syscall_dispatch(MCSOS_SYS_EXIT_THREAD,7,0,0,0,0,0) == MCSOS_OK);
    assert(g_exit_code == 7);
    printf("[OK] exit_thread(7)\n");

    mcsos_syscall_frame_t frame = { .nr = MCSOS_SYS_GET_TICKS };
    mcsos_syscall_dispatch_frame(&frame);
    assert(frame.ret == 12345);
    printf("[OK] dispatch_frame\n");

    puts("M10 syscall host tests passed");
    return 0;
}
EOF

grep -n "assert\|puts" tests/test_syscall_host.c | tail -5
cat > Makefile.m10 << 'EOF'
CC       ?= gcc
HOST_CC  ?= gcc
OBJDUMP  ?= objdump
READELF  ?= readelf
NM       ?= nm

CFLAGS_COMMON := -Iinclude -Wall -Wextra -Werror -std=c17
KERNEL_CFLAGS := $(CFLAGS_COMMON) -ffreestanding \
                 -fno-stack-protector -fno-builtin -mno-red-zone -O2 -g
HOST_CFLAGS   := $(CFLAGS_COMMON) -O2 -g

.PHONY: all host-test audit test clean

all: build/test_syscall_host build/syscall.o build/syscall_entry.o \
     build/m10_syscall_combined.o audit

build:
	mkdir -p build

build/test_syscall_host: tests/test_syscall_host.c kernel/syscall/syscall.c \
                         include/mcsos/syscall.h | build
	$(HOST_CC) $(HOST_CFLAGS) \
	    tests/test_syscall_host.c kernel/syscall/syscall.c \
	    -o $@

build/syscall.o: kernel/syscall/syscall.c include/mcsos/syscall.h | build
	$(CC) $(KERNEL_CFLAGS) -c kernel/syscall/syscall.c -o $@

build/syscall_entry.o: kernel/syscall/syscall_entry.S | build
	$(CC) -c kernel/syscall/syscall_entry.S -o $@

build/m10_syscall_combined.o: build/syscall.o build/syscall_entry.o
	ld -r $^ -o $@

host-test: build/test_syscall_host
	./build/test_syscall_host

audit: build/m10_syscall_combined.o
	$(NM) -u build/m10_syscall_combined.o > build/nm_undefined.txt
	$(READELF) -h build/m10_syscall_combined.o > build/readelf_header.txt
	$(OBJDUMP) -dr build/m10_syscall_combined.o > build/objdump.txt
	sha256sum build/test_syscall_host build/m10_syscall_combined.o > build/SHA256SUMS
	@grep -q "Advanced Micro Devices X86-64" build/readelf_header.txt && \
	    echo "[AUDIT OK] Machine: x86_64" || \
	    (echo "[AUDIT FAIL] Machine bukan x86_64"; exit 1)
	@grep -q "x86_64_syscall_int80_stub" build/objdump.txt && \
	    echo "[AUDIT OK] symbol stub ditemukan" || \
	    (echo "[AUDIT FAIL] symbol stub tidak ditemukan"; exit 1)
	@grep -q "iretq" build/objdump.txt && \
	    echo "[AUDIT OK] iretq ditemukan" || \
	    (echo "[AUDIT FAIL] iretq tidak ditemukan"; exit 1)

test: host-test audit

clean:
	rm -rf build
EOF

grep -n "host-test\|audit\|clean" Makefile.m10
make -f Makefile.m10 host-test
make -f Makefile.m10 audit
cat build/nm_undefined.txt
grep -E "Magic|Class|Machine|Type" build/readelf_header.txt
grep -E "x86_64_syscall_int80_stub|iretq" build/objdump.txt
git add include/mcsos/syscall.h kernel/syscall/syscall.c kernel/syscall/syscall_entry.S tests/test_syscall_host.c Makefile.m10
git commit -m "M10: ABI syscall awal, dispatcher, validasi argumen, stub int 0x80"
git checkout -b praktikum-m11-elf-user-loader
mkdir -p kernel/user include/mcsos/user tests/m11 scripts build
cd ~/mcsos
git status
git log --oneline -5
tree -L 2
cd ~/mcsos
git push origin praktikum-m11-elf-user-loader
cd ~/mcsos
git push origin praktikum-m10-elf-user-loade
git push origin praktikum/m10-syscall-abi
