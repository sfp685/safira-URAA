mcsos_thread_t *mcsos_sched_pick_next(mcsos_scheduler_t *sched);
int             mcsos_sched_yield(mcsos_scheduler_t *sched);
int             mcsos_sched_tick(mcsos_scheduler_t *sched);
int             mcsos_thread_block_current(mcsos_scheduler_t *sched);
int             mcsos_thread_mark_ready(mcsos_scheduler_t *sched,
                                        mcsos_thread_t *thread);
int             mcsos_sched_validate(const mcsos_scheduler_t *sched);
size_t          mcsos_sched_ready_count(const mcsos_scheduler_t *sched);

#endif /* MCSOS_THREAD_H */
EOF

head -3 include/mcsos_thread.h
# harus muncul: #ifndef MCSOS_THREAD_H
nano include/mcsos_thread.h
wc -l include/mcsos_thread.h
# harus sekitar 90 baris
tail -3 include/mcsos_thread.h
# harus muncul: #endif /* MCSOS_THREAD_H */
clang -std=c17 -Wall -Wextra -Werror -Iinclude -fsyntax-only include/mcsos_thread.h
echo "Header OK: $?"
nano kernel/mcsos_thread.c
wc -l kernel/mcsos_thread.c
tail -3 kernel/mcsos_thread.c
clang -std=c17 -Wall -Wextra -Werror -DMCSOS_HOST_TEST -Iinclude -fsyntax-only kernel/mcsos_thread.c
echo "mcsos_thread.c OK: $?"
nano arch/x86_64/context_switch.S
.section .text
/*
mcsos_context_switch:
1:
wc -l arch/x86_64/context_switch.S
tail -3 arch/x86_64/context_switch.S
rm arch/x86_64/context_switch.S
nano arch/x86_64/context_switch.S
wc -l arch/x86_64/context_switch.S
tail -3 arch/x86_64/context_switch.S
clang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector   -fno-pic -mno-red-zone   -c arch/x86_64/context_switch.S -o build/m9/context_switch.o
echo "context_switch.S OK: $?"
nano tests/test_scheduler.c
wc -l tests/test_scheduler.c
tail -3 tests/test_scheduler.c
nano Makefile
grep -n "m9-all\|m9-host-test\|m9-clean" Makefile
make m9-clean && make m9-all 2>&1 | tee build/m9_build.log
cat -A Makefile | tail -40
cat -A Makefile | head -20
cat > Makefile << 'MAKEEOF'
# ================================================================
# M9 - Kernel Thread, Scheduler, Context Switch
# ================================================================
CC_HOST   := clang
CC_KERNEL := clang
LD_KERNEL := ld.lld

BUILD_M9 := build/m9

CFLAGS_HOST_M9  := -std=c17 -Wall -Wextra -Werror -DMCSOS_HOST_TEST -Iinclude
CFLAGS_KERN_M9  := -target x86_64-unknown-none-elf -std=c17 \
                   -ffreestanding -fno-stack-protector -fno-pic \
                   -mno-red-zone -Wall -Wextra -Werror -Iinclude
ASFLAGS_KERN_M9 := -target x86_64-unknown-none-elf -ffreestanding \
                   -fno-stack-protector -fno-pic -mno-red-zone

.PHONY: all m9-all m9-host-test m9-freestanding m9-audit m9-clean

all: m9-all

m9-all: m9-host-test m9-freestanding m9-audit

$(BUILD_M9):
	mkdir -p $(BUILD_M9)

m9-host-test: $(BUILD_M9)
	$(CC_HOST) $(CFLAGS_HOST_M9) \
	  tests/test_scheduler.c kernel/mcsos_thread.c \
	  -o $(BUILD_M9)/m9_host_test
	$(BUILD_M9)/m9_host_test | tee $(BUILD_M9)/test_scheduler.log

m9-freestanding: $(BUILD_M9)
	$(CC_KERNEL) $(CFLAGS_KERN_M9) \
	  -c kernel/mcsos_thread.c -o $(BUILD_M9)/mcsos_thread.freestanding.o
	$(CC_KERNEL) $(ASFLAGS_KERN_M9) \
	  -c arch/x86_64/context_switch.S -o $(BUILD_M9)/context_switch.o
	ld.lld -r \
	  $(BUILD_M9)/mcsos_thread.freestanding.o \
	  $(BUILD_M9)/context_switch.o \
	  -o $(BUILD_M9)/m9_scheduler_combined.o

m9-audit: m9-freestanding
	nm -u $(BUILD_M9)/m9_scheduler_combined.o \
	  | tee $(BUILD_M9)/nm_undefined.log
	readelf -h $(BUILD_M9)/m9_scheduler_combined.o \
	  | tee $(BUILD_M9)/readelf_header.log
	objdump -d $(BUILD_M9)/m9_scheduler_combined.o \
	  | grep -E 'mcsos_context_switch|jmp|ret|hlt' \
	  | tee $(BUILD_M9)/objdump_key.log
	sha256sum $(BUILD_M9)/m9_host_test \
	          $(BUILD_M9)/m9_scheduler_combined.o \
	  | tee $(BUILD_M9)/sha256.log

m9-clean:
	rm -rf $(BUILD_M9)
MAKEEOF

cat -A Makefile | head -5
grep -n "m9-clean" Makefile
make m9-clean && make m9-all 2>&1 | tee build/m9_build.log
cat -A Makefile | grep "mkdir\|CC_HOST\|m9_host" | head -5
python3 - << 'PYEOF'
content = open("Makefile").read()
print(repr(content[:200]))
PYEOF

python3 << 'PYEOF'
makefile = """\
# ================================================================
# M9 - Kernel Thread, Scheduler, Context Switch
# ================================================================
CC_HOST   := clang
CC_KERNEL := clang
LD_KERNEL := ld.lld

BUILD_M9 := build/m9

CFLAGS_HOST_M9  := -std=c17 -Wall -Wextra -Werror -DMCSOS_HOST_TEST -Iinclude
CFLAGS_KERN_M9  := -target x86_64-unknown-none-elf -std=c17 \\
\t\t\t\t   -ffreestanding -fno-stack-protector -fno-pic \\
\t\t\t\t   -mno-red-zone -Wall -Wextra -Werror -Iinclude
ASFLAGS_KERN_M9 := -target x86_64-unknown-none-elf -ffreestanding \\
\t\t\t\t   -fno-stack-protector -fno-pic -mno-red-zone

.PHONY: all m9-all m9-host-test m9-freestanding m9-audit m9-clean

all: m9-all

m9-all: m9-host-test m9-freestanding m9-audit

$(BUILD_M9):
\tmkdir -p $(BUILD_M9)

m9-host-test: $(BUILD_M9)
\t$(CC_HOST) $(CFLAGS_HOST_M9) \\
\t  tests/test_scheduler.c kernel/mcsos_thread.c \\
\t  -o $(BUILD_M9)/m9_host_test
\t$(BUILD_M9)/m9_host_test | tee $(BUILD_M9)/test_scheduler.log

m9-freestanding: $(BUILD_M9)
\t$(CC_KERNEL) $(CFLAGS_KERN_M9) \\
\t  -c kernel/mcsos_thread.c -o $(BUILD_M9)/mcsos_thread.freestanding.o
\t$(CC_KERNEL) $(ASFLAGS_KERN_M9) \\
\t  -c arch/x86_64/context_switch.S -o $(BUILD_M9)/context_switch.o
\tld.lld -r \\
\t  $(BUILD_M9)/mcsos_thread.freestanding.o \\
\t  $(BUILD_M9)/context_switch.o \\
\t  -o $(BUILD_M9)/m9_scheduler_combined.o

m9-audit: m9-freestanding
\tnm -u $(BUILD_M9)/m9_scheduler_combined.o \\
\t  | tee $(BUILD_M9)/nm_undefined.log
\treadelf -h $(BUILD_M9)/m9_scheduler_combined.o \\
\t  | tee $(BUILD_M9)/readelf_header.log
\tobjdump -d $(BUILD_M9)/m9_scheduler_combined.o \\
\t  | grep -E 'mcsos_context_switch|jmp|ret|hlt' \\
\t  | tee $(BUILD_M9)/objdump_key.log
\tsha256sum $(BUILD_M9)/m9_host_test \\
\t          $(BUILD_M9)/m9_scheduler_combined.o \\
\t  | tee $(BUILD_M9)/sha256.log

m9-clean:
\trm -rf $(BUILD_M9)
"""
with open("Makefile", "w") as f:
    f.write(makefile)
print("Makefile written OK")
PYEOF

cat -A Makefile | grep "mkdir\|m9_host_test\|rm -rf"
make m9-clean && make m9-all 2>&1 | tee build/m9_build.log
make --print-data-base 2>&1 | grep "m9-clean" | head -5
ls -la Makefile makefile GNUmakefile 2>&1
which make && make --version | head -2
rm makefile
make m9-clean && make m9-all 2>&1 | tee build/m9_build.log
git add include/mcsos_thread.h kernel/mcsos_thread.c         arch/x86_64/context_switch.S tests/test_scheduler.c         Makefile build/m9/
git commit -m "M9: kernel thread, round-robin scheduler, context switch x86_64"
ls kernel/
ls arch/x86_64/
cat kernel/kernel_main.c 2>/dev/null || find . -name "kernel_main*" 2>/dev/null
cat kernel/kmain.c
ls kernel/core/
ls kernel/mcsos/
find . -name "log.h" 2>/dev/null
cat mcsos/kernel/log.h
nano kernel/kmain.c
wc -l kernel/kmain.c
tail -5 kernel/kmain.c
cat Makefile | grep -E "^all|^kernel|qemu|run|boot" | head -20
find . -name "*.mk" -o -name "build.sh" -o -name "run.sh" -o -name "*.sh" 2>/dev/null | grep -v ".git"
ls *.sh 2>/dev/null
find . -not -path "./.git/*" -not -path "./build/*" | sort
cat linker.ld
cat kmain.c
cat log.txt | tail -20
file mcsos/kernel.elf
ls src/kernel/arch/x86_64/
cat src/kernel/arch/x86_64/boot.s | head -30
file mcsos/kernel.elf
readelf -h mcsos/kernel.elf | grep -E "Class|Machine|Entry"
ls src/kernel/arch/x86_64/
python3 << 'PYEOF'
addition = """
# ================================================================
# M9 - Kernel ELF build (Multiboot + scheduler)
# ================================================================
KERNEL_SRCS := src/kernel/arch/x86_64/boot.s \\
               src/kernel/arch/x86_64/idt.c \\
               src/kernel/arch/x86_64/isr.s \\
               src/kernel/arch/x86_64/stubs.c \\
               src/kernel/arch/x86_64/trap.c \\
               kernel/arch/x86_64/idt.c \\
               kernel/core/trap.c \\
               kernel/kmain.c \\
               kernel/mcsos_thread.c \\
               arch/x86_64/context_switch.S

KERNEL_ELF  := build/m9/kernel_m9.elf

KERNEL_CFLAGS := -target x86_64-unknown-none-elf -std=c17 \\
                 -ffreestanding -fno-stack-protector -fno-pic \\
                 -mno-red-zone -Wall -Wextra -Werror \\
                 -Iinclude \\
                 -Ikernel/arch/x86_64/include \\
                 -Imcsos/kernel \\
                 -Imcsos

.PHONY: m9-kernel m9-qemu

m9-kernel: $(BUILD_M9)
\\tclang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector \\
\\t  -fno-pic -mno-red-zone \\
\\t  -c src/kernel/arch/x86_64/boot.s -o $(BUILD_M9)/boot.o
\\tclang $(KERNEL_CFLAGS) -c src/kernel/arch/x86_64/idt.c   -o $(BUILD_M9)/idt_src.o
\\tclang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector \\
\\t  -fno-pic -mno-red-zone \\
\\t  -c src/kernel/arch/x86_64/isr.s -o $(BUILD_M9)/isr.o
\\tclang $(KERNEL_CFLAGS) -c src/kernel/arch/x86_64/stubs.c -o $(BUILD_M9)/stubs.o
\\tclang $(KERNEL_CFLAGS) -c src/kernel/arch/x86_64/trap.c  -o $(BUILD_M9)/trap_src.o
\\tclang $(KERNEL_CFLAGS) -c kernel/arch/x86_64/idt.c       -o $(BUILD_M9)/idt_kern.o
\\tclang $(KERNEL_CFLAGS) -c kernel/core/trap.c             -o $(BUILD_M9)/trap_kern.o
\\tclang $(KERNEL_CFLAGS) -c kernel/kmain.c                 -o $(BUILD_M9)/kmain.o
\\tclang $(KERNEL_CFLAGS) -c kernel/mcsos_thread.c          -o $(BUILD_M9)/mcsos_thread.o
\\tclang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector \\
\\t  -fno-pic -mno-red-zone \\
\\t  -c arch/x86_64/context_switch.S -o $(BUILD_M9)/context_switch.o
\\tld.lld -T linker.ld --no-dynamic-linker \\
\\t  $(BUILD_M9)/boot.o \\
\\t  $(BUILD_M9)/idt_src.o \\
\\t  $(BUILD_M9)/isr.o \\
\\t  $(BUILD_M9)/stubs.o \\
\\t  $(BUILD_M9)/trap_src.o \\
\\t  $(BUILD_M9)/idt_kern.o \\
\\t  $(BUILD_M9)/trap_kern.o \\
\\t  $(BUILD_M9)/kmain.o \\
\\t  $(BUILD_M9)/mcsos_thread.o \\
\\t  $(BUILD_M9)/context_switch.o \\
\\t  -o $(KERNEL_ELF)
\\techo "Kernel ELF built: $(KERNEL_ELF)"

m9-qemu: m9-kernel
\\tqemu-system-x86_64 \\
\\t  -kernel $(KERNEL_ELF) \\
\\t  -serial stdio \\
\\t  -display none \\
\\t  -no-reboot \\
\\t  -m 128M
"""
with open("Makefile", "a") as f:
    f.write(addition)
print("Makefile updated OK")
PYEOF

grep -n "m9-kernel\|m9-qemu\|KERNEL_ELF" Makefile
make m9-kernel 2>&1 | tee build/m9_kernel_build.log
python3 << 'PYEOF'
with open("Makefile") as f:
    content = f.read()

# Hapus bagian kernel yang rusak (dari baris KERNEL_SRCS ke bawah)
cut = content.find("\n# ================================================================\n# M9 - Kernel ELF")
if cut != -1:
    content = content[:cut]

addition = """
# ================================================================
# M9 - Kernel ELF build (Multiboot + scheduler)
# ================================================================
KERNEL_ELF   := build/m9/kernel_m9.elf
KERNEL_CFLAGS := -target x86_64-unknown-none-elf -std=c17 \\
\t\t\t\t -ffreestanding -fno-stack-protector -fno-pic \\
\t\t\t\t -mno-red-zone -Wall -Wextra -Werror \\
\t\t\t\t -Iinclude -Ikernel/arch/x86_64/include -Imcsos

.PHONY: m9-kernel m9-qemu

m9-kernel: $(BUILD_M9)
\tclang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -c src/kernel/arch/x86_64/boot.s -o $(BUILD_M9)/boot.o
\tclang $(KERNEL_CFLAGS) -c src/kernel/arch/x86_64/idt.c   -o $(BUILD_M9)/idt_src.o
\tclang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -c src/kernel/arch/x86_64/isr.s -o $(BUILD_M9)/isr.o
\tclang $(KERNEL_CFLAGS) -c src/kernel/arch/x86_64/stubs.c -o $(BUILD_M9)/stubs.o
\tclang $(KERNEL_CFLAGS) -c src/kernel/arch/x86_64/trap.c  -o $(BUILD_M9)/trap_src.o
\tclang $(KERNEL_CFLAGS) -c kernel/arch/x86_64/idt.c       -o $(BUILD_M9)/idt_kern.o
\tclang $(KERNEL_CFLAGS) -c kernel/core/trap.c             -o $(BUILD_M9)/trap_kern.o
\tclang $(KERNEL_CFLAGS) -c kernel/kmain.c                 -o $(BUILD_M9)/kmain.o
\tclang $(KERNEL_CFLAGS) -c kernel/mcsos_thread.c          -o $(BUILD_M9)/mcsos_thread.o
\tclang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -c arch/x86_64/context_switch.S -o $(BUILD_M9)/context_switch.o
\tld.lld -T linker.ld --no-dynamic-linker $(BUILD_M9)/boot.o $(BUILD_M9)/idt_src.o $(BUILD_M9)/isr.o $(BUILD_M9)/stubs.o $(BUILD_M9)/trap_src.o $(BUILD_M9)/idt_kern.o $(BUILD_M9)/trap_kern.o $(BUILD_M9)/kmain.o $(BUILD_M9)/mcsos_thread.o $(BUILD_M9)/context_switch.o -o $(KERNEL_ELF)
\techo "Kernel ELF built: $(KERNEL_ELF)"

m9-qemu: m9-kernel
\tqemu-system-x86_64 -kernel $(KERNEL_ELF) -serial stdio -display none -no-reboot -m 128M
"""

with open("Makefile", "w") as f:
    f.write(content + addition)
print("Done")
PYEOF

cat -A Makefile | grep "clang\|ld.lld\|qemu" | head -5
tail -20 Makefile
python3 << 'PYEOF'
with open("Makefile") as f:
    lines = f.readlines()

fixed = []
in_recipe = False
for line in lines:
    # Deteksi baris target (tidak dimulai tab/spasi, ada ':')
    stripped = line.rstrip('\n')
    if stripped and not stripped[0] in (' ', '\t', '#') and ':' in stripped:
        in_recipe = True
        fixed.append(line)
    elif in_recipe and stripped.startswith('        '):
        # 8 spasi -> TAB
        fixed.append('\t' + stripped.lstrip() + '\n')
    elif in_recipe and stripped.startswith('    '):
        # 4 spasi -> TAB
        fixed.append('\t' + stripped.lstrip() + '\n')
    else:
        if not stripped:
            in_recipe = False
        fixed.append(line)

with open("Makefile", "w") as f:
    f.writelines(fixed)
print("Fixed")
PYEOF

cat -A Makefile | grep "clang\|qemu\|echo" | head -5
make m9-kernel 2>&1 | tee build/m9_kernel_build.log
python3 << 'PYEOF'
with open("Makefile") as f:
    content = f.read()

content = content.replace(
    "-Iinclude -Ikernel/arch/x86_64/include -Imcsos",
    "-Iinclude -Ikernel/arch/x86_64/include -Imcsos -I."
)

with open("Makefile", "w") as f:
    f.write(content)
print("Done")
PYEOF

grep "KERNEL_CFLAGS" Makefile | head -3
make m9-clean && make m9-all && make m9-kernel 2>&1 | tee build/m9_kernel_build.log
cat mcsos/kernel/panic.h
grep -r "KERNEL_ASSERT" . --include="*.h" --include="*.c" | grep -v ".git"
head -20 kernel/arch/x86_64/idt.c
python3 << 'PYEOF'
with open("mcsos/kernel/panic.h") as f:
    content = f.read()

# Tambahkan KERNEL_ASSERT sebelum #endif
assert_macro = """
#define KERNEL_ASSERT(expr) do { \\
    if (!(expr)) { \\
        kernel_panic_at(__FILE__, __LINE__, #expr); \\
    } \\
} while (0)
"""

content = content.replace("#endif", assert_macro + "\n#endif")

with open("mcsos/kernel/panic.h", "w") as f:
    f.write(content)
print("Done")
PYEOF

cat mcsos/kernel/panic.h
make m9-kernel 2>&1 | tee build/m9_kernel_build.log
grep -n "x86_64_trigger_breakpoint_for_test" kernel/arch/x86_64/idt.c kernel/core/trap.c
python3 << 'PYEOF'
with open("Makefile") as f:
    content = f.read()

content = content.replace(
    "$(BUILD_M9)/trap_kern.o $(BUILD_M9)/kmain.o",
    "$(BUILD_M9)/kmain.o"
)

with open("Makefile", "w") as f:
    f.write(content)
print("Done")
PYEOF

grep "trap_kern\|kmain.o" Makefile
make m9-kernel 2>&1 | tee build/m9_kernel_build.log
grep -n "x86_64_trigger_breakpoint_for_test" kernel/core/trap.c
sed -n '25,35p' kernel/core/trap.c
python3 << 'PYEOF'
with open("kernel/core/trap.c") as f:
    content = f.read()

# Hapus fungsi duplikat beserta komentarnya
to_remove = """// Fungsi pemicu interupsi breakpoint untuk kebutuhan pengujian M4
void x86_64_trigger_breakpoint_for_test(void) {
    __asm__ volatile("int $3");
}"""

content = content.replace(to_remove, "")

with open("kernel/core/trap.c", "w") as f:
    f.write(content)
print("Done")
PYEOF

grep -n "trigger_breakpoint" kernel/core/trap.c
# harus kosong
python3 << 'PYEOF'
with open("Makefile") as f:
    content = f.read()

content = content.replace(
    "$(BUILD_M9)/kmain.o",
    "$(BUILD_M9)/trap_kern.o $(BUILD_M9)/kmain.o",
    1  # hanya replace pertama kali
)

with open("Makefile", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>&1 | tee build/m9_kernel_build.log
python3 << 'PYEOF'
with open("Makefile") as f:
    content = f.read()

# Perbaiki baris compile kmain yang terkontaminasi
content = content.replace(
    "-c kernel/kmain.c                 -o $(BUILD_M9)/trap_kern.o $(BUILD_M9)/kmain.o",
    "-c kernel/kmain.c                 -o $(BUILD_M9)/kmain.o"
)

# Pastikan trap_kern.o ada di baris ld.lld
content = content.replace(
    "$(BUILD_M9)/idt_kern.o $(BUILD_M9)/kmain.o",
    "$(BUILD_M9)/idt_kern.o $(BUILD_M9)/trap_kern.o $(BUILD_M9)/kmain.o"
)

with open("Makefile", "w") as f:
    f.write(content)
print("Done")
PYEOF

grep -n "kmain\|trap_kern\|ld.lld" Makefile | tail -10
make m9-kernel 2>&1 | tee build/m9_kernel_build.log
[200~grep -rn "x86_64_exception_stubs" . --include="*.s" --include="*.S" --include="*.c" --include="*.h" | grep -v ".git"~
grep -rn "x86_64_exception_stubs" . --include="*.s" --include="*.S" --include="*.c" --include="*.h"
python3 << 'PYEOF'
with open("Makefile") as f:
    content = f.read()

# Tambah compile isr.S
content = content.replace(
    "\tclang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -c arch/x86_64/context_switch.S -o $(BUILD_M9)/context_switch.o",
    "\tclang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -c arch/x86_64/context_switch.S -o $(BUILD_M9)/context_switch.o\n\tclang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -c kernel/arch/x86_64/isr.S -o $(BUILD_M9)/isr_kern.o"
)

# Tambah isr_kern.o ke ld.lld
content = content.replace(
    "$(BUILD_M9)/context_switch.o -o $(KERNEL_ELF)",
    "$(BUILD_M9)/context_switch.o $(BUILD_M9)/isr_kern.o -o $(KERNEL_ELF)"
)

with open("Makefile", "w") as f:
    f.write(content)
print("Done")
PYEOF

grep -n "isr_kern" Makefile
make m9-kernel 2>&1 | tee build/m9_kernel_build.log
make m9-qemu 2>&1 | tee build/m9_qemu.log
qemu-system-x86_64   -kernel build/m9/kernel_m9.elf   -serial stdio   -display none   -no-reboot   -m 128M   -append "" 2>&1 | tee build/m9_qemu.log
readelf -h build/m9/kernel_m9.elf | grep -E "Class|Machine|Type|Entry"
objdump -d build/m9/kernel_m9.elf | head -30
which grub-mkrescue grub2-mkrescue 2>/dev/null
grub-mkrescue --version 2>/dev/null || grub2-mkrescue --version 2>/dev/null
xorriso --version 2>/dev/null | head -1
sudo apt-get install -y grub-pc-bin grub-common xorriso mtools
which grub-mkrescue
grub-mkrescue --version
python3 << 'PYEOF'
with open("Makefile") as f:
    content = f.read()

addition = """
# ================================================================
# M9 - ISO + QEMU via GRUB
# ================================================================
ISO_DIR := build/m9/iso
KERNEL_ISO := build/m9/kernel_m9.iso

.PHONY: m9-iso m9-qemu-iso

m9-iso: m9-kernel
\tmkdir -p $(ISO_DIR)/boot/grub
\tcp $(KERNEL_ELF) $(ISO_DIR)/boot/kernel_m9.elf
\tprintf 'set timeout=0\\nset default=0\\nmenuentry "MCSOS M9" {\\n  multiboot2 /boot/kernel_m9.elf\\n  boot\\n}\\n' > $(ISO_DIR)/boot/grub/grub.cfg
\tgrub-mkrescue -o $(KERNEL_ISO) $(ISO_DIR) 2>&1
\techo "ISO built: $(KERNEL_ISO)"

m9-qemu-iso: m9-iso
\tqemu-system-x86_64 \\
\t  -cdrom $(KERNEL_ISO) \\
\t  -serial stdio \\
\t  -display none \\
\t  -no-reboot \\
\t  -m 128M
"""

with open("Makefile", "w") as f:
    f.write(content + addition)
print("Done")
PYEOF

cat -A Makefile | grep "mkdir\|grub-mk\|qemu" | tail -5
make m9-qemu-iso 2>&1 | tee build/m9_qemu.log
nano kernel/kmain.c
head -5 kernel/kmain.c
grep "log_init" kernel/kmain.c
make m9-qemu-iso 2>&1 | timeout 8 tee build/m9_qemu.log; cat build/m9_qemu.log | grep "\[M"
head -10 src/kernel/arch/x86_64/boot.s
python3 << 'PYEOF'
with open("Makefile") as f:
    content = f.read()

content = content.replace(
    "multiboot2 /boot/kernel_m9.elf",
    "multiboot /boot/kernel_m9.elf"
)

with open("Makefile", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-iso 2>/dev/null
qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M &
sleep 6
kill %1 2>/dev/null
cat build/m9/serial.log
timeout 10 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M
cat build/m9/serial.log
objdump -d build/m9/kernel_m9.elf | grep -A5 "_start"
xxd build/m9/kernel_m9.elf | grep "d0 02 b0 01\|02 b0 ad 1b" | head -3
user@DESKTOP-9H6BVAA:~/mcsos$ objdump -d build/m9/kernel_m9.elf | grep -A5 "_start"
xxd build/m9/kernel_m9.elf | grep "d0 02 b0 01\|02 b0 ad 1b" | head -3
0000000000100470 <_start>:
000000000010047c <.loop>:
user@DESKTOP-9H6BVAA:~/mcsos$
cat linker.ld
python3 << 'PYEOF'
content = """ENTRY(_start)
SECTIONS
{
    . = 0x100000;
    .multiboot : { *(.multiboot) }
    .text : { *(.text) }
    .rodata : { *(.rodata) }
    .data : { *(.data) }
    .bss  : { *(.bss) COMMON }
}
"""
with open("linker.ld", "w") as f:
    f.write(content)
print("Done")
PYEOF

cat linker.ld
make m9-iso 2>/dev/null && timeout 10 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M
cat build/m9/serial.log
xxd build/m9/kernel_m9.elf | head -5
objdump -h build/m9/kernel_m9.elf | grep -E "multiboot|\.text|\.data"
python3 << 'PYEOF'
content = """ENTRY(_start)
SECTIONS
{
    . = 0x100000;
    .multiboot ALIGN(4) : { *(.multiboot) }
    .text ALIGN(16) : { *(.text) }
    .rodata ALIGN(4) : { *(.rodata) }
    .data ALIGN(4) : { *(.data) }
    .bss ALIGN(4) : {
        *(.bss)
        *(COMMON)
    }
}
"""
with open("linker.ld", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null
objdump -h build/m9/kernel_m9.elf | grep -E "multiboot|\.text"
cat src/kernel/arch/x86_64/boot.s
python3 << 'PYEOF'
content = """\t.section .text
\t.align 4
\t/* Multiboot1 header - harus dalam 8KB pertama */
\t.long 0x1BADB002
\t.long 0x00
\t.long -(0x1BADB002 + 0x00)

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

