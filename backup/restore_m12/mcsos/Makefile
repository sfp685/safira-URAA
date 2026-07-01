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

# ================================================================
# M9 - Kernel ELF build (Multiboot + scheduler)
# ================================================================
KERNEL_ELF   := build/m9/kernel_m9.elf
KERNEL_CFLAGS := -target x86_64-unknown-none-elf -std=c17 \
				 -ffreestanding -fno-stack-protector -fno-pic \
				 -mno-red-zone -Wall -Wextra -Werror \
				 -Iinclude -Ikernel/arch/x86_64/include -Imcsos -I.

.PHONY: m9-kernel m9-qemu

m9-kernel: $(BUILD_M9)
	clang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -c src/kernel/arch/x86_64/boot.s -o $(BUILD_M9)/boot.o
	clang $(KERNEL_CFLAGS) -c src/kernel/arch/x86_64/idt.c   -o $(BUILD_M9)/idt_src.o
	clang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -c src/kernel/arch/x86_64/isr.s -o $(BUILD_M9)/isr.o
	clang $(KERNEL_CFLAGS) -c src/kernel/arch/x86_64/stubs.c -o $(BUILD_M9)/stubs.o
	clang $(KERNEL_CFLAGS) -c src/kernel/arch/x86_64/trap.c  -o $(BUILD_M9)/trap_src.o
	clang $(KERNEL_CFLAGS) -c kernel/arch/x86_64/idt.c       -o $(BUILD_M9)/idt_kern.o
	clang $(KERNEL_CFLAGS) -c kernel/core/trap.c             -o $(BUILD_M9)/trap_kern.o
	clang $(KERNEL_CFLAGS) -DMCSOS_HOST_TEST -c kernel/kmain.c -o $(BUILD_M9)/kmain.o
	clang $(KERNEL_CFLAGS) -DMCSOS_HOST_TEST -c kernel/mcsos_thread.c -o $(BUILD_M9)/mcsos_thread.o
	clang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -c arch/x86_64/context_switch.S -o $(BUILD_M9)/context_switch.o
	clang -target x86_64-unknown-none-elf -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -c kernel/arch/x86_64/isr.S -o $(BUILD_M9)/isr_kern.o
	clang $(KERNEL_CFLAGS) -I. -c kernel/sync/lockdep.c  -o $(BUILD_M9)/lockdep.o
	clang $(KERNEL_CFLAGS) -I. -c kernel/sync/spinlock.c -o $(BUILD_M9)/spinlock.o
	clang $(KERNEL_CFLAGS) -I. -c kernel/sync/mutex.c    -o $(BUILD_M9)/mutex.o
	clang $(KERNEL_CFLAGS) -I. -c kernel/sync/selftest.c -o $(BUILD_M9)/selftest.o
	ld.lld -T linker.ld --no-dynamic-linker $(BUILD_M9)/boot.o $(BUILD_M9)/idt_src.o $(BUILD_M9)/isr.o $(BUILD_M9)/stubs.o $(BUILD_M9)/trap_src.o $(BUILD_M9)/idt_kern.o $(BUILD_M9)/trap_kern.o $(BUILD_M9)/kmain.o $(BUILD_M9)/mcsos_thread.o $(BUILD_M9)/context_switch.o $(BUILD_M9)/isr_kern.o $(BUILD_M9)/lockdep.o $(BUILD_M9)/spinlock.o $(BUILD_M9)/mutex.o $(BUILD_M9)/selftest.o -o $(KERNEL_ELF)
	echo "Kernel ELF built: $(KERNEL_ELF)"

m9-qemu: m9-kernel
	qemu-system-x86_64 -kernel $(KERNEL_ELF) -serial stdio -display none -no-reboot -m 128M

# ================================================================
# M9 - ISO + QEMU via GRUB
# ================================================================
ISO_DIR := build/m9/iso
KERNEL_ISO := build/m9/kernel_m9.iso

.PHONY: m9-iso m9-qemu-iso

m9-iso: m9-kernel
	mkdir -p $(ISO_DIR)/boot/grub
	cp $(KERNEL_ELF) $(ISO_DIR)/boot/kernel_m9.elf
	printf 'set timeout=0\nset default=0\nmenuentry "MCSOS M9" {\n  multiboot2 /boot/kernel_m9.elf\n  boot\n}\n' > $(ISO_DIR)/boot/grub/grub.cfg
	grub-mkrescue -o $(KERNEL_ISO) $(ISO_DIR) 2>&1
	echo "ISO built: $(KERNEL_ISO)"

m9-qemu-iso: m9-iso
	qemu-system-x86_64 \
	  -cdrom $(KERNEL_ISO) \
	  -serial stdio \
	  -display none \
	  -no-reboot \
	  -m 128M
