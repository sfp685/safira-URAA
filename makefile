SHELL := /usr/bin/env bash

BUILD_DIR := build
KERNEL := $(BUILD_DIR)/kernel.elf
CC := clang
LD := ld.lld

SRC_C := $(shell find kernel src -name "*.c")
SRC_S := $(shell find src kernel -name "*.s")
SRC_S_UPPER := $(shell find src kernel -name "*.S")

OBJ_FILES := $(patsubst %.c, $(BUILD_DIR)/%.o, $(SRC_C)) \
             $(patsubst %.s, $(BUILD_DIR)/%.o, $(SRC_S)) \
             $(patsubst %.S, $(BUILD_DIR)/%.o, $(SRC_S_UPPER))

CFLAGS := -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -Iinclude -Ilimine -Ikernel
ASFLAGS := -x assembler-with-cpp -m64
LDFLAGS := -nostdlib -static -z max-page-size=0x1000 -T linker.ld

all: $(KERNEL)

$(KERNEL): $(OBJ_FILES)
	$(LD) $(LDFLAGS) -o $(KERNEL) $(OBJ_FILES)

$(BUILD_DIR)/%.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.s
	mkdir -p $(dir $@)
	$(CC) $(ASFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.S
	mkdir -p $(dir $@)
	$(CC) $(ASFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR)
