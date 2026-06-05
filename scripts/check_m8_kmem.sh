#!/usr/bin/env bash
set -euo pipefail
echo '[M8] checking files...'
for f in include/mcsos/kmem.h kernel/mm/kmem.c tests/test_kmem.c Makefile; do
  [[ -f "$f" ]] || { echo "[FAIL] missing $f"; exit 1; }
done
echo '[M8] checking toolchain...'
command -v clang && command -v nm && command -v readelf && command -v objdump
echo '[M8] freestanding audit...'
mkdir -p build/m8
clang -std=c17 -Wall -Wextra -Werror -ffreestanding -fno-builtin \
  -Iinclude -c kernel/mm/kmem.c -o build/m8/kmem.freestanding.o
nm -u build/m8/kmem.freestanding.o | tee build/m8/nm_u.txt
[[ -s build/m8/nm_u.txt ]] && { echo '[FAIL] unresolved symbols'; exit 1; }
readelf -h build/m8/kmem.freestanding.o > build/m8/readelf_h.txt
echo '[M8] host unit test...'
clang -std=c17 -Wall -Wextra -Werror -Iinclude \
  tests/test_kmem.c kernel/mm/kmem.c -o build/m8/test_kmem
./build/m8/test_kmem | tee build/m8/test_kmem.log
grep -q 'PASS' build/m8/test_kmem.log
echo '[PASS] M8 preflight completed.'
