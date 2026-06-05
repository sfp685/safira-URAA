CC      ?= clang
HOSTCC  ?= cc
CFLAGS  := -std=c17 -Wall -Wextra -Werror -ffreestanding -fno-builtin -fno-stack-protector -mno-red-zone -Iinclude
HOST_CFLAGS := -std=c17 -Wall -Wextra -Werror -DMCSOS_HOST_TEST -Iinclude

all: build/vmm.o build/test_vmm_host

build/vmm.o: src/vmm.c include/vmm.h include/types.h
	mkdir -p build
	$(CC) $(CFLAGS) -c src/vmm.c -o build/vmm.o

build/test_vmm_host: src/vmm.c tests/test_vmm_host.c include/vmm.h include/types.h
	mkdir -p build
	$(HOSTCC) $(HOST_CFLAGS) src/vmm.c tests/test_vmm_host.c -o build/test_vmm_host

check: all
	./build/test_vmm_host
	nm -u build/vmm.o
	objdump -dr build/vmm.o > build/vmm.objdump.txt
	grep -q "invlpg" build/vmm.objdump.txt
	grep -q "cr3" build/vmm.objdump.txt
	@echo "[PASS] semua check M7 lulus"

clean:
	rm -rf build
