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
