BUILD_DIR := build
ISO_DIR := $(BUILD_DIR)/isodir
KERNEL := $(BUILD_DIR)/kernel.elf
ISO := $(BUILD_DIR)/mcsos.iso
MAP := $(BUILD_DIR)/kernel.map
CC := clang
LD := ld.lld
CFLAGS := -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Isrc/kernel/arch/x86_64 -Isrc/kernel -I. -Iinclude
LDFLAGS := -nostdlib -static -z max-page-size=0x1000 -T linker.ld -Map=$(MAP)

.PHONY: all iso run clean
all: $(KERNEL)

$(KERNEL):
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c src/kernel/arch/x86_64/boot.s -o $(BUILD_DIR)/boot.o
	$(CC) $(CFLAGS) -c kmain.c -o $(BUILD_DIR)/kmain.o
	$(CC) $(CFLAGS) -c src/kernel/arch/x86_64/idt.c -o $(BUILD_DIR)/idt.o
	$(CC) $(CFLAGS) -c src/kernel/arch/x86_64/trap.c -o $(BUILD_DIR)/trap.o
	$(CC) $(CFLAGS) -c src/kernel/arch/x86_64/stubs.c -o $(BUILD_DIR)/stubs.o
	$(CC) $(CFLAGS) -c src/kernel/arch/x86_64/isr.s -o $(BUILD_DIR)/isr.o
	$(CC) $(CFLAGS) -c kernel/block/block.c -o $(BUILD_DIR)/block.o
	$(CC) $(CFLAGS) -c kernel/block/ramblk.c -o $(BUILD_DIR)/ramblk.o
	$(CC) $(CFLAGS) -c kernel/block/bcache.c -o $(BUILD_DIR)/bcache.o
	$(CC) $(CFLAGS) -c kernel/block/block_demo.c -o $(BUILD_DIR)/block_demo.o
	$(LD) $(LDFLAGS) -o $(KERNEL) $(BUILD_DIR)/boot.o $(BUILD_DIR)/kmain.o $(BUILD_DIR)/idt.o $(BUILD_DIR)/trap.o $(BUILD_DIR)/stubs.o $(BUILD_DIR)/isr.o $(BUILD_DIR)/block.o $(BUILD_DIR)/ramblk.o $(BUILD_DIR)/bcache.o $(BUILD_DIR)/block_demo.o

iso: $(KERNEL)
	mkdir -p $(ISO_DIR)/boot/grub
	cp $(KERNEL) $(ISO_DIR)/boot/kernel.elf
	cp build/isodir/boot/grub/grub.cfg $(ISO_DIR)/boot/grub/grub.cfg 2>/dev/null || true
	echo 'serial --unit=0 --speed=9600' > $(ISO_DIR)/boot/grub/grub.cfg
	echo 'terminal_input serial' >> $(ISO_DIR)/boot/grub/grub.cfg
	echo 'terminal_output serial' >> $(ISO_DIR)/boot/grub/grub.cfg
	echo 'set timeout=0' >> $(ISO_DIR)/boot/grub/grub.cfg
	echo 'set timeout_style=hidden' >> $(ISO_DIR)/boot/grub/grub.cfg
	echo 'set default=0' >> $(ISO_DIR)/boot/grub/grub.cfg
	echo 'menuentry "MCSOS" {' >> $(ISO_DIR)/boot/grub/grub.cfg
	echo '    multiboot /boot/kernel.elf' >> $(ISO_DIR)/boot/grub/grub.cfg
	echo '    boot' >> $(ISO_DIR)/boot/grub/grub.cfg
	echo '}' >> $(ISO_DIR)/boot/grub/grub.cfg
	grub-mkrescue -o $(ISO) $(ISO_DIR)

run: iso
	qemu-system-x86_64 -machine q35 -m 256M -nographic -cdrom $(ISO)

clean:
	rm -rf $(BUILD_DIR)