python3 << 'PYEOF'
content = """ENTRY(_start)
SECTIONS
{
    . = 0x100000;
    .text : { *(.text) }
    .rodata : { *(.rodata) }
    .data : { *(.data) }
    .bss : { *(.bss) *(COMMON) }
}
"""
with open("linker.ld", "w") as f:
    f.write(content)
print("Done")
PYEOF

make m9-kernel 2>/dev/null
xxd build/m9/kernel_m9.elf | grep -m1 "02 b0 ad 1b\|1b ad b0 02"
objdump -h build/m9/kernel_m9.elf | grep "\.text\|\.bss"
xxd build/m9/kernel_m9.elf | grep -A2 "00100000\|00001000" | head -5
dd if=build/m9/kernel_m9.elf bs=1 skip=4096 count=16 2>/dev/null | xxd
make m9-iso 2>/dev/null
timeout 10 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M
cat build/m9/serial.log
timeout 10 qemu-system-x86_64   -cdrom build/m9/kernel_m9.iso   -serial file:build/m9/serial.log   -display none   -no-reboot   -m 128M   -d int,cpu_reset   -D build/m9/qemu_debug.log 2>/dev/null
cat build/m9/qemu_debug.log | head -30
cat build/m9/serial.log
python3 << 'PYEOF'
content = """\t.section .text
\t.align 8

\t/* ---- Multiboot2 header ---- */
\t.long 0xe85250d6          /* magic */
\t.long 0                   /* architecture: i386 */
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
