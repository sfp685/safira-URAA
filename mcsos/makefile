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
	$(LD) $(LDFLAGS) -o $(KERNEL) $(BUILD_DIR)/boot.o $(BUILD_DIR)/kmain.o $(BUILD_DIR)/idt.o $(BUILD_DIR)/trap.o $(BUILD_DIR)/stubs.o $(BUILD_DIR)/isr.o $(BUILD_DIR)/block.o $(BUILD_DIR)/ramblk.o $(BUILD_DIR)/bcache.o

iso: $(KERNEL)
	mkdir -p $(ISO_DIR)/boot/grub
	cp $(KERNEL) $(ISO_DIR)/boot/kernel.elf
	echo 'set timeout=0' > $(ISO_DIR)/boot/grub/grub.cfg
	echo 'set default=0' >> $(ISO_DIR)/boot/grub/grub.cfg
	echo 'menuentry "MCSOS" {' >> $(ISO_DIR)/boot/grub/grub.cfg
	echo '    multiboot /boot/kernel.elf' >> $(ISO_DIR)/boot/grub/grub.cfg
	echo '    boot' >> $(ISO_DIR)/boot/grub/grub.cfg
	echo '}' >> $(ISO_DIR)/boot/grub/grub.cfg
	grub-mkrescue -o $(ISO) $(ISO_DIR)

run: iso
	qemu-system-x86_64 -machine q35 -m 256M -serial stdio -cdrom $(ISO)

clean:
	rm -rf $(BUILD_DIR)
# ============================================================
# M14 CHECKPOINT TARGETS
# ============================================================

.PHONY: host-test freestanding audit

host-test:
	mkdir -p artifacts/m14
	@echo "=== M14 HOST TEST ===" | tee artifacts/m14/m14_make_all.log
	$(MAKE) all 2>&1 | tee -a artifacts/m14/m14_make_all.log

freestanding:
	mkdir -p artifacts/m14
	$(MAKE) clean
	$(MAKE) all
	@test -f build/block.o
	@test -f build/ramblk.o
	@test -f build/bcache.o
	@echo "[OK] Freestanding objects built."

audit:
	mkdir -p artifacts/m14
	nm -u build/kernel.elf | tee artifacts/m14/m14_nm_undefined.txt
	readelf -h build/kernel.elf | tee artifacts/m14/m14_readelf.txt
	objdump -d build/kernel.elf | tee artifacts/m14/m14_objdump.txt
	sha256sum build/kernel.elf | tee artifacts/m14/m14_sha256.txt
