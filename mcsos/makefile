BUILD_DIR := build
KERNEL := $(BUILD_DIR)/kernel.elf
MAP := $(BUILD_DIR)/kernel.map
CC := clang
LD := ld.lld
CFLAGS := -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -mcmodel=kernel -Isrc/kernel/arch/x86_64 -Isrc/kernel -I. -Iinclude
LDFLAGS := -nostdlib -static -z max-page-size=0x1000 -T linker.ld -Map=$(MAP)
.PHONY: all clean run
all: $(KERNEL)
clean:
	rm -rf $(BUILD_DIR)
run: $(KERNEL)
	qemu-system-x86_64 -cpu qemu64 -display none -serial stdio -device loader,file=$(KERNEL),addr=0x100000
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
	$(LD) $(LDFLAGS) -o $(KERNEL) $(BUILD_DIR)/boot.o $(BUILD_DIR)/kmain.o $(BUILD_DIR)/idt.o $(BUILD_DIR)/trap.o $(BUILD_DIR)/stubs.o $(BUILD_DIR)/isr.o $(BUILD_DIR)/block.o $(BUILD_DIR)/ramblk.o $(BUILD_DIR)/bcache.o
