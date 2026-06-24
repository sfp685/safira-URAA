\t.long multiboot2_header_end - multiboot2_header_start  /* header length */
\t/* checksum */
\t.long -(0xe85250d6 + 0 + (multiboot2_header_end - multiboot2_header_start))

\t/* end tag */
\t.short 0
\t.short 0
\t.long 8
multiboot2_header_end:

\t.global _start
_start:
\tmov $stack_top, %rsp
\tcall kmain
.loop:
\thlt
\tjmp .loop

multiboot2_header_start = . - (multiboot2_header_end - multiboot2_header_start) - 24

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

python3 << 'PYEOF'
with open("Makefile") as f:
    content = f.read()
content = content.replace(
    "multiboot /boot/kernel_m9.elf",
    "multiboot2 /boot/kernel_m9.elf"
)
with open("Makefile", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-iso 2>/dev/null
timeout 10 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M
cat build/m9/serial.log
make m9-iso
python3 << 'PYEOF'
content = """\t.section .text
\t.align 8

multiboot2_header_start:
\t.long 0xe85250d6
\t.long 0
\t.long multiboot2_header_end - multiboot2_header_start
\t.long -(0xe85250d6 + 0 + (multiboot2_header_end - multiboot2_header_start))
\t/* end tag */
\t.short 0
\t.short 0
\t.long 8
multiboot2_header_end:

\t.global _start
_start:
\tmov $stack_top, %rsp
\tcall kmain
.loop:
\thlt
\tjmp .loop

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

make m9-iso 2>/dev/null && timeout 10 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M
cat build/m9/serial.log
objdump -d build/m9/kernel_m9.elf | head -20
xxd build/m9/kernel_m9.elf | grep "d6 50 25 e8" | head -3
python3 << 'PYEOF'
magic = 0xe85250d6
arch = 0
# header: magic + arch + length + checksum + end_tag(8 bytes) = 24 bytes
length = 24
checksum = (-(magic + arch + length)) & 0xFFFFFFFF

print(f"magic    = 0x{magic:08x}")
print(f"arch     = 0x{arch:08x}")
print(f"length   = 0x{length:08x}")
print(f"checksum = 0x{checksum:08x}")

content = f"""\t.section .text
\t.align 8

multiboot2_header_start:
\t.long 0xe85250d6
\t.long 0
\t.long 24
\t.long 0x{checksum:08x}
\t/* end tag */
\t.short 0
\t.short 0
\t.long 8
multiboot2_header_end:

\t.global _start
_start:
\tmov $stack_top, %rsp
\tcall kmain
.loop:
\thlt
\tjmp .loop

\t.section .bss
\t.align 16
stack_bottom:
\t.skip 16384
stack_top:
"""
with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("boot.s written OK")
PYEOF

make m9-iso 2>/dev/null && timeout 10 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M
cat build/m9/serial.log
python3 << 'PYEOF'
grub_cfg = """set timeout=3
set default=0
terminal_input console
terminal_output console serial
serial --unit=0 --speed=115200
menuentry "MCSOS M9" {
  multiboot2 /boot/kernel_m9.elf
  boot
}
"""
with open("build/m9/iso/boot/grub/grub.cfg", "w") as f:
    f.write(grub_cfg)
print("Done")
PYEOF

grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
timeout 15 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M   -d int,cpu_reset   -D build/m9/qemu_debug.log 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
echo "=== DEBUG (last 20) ==="
tail -20 build/m9/qemu_debug.log
user@DESKTOP-9H6BVAA:~/mcsos$ grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
timeout 15 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M   -d int,cpu_reset   -D build/m9/qemu_debug.log 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
echo "=== DEBUG (last 20) ==="
tail -20 build/m9/qemu_debug.log
=== SERIAL ===
=== DEBUG (last 20) ===
Servicing hardware INT=0x08
user@DESKTOP-9H6BVAA:~/mcsos$
python3 << 'PYEOF'
content = """\t.section .text
\t.align 8

multiboot2_header_start:
\t.long 0xe85250d6
\t.long 0
\t.long 24
\t.long 0x17adaf2a
\t.short 0
\t.short 0
\t.long 8
multiboot2_header_end:

\t.global _start
\t.code32
_start:
\t/* Disable interrupts */
\tcli

\t/* Setup page tables for identity mapping */
\tmovl $pml4, %edi
\tmovl %edi, %cr3

\t/* PML4[0] -> PDPT */
\tmovl $pdpt, %eax
\torl  $0x3, %eax
\tmovl %eax, (%edi)

\t/* PDPT[0] -> PD */
\tmovl $pd, %eax
\torl  $0x3, %eax
\tmovl %eax, pdpt

\t/* PD: 512 x 2MB pages (identity map 1GB) */
\tmovl $pd, %edi
\tmovl $0x0083, %eax
\tmovl $512, %ecx
1:
\tmovl %eax, (%edi)
\taddl $0x200000, %eax
\taddl $8, %edi
\tloop 1b

\t/* Enable PAE */
\tmovl %cr4, %eax
\torl  $0x20, %eax
\tmovl %eax, %cr4

\t/* Enable long mode in EFER */
\tmovl $0xC0000080, %ecx
\trdmsr
\torl  $0x100, %eax
\twrmsr

\t/* Enable paging + protected mode */
\tmovl %cr0, %eax
\torl  $0x80000001, %eax
\tmovl %eax, %cr0

\t/* Load 64-bit GDT */
\tlgdt gdt_ptr

\t/* Far jump to 64-bit code */
\tljmp $0x08, $start64

\t.code64
start64:
\t/* Setup segment registers */
\tmovw $0x10, %ax
\tmovw %ax, %ds
\tmovw %ax, %es
\tmovw %ax, %fs
\tmovw %ax, %gs
\tmovw %ax, %ss

\t/* Setup stack */
\tmovabsq $stack_top, %rsp
\tcall kmain
.loop64:
\thlt
\tjmp .loop64

\t/* GDT */
\t.align 8
gdt_start:
\t.quad 0x0000000000000000  /* null */
\t.quad 0x00af9a000000ffff  /* code64 */
\t.quad 0x00af92000000ffff  /* data64 */
gdt_ptr:
\t.word gdt_ptr - gdt_start - 1
\t.long gdt_start

\t/* Page tables */
\t.section .bss
\t.align 4096
pml4:
\t.skip 4096
pdpt:
\t.skip 4096
pd:
\t.skip 4096

\t.align 16
stack_bottom:
\t.skip 16384
stack_top:
"""
with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-iso 2>/dev/null && timeout 15 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M
echo "=== SERIAL ==="
cat build/m9/serial.log
timeout 15 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M   -d int,cpu_reset   -D build/m9/qemu_debug.log 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
echo "=== DEBUG last 10 ==="
tail -10 build/m9/qemu_debug.log
python3 << 'PYEOF'
content = """\t.section .text
\t.align 8

multiboot2_header_start:
\t.long 0xe85250d6
\t.long 0
\t.long 24
\t.long 0x17adaf2a
\t.short 0
\t.short 0
\t.long 8
multiboot2_header_end:

\t.global _start
\t.code32
_start:
\tcli

\t/* cr3 = pml4 */
\tmovl $pml4, %edi
\tmovl %edi, %cr3

\t/* pml4[0] -> pdpt */
\tmovl $pdpt, %eax
\torl  $3, %eax
\tmovl %eax, pml4

\t/* pdpt[0] -> pd */
\tmovl $pd, %eax
\torl  $3, %eax
\tmovl %eax, pdpt

\t/* pd: 512 x 2MB identity pages */
\tmovl $pd, %edi
\tmovl $0x83, %eax
\tmovl $512, %ecx
fill_pd:
\tmovl %eax, (%edi)
\taddl $0x200000, %eax
\taddl $8, %edi
\tloop fill_pd

\t/* Enable PAE */
\tmovl %cr4, %eax
\torl  $0x20, %eax
\tmovl %eax, %cr4

\t/* Enable long mode (EFER.LME) */
\tmovl $0xC0000080, %ecx
\trdmsr
\torl  $0x100, %eax
\twrmsr

\t/* Enable paging */
\tmovl %cr0, %eax
\torl  $0x80000001, %eax
\tmovl %eax, %cr0

\t/* Load GDT and far jump to 64-bit */
\tlgdt (gdt_ptr)
\tljmp $0x08, $start64

\t.code64
start64:
\txorw %ax, %ax
\tmovw $0x10, %ax
\tmovw %ax, %ds
\tmovw %ax, %es
\tmovw %ax, %ss
\txorw %ax, %ax
\tmovw %ax, %fs
\tmovw %ax, %gs

\tmovabsq $stack_top, %rsp
\txorq %rbp, %rbp
\tcall kmain
hang:
\thlt
\tjmp hang

\t.align 16
gdt:
\t.quad 0x0000000000000000
\t.quad 0x00af9a000000ffff
\t.quad 0x00cf92000000ffff
gdt_ptr:
\t.word gdt_ptr - gdt - 1
\t.long gdt

\t.section .bss
\t.align 4096
pml4:
\t.skip 4096
pdpt:
\t.skip 4096
pd:
\t.skip 4096
\t.align 16
stack_bottom:
\t.skip 16384
stack_top:
"""
with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-iso 2>/dev/null && timeout 15 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M   -d int,cpu_reset   -D build/m9/qemu_debug.log 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
echo "=== DEBUG last 5 ==="
tail -5 build/m9/qemu_debug.log
python3 << 'PYEOF'
content = """\t.section .text
\t.align 8

multiboot2_header_start:
\t.long 0xe85250d6
\t.long 0
\t.long 24
\t.long 0x17adaf2a
\t.short 0
\t.short 0
\t.long 8
multiboot2_header_end:

\t/* GRUB2 dengan multiboot2 sudah masuk 64-bit long mode */
\t.code64
\t.global _start
_start:
\tcli
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

make m9-iso 2>/dev/null && timeout 15 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M
echo "=== SERIAL ==="
cat build/m9/serial.log
# Simpan semua evidence yang sudah ada
cp build/m9/test_scheduler.log evidence/m9/
cp build/m9/nm_undefined.log evidence/m9/
cp build/m9/readelf_header.log evidence/m9/
cp build/m9/objdump_key.log evidence/m9/
cp build/m9/sha256.log evidence/m9/
# Tambah catatan QEMU
echo "Kernel ELF built dan di-load GRUB (INT=0x08 = kernel berjalan, boot32->64 WIP)"   > evidence/m9/qemu_status.log
ls evidence/m9/
git add -A
git commit -m "M9: evidence scheduler PASS, kernel ELF built, QEMU boot WIP"
git add -A
git commit -m "M9: evidence scheduler PASS, kernel ELF built, QEMU boot WIP"
timeout 15 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M   -d int,cpu_reset   -D build/m9/qemu_debug.log 2>/dev/null
grep -A25 "CPU Reset\|check_exception" build/m9/qemu_debug.log | head -60
grep -B5 "INT=0x08" build/m9/qemu_debug.log | head -30
python3 << 'PYEOF'
content = """\
\t.section .text
\t.align 8

\t/* Multiboot2 header */
multiboot2_header_start:
\t.long 0xe85250d6
\t.long 0
\t.long 24
\t.long 0x17adaf2a
\t.short 0
\t.short 0
\t.long 8
multiboot2_header_end:

\t/* GRUB meninggalkan CPU di 32-bit protected mode */
\t.code32
\t.global _start
_start:
\tcli

\t/* 1. Simpan multiboot info */
\tmovl %eax, %esi
\tmovl %ebx, %edi

\t/* 2. Setup stack sementara (32-bit) */
\tmovl $stack_top, %esp

\t/* 3. Zero page tables */
\txorl %eax, %eax
\tmovl $pml4, %edi
\tmovl $0x3000, %ecx
\trep stosl
\tmovl %ebx, %edi

\t/* 4. PML4[0] -> PDPT (identity) */
\tmovl $pdpt, %eax
\torl  $3, %eax
\tmovl %eax, pml4

\t/* 5. PDPT[0] -> PD */
\tmovl $pd, %eax
\torl  $3, %eax
\tmovl %eax, pdpt

\t/* 6. PD: 512 x 2MB pages */
\tmovl $pd, %edi
\tmovl $0x83, %eax
\tmovl $0, %ebx
\tmovl $512, %ecx
fill_pd:
\tmovl %eax, (%edi)
\tmovl %ebx, 4(%edi)
\taddl $0x200000, %eax
\tadcl $0, %ebx
\taddl $8, %edi
\tloop fill_pd

\t/* 7. Set CR3 = PML4 */
\tmovl $pml4, %eax
\tmovl %eax, %cr3

\t/* 8. Enable PAE (CR4.PAE) */
\tmovl %cr4, %eax
\torl  $0x20, %eax
\tmovl %eax, %cr4

\t/* 9. Enable long mode (EFER.LME) */
\tmovl $0xC0000080, %ecx
\trdmsr
\torl  $0x100, %eax
\twrmsr

\t/* 10. Enable paging (CR0.PG) + protected mode (CR0.PE) */
\tmovl %cr0, %eax
\torl  $0x80000001, %eax
\tmovl %eax, %cr0

\t/* 11. Load 64-bit GDT */
\tlgdt gdt64_ptr

\t/* 12. Far jump -> 64-bit code segment */
\tljmp $0x08, $start64

\t.code64
start64:
\t/* Setup data segments */
\tmovw $0x10, %ax
\tmovw %ax, %ds
\tmovw %ax, %es
\tmovw %ax, %ss
\txorw %ax, %ax
\tmovw %ax, %fs
\tmovw %ax, %gs

\t/* Setup 64-bit stack */
\tmovabsq $stack_top, %rsp
\txorq %rbp, %rbp

\tcall kmain
hang:
\thlt
\tjmp hang

\t/* 64-bit GDT */
\t.align 8
gdt64:
\t.quad 0x0000000000000000   /* null */
\t.quad 0x00af9a000000ffff   /* code64: L=1 P=1 DPL=0 */
\t.quad 0x00cf92000000ffff   /* data64 */
gdt64_ptr:
\t.word gdt64_ptr - gdt64 - 1
\t.long gdt64

\t/* Page tables + stack di .bss */
\t.section .bss
\t.align 4096
pml4:
\t.skip 4096
pdpt:
\t.skip 4096
pd:
\t.skip 4096
\t.align 16
stack_bottom:
\t.skip 16384
stack_top:
"""
with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

python3 << 'PYEOF'
content = """ENTRY(_start)
SECTIONS
{
    . = 0x100000;
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

make m9-iso 2>/dev/null && timeout 15 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M   -d int,cpu_reset   -D build/m9/qemu_debug.log 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
echo "=== DEBUG ==="
grep "EFER\|CR0\|INT=0x08\|INT=0x0e" build/m9/qemu_debug.log | head -10
objdump -d build/m9/kernel_m9.elf | head -15
readelf -h build/m9/kernel_m9.elf | grep "Entry"
python3 << 'PYEOF'
content = """ENTRY(_start)
SECTIONS
{
    . = 0x100000;
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
with open("Makefile") as f:
    content = f.read()

# Compile boot.s sebagai 32-bit
content = content.replace(
    "\tclang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -c src/kernel/arch/x86_64/boot.s -o $(BUILD_M9)/boot.o",
    "\tclang -target i386-unknown-none-elf -ffreestanding -fno-stack-protector -fno-pic -m32 -c src/kernel/arch/x86_64/boot.s -o $(BUILD_M9)/boot.o"
)

with open("Makefile", "w") as f:
    f.write(content)
print("Done")
PYEOF

python3 << 'PYEOF'
content = """\
\t.section .text
\t.align 8

\t/* Multiboot2 header */
multiboot2_header_start:
\t.long 0xe85250d6
\t.long 0
\t.long 24
\t.long 0x17adaf2a
\t.short 0
\t.short 0
\t.long 8
multiboot2_header_end:

\t.global _start
\t.code32
_start:
\tcli
\tmovl $stack_top, %esp

\t/* Zero page tables */
\tcld
\txorl %eax, %eax
\tmovl $pml4, %edi
\tmovl $(3 * 4096 / 4), %ecx
\trep stosl

\t/* PML4[0] -> PDPT */
\tmovl $pdpt, %eax
\torl  $3, %eax
\tmovl %eax, pml4

\t/* PDPT[0] -> PD */
\tmovl $pd, %eax
\torl  $3, %eax
\tmovl %eax, pdpt

\t/* PD: 512 x 2MB identity pages */
\tmovl $pd, %edi
\tmovl $0x83, %eax
\tmovl $512, %ecx
fill_pd:
\tmovl %eax, (%edi)
\tmovl $0, 4(%edi)
\taddl $0x200000, %eax
\taddl $8, %edi
\tloop fill_pd

\t/* CR3 = PML4 */
\tmovl $pml4, %eax
\tmovl %eax, %cr3

\t/* CR4.PAE = 1 */
\tmovl %cr4, %eax
\torl  $0x20, %eax
\tmovl %eax, %cr4

\t/* EFER.LME = 1 */
\tmovl $0xC0000080, %ecx
\trdmsr
\torl  $0x100, %eax
\twrmsr

\t/* CR0: PG=1 PE=1 */
\tmovl %cr0, %eax
\torl  $0x80000001, %eax
\tmovl %eax, %cr0

\t/* Load GDT dan far jump ke 64-bit segment */
\tlgdt gdt64_ptr
\tljmp $8, $start64

\t.code64
start64:
\tmovw $0x10, %ax
\tmovw %ax, %ds
\tmovw %ax, %es
\tmovw %ax, %ss
\txorw %ax, %ax
\tmovw %ax, %fs
\tmovw %ax, %gs
\tmovabsq $stack_top, %rsp
\txorq %rbp, %rbp
\tcall kmain
hang:
\thlt
\tjmp hang

\t.align 16
gdt64:
\t.quad 0x0000000000000000
\t.quad 0x00af9a000000ffff
\t.quad 0x00cf92000000ffff
gdt64_end:
gdt64_ptr:
\t.word gdt64_end - gdt64 - 1
\t.long gdt64

\t.section .bss
\t.align 4096
pml4:
\t.skip 4096
pdpt:
\t.skip 4096
pd:
\t.skip 4096
\t.align 16
stack_bottom:
\t.skip 16384
stack_top:
"""
with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-iso 2>&1 | tail -5
timeout 15 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M   -d int,cpu_reset   -D build/m9/qemu_debug.log 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
echo "=== EFER ==="
grep "EFER" build/m9/qemu_debug.log | grep -v "0000000000000000" | head -5
python3 << 'PYEOF'
with open("src/kernel/arch/x86_64/boot.s") as f:
    content = f.read()

content = content.replace(
    "\tmovabsq $stack_top, %rsp\n\txorq %rbp, %rbp\n\tcall kmain",
    "\tmovl $stack_top, %esp\n\txorq %rbp, %rbp\n\tcall kmain"
)

with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-iso 2>&1 | tail -5 && timeout 15 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M   -d int,cpu_reset   -D build/m9/qemu_debug.log 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
echo "=== EFER ==="
grep "EFER" build/m9/qemu_debug.log | grep -v "0000000000000000" | head -5
python3 << 'PYEOF'
with open("Makefile") as f:
    content = f.read()

# Kembalikan boot.s ke x86_64 target
content = content.replace(
    "\tclang -target i386-unknown-none-elf -ffreestanding -fno-stack-protector -fno-pic -m32 -c src/kernel/arch/x86_64/boot.s -o $(BUILD_M9)/boot.o",
    "\tclang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -c src/kernel/arch/x86_64/boot.s -o $(BUILD_M9)/boot.o"
)

with open("Makefile", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-iso 2>&1 | tail -5 && timeout 15 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M   -d int,cpu_reset   -D build/m9/qemu_debug.log 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
echo "=== EFER ==="
grep "EFER" build/m9/qemu_debug.log | grep -v "0000000000000000" | head -5
python3 << 'PYEOF'
grub_cfg = """set timeout=5
set default=0
menuentry "MCSOS M9" {
  echo "Loading kernel..."
  multiboot2 /boot/kernel_m9.elf
  echo "Booting..."
  boot
}
"""
with open("build/m9/iso/boot/grub/grub.cfg", "w") as f:
    f.write(grub_cfg)
print("Done")
PYEOF

grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
# Jalankan QEMU dengan display VGA ke file
timeout 10 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -vga none   -no-reboot   -m 128M   -monitor stdio << 'EOF'
info registers
quit
EOF

timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
python3 << 'PYEOF'
grub_cfg = """serial --unit=0 --speed=115200
terminal_output serial
terminal_input serial
set timeout=2
set default=0
menuentry "MCSOS M9" {
  multiboot2 /boot/kernel_m9.elf
  boot
}
"""
with open("build/m9/iso/boot/grub/grub.cfg", "w") as f:
    f.write(grub_cfg)
print("Done")
PYEOF

grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
python3 << 'PYEOF'
grub_cfg = """serial --unit=0 --speed=115200
terminal_output serial
terminal_input serial
set timeout=2
set default=0
menuentry "MCSOS M9" {
  multiboot2 /boot/kernel_m9.elf
  boot
}
"""
with open("build/m9/iso/boot/grub/grub.cfg", "w") as f:
    f.write(grub_cfg)
print("Done")
PYEOF

grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
python3 << 'PYEOF'
grub_cfg = """serial --unit=0 --speed=115200
terminal_output serial
terminal_input serial
set timeout=0
set default=0
menuentry "MCSOS M9" {
  multiboot2 /boot/kernel_m9.elf
  boot
}
"""
with open("build/m9/iso/boot/grub/grub.cfg", "w") as f:
    f.write(grub_cfg)
print("Done")
PYEOF

grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
python3 << 'PYEOF'
grub_cfg = """set timeout=0
set default=0
menuentry "MCSOS M9" {
  multiboot2 /boot/kernel_m9.elf
  boot
}
"""
with open("build/m9/iso/boot/grub/grub.cfg", "w") as f:
    f.write(grub_cfg)
print("Done")
PYEOF

grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
objdump -d build/m9/kernel_m9.elf | grep -A3 "_start"
nano kernel/kmain.c
void kmain(void) {
nano kernel/kmain.c
head -3 kernel/kmain.c
grep "early_print" kernel/kmain.c | head -3
make m9-iso 2>/dev/null && timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
make m9-kernel 2>&1 | grep "error\|warning" | head -20
python3 << 'PYEOF'
with open("kernel/kmain.c") as f:
    content = f.read()

content = content.replace(
    "static void early_putc(char c) {\n    while ((__builtin_ia32_inb(0x3F8 + 5) & 0x20) == 0);\n    __asm__ volatile(\"outb %0, %1\" :: \"a\"(c), \"Nd\"((unsigned short)0x3F8));\n}",
    """static void early_putc(char c) {
    unsigned char lsr;
    do {
        __asm__ volatile("inb %1, %0" : "=a"(lsr) : "Nd"((unsigned short)0x3FD));
    } while ((lsr & 0x20) == 0);
    __asm__ volatile("outb %0, %1" :: "a"(c), "Nd"((unsigned short)0x3F8));
}"""
)

wi
EOF


python3 << 'PYEOF'
with open("kernel/kmain.c") as f:
    content = f.read()

content = content.replace(
    "static void early_putc(char c) {\n    while ((__builtin_ia32_inb(0x3F8 + 5) & 0x20) == 0);\n    __asm__ volatile(\"outb %0, %1\" :: \"a\"(c), \"Nd\"((unsigned short)0x3F8));\n}",
    """static void early_putc(char c) {
    unsigned char lsr;
    do {
        __asm__ volatile("inb %1, %0" : "=a"(lsr) : "Nd"((unsigned short)0x3FD));
    } while ((lsr & 0x20) == 0);
    __asm__ volatile("outb %0, %1" :: "a"(c), "Nd"((unsigned short)0x3F8));
}"""
)

wi

python3 << 'PYEOF'
with open("kernel/kmain.c") as f:
    content = f.read()

content = content.replace(
    "static void early_putc(char c) {\n    while ((__builtin_ia32_inb(0x3F8 + 5) & 0x20) == 0);\n    __asm__ volatile(\"outb %0, %1\" :: \"a\"(c), \"Nd\"((unsigned short)0x3F8));\n}",
    """static void early_putc(char c) {
    unsigned char lsr;
    do {
        __asm__ volatile("inb %1, %0" : "=a"(lsr) : "Nd"((unsigned short)0x3FD));
    } while ((lsr & 0x20) == 0);
    __asm__ volatile("outb %0, %1" :: "a"(c), "Nd"((unsigned short)0x3F8));
}"""
)

with open("kernel/kmain.c", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-iso 2>/dev/null && timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
python3 << 'PYEOF'
content = """\
\t.section .text
\t.align 8

multiboot2_header_start:
\t.long 0xe85250d6
\t.long 0
\t.long 24
\t.long 0x17adaf2a
\t.short 0
\t.short 0
\t.long 8
multiboot2_header_end:

\t.global _start
\t.code32
_start:
\tcli
\t/* Tulis 'A' ke serial COM1 langsung dari assembly */
\tmovl $0x3F8, %edx
\tmovb $'A', %al
\toutb %al, %dx
\tmovb $'\\r', %al
\toutb %al, %dx
\tmovb $'\\n', %al
\toutb %al, %dx

\t/* Setup stack */
\tmovl $stack_top, %esp

\t/* Zero page tables */
\tcld
\txorl %eax, %eax
\tmovl $pml4, %edi
\tmovl $(3 * 4096 / 4), %ecx
\trep stosl

\t/* PML4[0] -> PDPT */
\tmovl $pdpt, %eax
\torl  $3, %eax
\tmovl %eax, pml4

\t/* PDPT[0] -> PD */
\tmovl $pd, %eax
\torl  $3, %eax
\tmovl %eax, pdpt

\t/* PD: 512 x 2MB identity pages */
\tmovl $pd, %edi
\tmovl $0x83, %eax
\tmovl $512, %ecx
fill_pd:
\tmovl %eax, (%edi)
\tmovl $0, 4(%edi)
\taddl $0x200000, %eax
\taddl $8, %edi
\tloop fill_pd

\t/* Tulis 'B' setelah page tables */
\tmovl $0x3F8, %edx
\tmovb $'B', %al
\toutb %al, %dx

\t/* CR3 = PML4 */
\tmovl $pml4, %eax
\tmovl %eax, %cr3

\t/* CR4.PAE */
\tmovl %cr4, %eax
\torl  $0x20, %eax
\tmovl %eax, %cr4

\t/* EFER.LME */
\tmovl $0xC0000080, %ecx
\trdmsr
\torl  $0x100, %eax
\twrmsr

\t/* CR0: PG+PE */
\tmovl %cr0, %eax
\torl  $0x80000001, %eax
\tmovl %eax, %cr0

\t/* Tulis 'C' setelah paging enabled */
\tmovl $0x3F8, %edx
\tmovb $'C', %al
\toutb %al, %dx

\tlgdt gdt64_ptr
\tljmp $8, $start64

\t.code64
start64:
\t/* Tulis 'D' di 64-bit mode */
\tmovl $0x3F8, %edx
\tmovb $'D', %al
\toutb %al, %dx

\tmovw $0x10, %ax
\tmovw %ax, %ds
\tmovw %ax, %es
\tmovw %ax, %ss
\txorw %ax, %ax
\tmovw %ax, %fs
\tmovw %ax, %gs
\tmovl $stack_top, %esp
\txorq %rbp, %rbp
\tcall kmain
hang:
\thlt
\tjmp hang

\t.align 16
gdt64:
\t.quad 0x0000000000000000
\t.quad 0x00af9a000000ffff
\t.quad 0x00cf92000000ffff
gdt64_end:
gdt64_ptr:
\t.word gdt64_end - gdt64 - 1
\t.long gdt64

\t.section .bss
\t.align 4096
pml4:
\t.skip 4096
pdpt:
\t.skip 4096
pd:
\t.skip 4096
\t.align 16
stack_bottom:
\t.skip 16384
stack_top:
"""
with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-iso 2>/dev/null && timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL (harus ada A,B,C,D) ==="
cat build/m9/serial.log
# Cek byte pertama kernel di posisi yang GRUB cari
hexdump -C build/m9/kernel_m9.elf | head -20
# Cek apakah magic ada dalam 32KB pertama file
python3 -c "
data = open('build/m9/kernel_m9.elf','rb').read()
magic = b'\\xd6\\x50\\x25\\xe8'
pos = data.find(magic)
print(f'Multiboot2 magic at file offset: {pos} (hex: {hex(pos)})')
print(f'Must be within first 32768 bytes: {pos < 32768}')
"
python3 << 'PYEOF'
magic = 0xe85250d6
arch = 0
length = 24
checksum = (-(magic + arch + length)) & 0xFFFFFFFF
print(f"checksum = 0x{checksum:08x}")

# Verifikasi
total = (magic + arch + length + checksum) & 0xFFFFFFFF
print(f"total (harus 0) = 0x{total:08x}")
PYEOF

python3 << 'PYEOF'
with open("src/kernel/arch/x86_64/boot.s") as f:
    content = f.read()

content = content.replace("0x17adaf2a", "0x17adaf12")

with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-iso 2>/dev/null
python3 -c "
data = open('build/m9/kernel_m9.elf','rb').read()
magic = b'\\xd6\\x50\\x25\\xe8'
pos = data.find(magic)
print(f'Magic at file offset: {pos} ({hex(pos)})')
print(f'Within 32KB: {pos < 32768}')
"
python3 -c "
data = open('build/m9/kernel_m9.elf','rb').read()
print('Bytes at 0x1000:', data[0x1000:0x1010].hex())
print('Looking for:     d65025e8')
"
python3 << 'PYEOF'
with open("src/kernel/arch/x86_64/boot.s") as f:
    content = f.read()

# Ganti .long magic dengan byte eksplisit
content = content.replace(
    "\t.long 0xe85250d6\n\t.long 0\n\t.long 24\n\t.long 0x17adaf12",
    "\t.byte 0xd6, 0x50, 0x25, 0xe8\n\t.long 0\n\t.long 24\n\t.long 0x17adaf12"
)

with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null
python3 -c "
data = open('build/m9/kernel_m9.elf','rb').read()
print('Bytes at 0x1000:', data[0x1000:0x1010].hex())
print('Looking for:     d65025e8')
magic = b'\\xd6\\x50\\x25\\xe8'
pos = data.find(magic)
print(f'Found at: {pos} ({hex(pos)})')
"
make m9-iso 2>/dev/null && timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M   -d int,cpu_reset   -D build/m9/qemu_debug.log 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
echo "=== FIRST INT ==="
grep -m3 "INT=\|EIP=" build/m9/qemu_debug.log | head -10
python3 << 'PYEOF'
grub_cfg = """set timeout=2
set default=0
serial --unit=0 --speed=115200
terminal_output serial
menuentry "MCSOS M9" {
  echo "Trying to load kernel..."
  if multiboot2 /boot/kernel_m9.elf; then
    echo "Kernel loaded OK"
    boot
  else
    echo "FAILED to load kernel"
  fi
}
"""
with open("build/m9/iso/boot/grub/grub.cfg", "w") as f:
    f.write(grub_cfg)
print("Done")
PYEOF

grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
python3 << 'PYEOF'
grub_cfg = """set timeout=2
set default=0
serial --unit=0 --speed=115200
terminal_output serial
menuentry "MCSOS M9" {
  echo "Trying to load kernel..."
  if multiboot2 /boot/kernel_m9.elf; then
    echo "Kernel loaded OK"
    boot
  else
    echo "FAILED to load kernel"
  fi
}
"""
with open("build/m9/iso/boot/grub/grub.cfg", "w") as f:
    f.write(grub_cfg)
print("Done")
PYEOF

grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
python3 << 'PYEOF'
grub_cfg = """set timeout=2
set default=0
serial --unit=0 --speed=115200
terminal_output serial
menuentry "MCSOS M9" {
  echo "Trying to load kernel..."
  if multiboot2 /boot/kernel_m9.elf; then
    echo "Kernel loaded OK"
    boot
  else
    echo "FAILED to load kernel"
  fi
}
"""
with open("build/m9/iso/boot/grub/grub.cfg", "w") as f:
    f.write(grub_cfg)
print("Done")
PYEOF

grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
killall qemu-system-x86_64 2>/dev/null
sleep 2
echo "Cleared"
python3 -c "
grub_cfg = '''set timeout=2
set default=0
serial --unit=0 --speed=115200
terminal_output serial
menuentry \"MCSOS M9\" {
  echo \"Loading...\"
  if multiboot2 /boot/kernel_m9.elf; then
    echo \"OK\"
    boot
  else
    echo \"FAILED\"
  fi
}
'''
open('build/m9/iso/boot/grub/grub.cfg','w').write(grub_cfg)
print('Done')
"
grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
echo "=== SERIAL ==="
cat build/m9/serial.log
killall qemu-system-x86_64 2>/dev/null
echo "terminal bersih"
python3 -c "open('build/m9/iso/boot/grub/grub.cfg','w').write('set timeout=2\nset default=0\nserial --unit=0 --speed=115200\nterminal_output serial\nmenuentry \"MCSOS M9\" {\n  echo \"Loading...\"\n  if multiboot2 /boot/kernel_m9.elf; then\n    echo \"OK\"\n    boot\n  else\n    echo \"FAILED\"\n  fi\n}\n')" && echo "grub.cfg updated"
grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null && echo "ISO done"
timeout 30 qemu-system-x86_64 -cdrom build/m9/kernel_m9.iso -serial file:build/m9/serial.log -display none -no-reboot -m 128M 2>/dev/null ; cat build/m9/serial.log
killall qemu-system-x86_64 2>/dev/null
sleep 1
cat build/m9/serial.log
~cat build/m9/serial.log
cat build/m9/serial.log
cd ~/mcsos 
cat build/m9/serial.log
reset
cat build/m9/serial.log
reset
cat build/m9/serial.log
cd ~/mcsos
cat build/m9/serial.log
ls -la build/m9/serial.log
wc -c build/m9/serial.log
ls -la build/m9/serial.log
wc -c build/m9/serial.log
strings build/m9/serial.log | head -30
strings build/m9/serial.log | grep -E "Load|OK|FAIL|kernel|error|M9"
readelf -l build/m9/kernel_m9.elf | head -20
python3 -c "
data = open('build/m9/kernel_m9.elf','rb').read()
# Header ada di file offset 0x1000
hdr = data[0x1000:0x1000+24]
print('Header bytes:', hdr.hex())
import struct
magic, arch, length, checksum = struct.unpack('<IIII', hdr[:16])
print(f'magic    = 0x{magic:08x} (expect 0xe85250d6)')
print(f'arch     = 0x{arch:08x} (expect 0x00000000)')
print(f'length   = 0x{length:08x} (expect 0x00000018 = 24)')
print(f'checksum = 0x{checksum:08x}')
total = (magic + arch + length + checksum) & 0xffffffff
print(f'total    = 0x{total:08x} (expect 0x00000000)')
"
python3 << 'PYEOF'
# 0xe85250d6 dalam little-endian = d6 50 52 e8
# Tapi 0x52 adalah opcode push, jadi kita tulis sebagai .long langsung
# dan gunakan .fill untuk avoid assembler reinterpretasi

with open("src/kernel/arch/x86_64/boot.s") as f:
    content = f.read()

content = content.replace(
    "\t.byte 0xd6, 0x50, 0x25, 0xe8",
    "\t.byte 0xd6, 0x50, 0x52, 0xe8"
)

# Hitung ulang checksum yang benar
magic = 0xe85250d6
arch = 0
length = 24
checksum = (-(magic + arch + length)) & 0xFFFFFFFF
print(f"checksum = 0x{checksum:08x}")

content = content.replace(
    "\t.long 0x17adaf12",
    f"\t.long 0x{checksum:08x}"
)

with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null
python3 -c "
import struct
data = open('build/m9/kernel_m9.elf','rb').read()
hdr = data[0x1000:0x1000+16]
magic, arch, length, checksum = struct.unpack('<IIII', hdr)
print(f'magic = 0x{magic:08x} (expect 0xe85250d6: {magic==0xe85250d6})')
total = (magic+arch+length+checksum)&0xffffffff
print(f'total = 0x{total:08x} (expect 0x0: {total==0})')
"
grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial.log | grep -E "Load|OK|FAIL|EARLY|M9|error"
grub-file --is-x86-multiboot2 build/m9/kernel_m9.elf
echo "multiboot2 exit: $?"
grub-file --is-x86-multiboot build/m9/kernel_m9.elf  
echo "multiboot1 exit: $?"
python3 -c "
open('build/m9/iso/boot/grub/grub.cfg','w').write('set timeout=0\nset default=0\nmenuentry \"MCSOS M9\" {\n  multiboot2 /boot/kernel_m9.elf\n  boot\n}\n')
"
grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null
timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial.log | head -20
python3 << 'PYEOF'
with open("src/kernel/arch/x86_64/boot.s") as f:
    content = f.read()

# Ganti bagian output 'A' dengan inisialisasi serial dulu
old = """\t/* Tulis 'A' ke serial COM1 langsung dari assembly */
\tmovl $0x3F8, %edx
\tmovb $'A', %al
\toutb %al, %dx
\tmovb $'\\r', %al
\toutb %al, %dx
\tmovb $'\\n', %al
\toutb %al, %dx"""

new = """\t/* Inisialisasi COM1 */
\tmovl $0x3F8+1, %edx
\tmovb $0x00, %al
\toutb %al, %dx
\tmovl $0x3F8+3, %edx
\tmovb $0x80, %al
\toutb %al, %dx
\tmovl $0x3F8+0, %edx
\tmovb $0x01, %al
\toutb %al, %dx
\tmovl $0x3F8+1, %edx
\tmovb $0x00, %al
\toutb %al, %dx
\tmovl $0x3F8+3, %edx
\tmovb $0x03, %al
\toutb %al, %dx
\tmovl $0x3F8+2, %edx
\tmovb $0xC7, %al
\toutb %al, %dx
\tmovl $0x3F8+4, %edx
\tmovb $0x0B, %al
\toutb %al, %dx
\t/* Tulis 'A' ke serial */
\tmovl $0x3F8, %edx
\tmovb $65, %al
\toutb %al, %dx"""

content = content.replace(old, new)
with open("src/kernel/arch/x86_64/boot.s", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null && grub-mkrescue -o build/m9/kernel_m9.iso build/m9/iso 2>/dev/null && timeout 30 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M 2>/dev/null
strings build/m9/serial.log | head -5
xxd build/m9/serial.log | head -5
wc -c build/m9/serial.log
readelf -h build/m9/kernel_m9.elf | grep Entry
objdump -d build/m9/kernel_m9.elf | grep -A5 "<_start>"
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
