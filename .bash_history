wsl --set-default-version 2
notepad $env:USERPROFILE\.wslconfig
wsl --shutdown
wsl --status
/home/<username>/src/mcsos
sudo apt update && sudo apt upgrade -y
sudo apt install -y \ build-essential git make cmake ninja-build pkg-config \ clang lld llvm binutils nasm \ qemu-system-x86 qemu-utils ovmf \ gdb gdb-multiarch \ xorriso mtools dosfstools parted gdisk \ python3 python3-pip python3-venv \ shellcheck cppcheck clang-tidy \ curl wget ca-certificates unzip tree file xxd
sudo apt install build-essential git make cmake ninja-build pkg-config clang lld llvm qemu-system-x86 qemu-utils ovmf gdb gdb-multiarch xorriso dosfstools parted gdisk mtool python3 python3-pip python3-venv shellcheck cppcheck clang-tidy curl wget ca-certificates unzip tree file xxd
sudo apt install build-essential git make cmake ninja-build pkg-config clang lld llvm qemu-system-x86 qemu-utils ovmf gdb gdb-multiarch xorriso dosfstools parted gdisk mtools python3 python3-pip python3-venv shellcheck cppcheck clang-tidy curl wget ca-certificates unzip tree file xxd
for tool in git make cmake ninja clang ld.lld llvm-readelf llvm-objdump readelf objdump nasm qemu-system-x86_64 gdb python3 shellcheck cppcheck; do printf "%-24s" "$tool" command -v "$tool" || true done; EOF
for tool in git make cmake ninja clang ld.lld llvm-readelf llvm-objdump readelf objdump nasm qemu-system-x86_64 gdb python3 shellcheck cppcheck; do printf "%-24s" "$tool"; command -v "$tool" || true; done
git config --globalSafira"
git config --global user.email "safirafebriani64@gmail.com"
git config --global init.defaultBranch main
git config --global core.autocrlf input
git config --global pull.rebase false
git config --global --list | sort
git config --global user.name "Safira"
git config --global user.email "safirafebriani64@gmail.com
"
git config --global init.defaultBranch main
git config --global core.autocrlf input
git config --global --list | sort
main                  dikumpulkan dev                   : baseline stabil yang sudah dinilai atau siap : integrasi pekerjaan aktif m0/<nama-atau-kelompok>: branch khusus praktikum M0
mkdir -p ~/src
cd ~/src
mkdir -p mcsos
cd mcsos
git init
pwd
mkdir -p \ docs/adr \ docs/architecture \ docs/requirements \ docs/security \ docs/testing \ docs/governance \ docs/operations \ docs/reports \ tools \ smoke \ build/meta \ build/smoke
tree -a -L 3
sudo apt install -y build-essential bison flex libgmp-dev libmpc-dev libmpfr-dev texinfo libisl-dev
tree -a -L 3
git config --global --list | sort
mkdir -p docs/adr docs/architecture docs/requirements docs/security docs/testing docs/governance docs/operations docs/reports tools smoke build/meta build/smoke
clang --target=x86_64-unknown-none -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -Wall -Wextra -Werror -std=c17 -c smoke/freestanding.c -o build/smoke/freestanding.o
readelf -h build/smoke/freestanding.o | tee build/smoke/freestanding-header.txt
readelf -s build/smoke/freestanding.o | tee build/smoke/freestanding-symbols.txt
objdump -drwC build/smoke/freestanding.o | tee build/smoke/freestanding-objdump.txt
cat > .gitignore <<'EOF'
# Build artifacts
build/
*.o
*.elf
*.bin
*.iso
*.img
*.map
*.log

# Editor and OS noise
.vscode/
.idea/
.DS_Store
Thumbs.db

# Python cache
__pycache__/
*.pyc
EOF

cat > README.md <<'EOF'
# MCSOS 260502

MCSOS 260502 adalah proyek sistem operasi pendidikan bertahap untuk target x86_64 dengan host pengembangan Windows 11 x64 melalui WSL 2.

Status saat ini: M0 - baseline requirements, governance, dan lingkungan pengembangan reproducible.

Target awal:
- Arsitektur: x86_64
- Emulator: QEMU system x86_64
- Firmware emulator: OVMF / UEFI
- Bahasa kernel awal: freestanding C17 dan assembly x86_64 minimal
- Kernel model awal: monolithic educational kernel dengan boundary modular internal

Perintah awal:
```bash
make meta
make check
make smoke
EOF

cat > tools/check_env.sh <<'EOF'
#!/usr/bin/env bash
set -e

# Versi minimum yang dibutuhkan
REQUIRED_CLANG=14
REQUIRED_MAKE=4.0

echo "=== Memulai Validasi Lingkungan MCSOS ==="

# 1. Cek Clang
if command -v clang >/dev/null 2>&1; then
    CLANG_VER=$(clang --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 | cut -d. -f1)
    if [ "$CLANG_VER" -ge "$REQUIRED_CLANG" ]; then
        echo "[OK] Clang versi $CLANG_VER ditemukan."
    else
        echo "[ERROR] Clang versi $CLANG_VER terlalu lama. Butuh v$REQUIRED_CLANG+."
    fi
else
    echo "[ERROR] Clang tidak ditemukan."
fi

# 2. Cek Make
MAKE_VER=$(make --version | grep -oE '[0-9]+\.[0-9]+' | head -n1 | cut -d. -f1)
if [ "$MAKE_VER" -ge 4 ]; then
    echo "[OK] Make versi $MAKE_VER ditemukan."
else
    echo "[ERROR] Make terlalu lama."
fi

# 3. Cek struktur folder
if [ -d "docs" ] && [ -d "build" ] && [ -d "smoke" ]; then
    echo "[OK] Struktur direktori lengkap."
else
    echo "[ERROR] Struktur direktori tidak lengkap."
fi

echo "=== Validasi Selesai ==="
EOF

chmod +x tools/check_env.sh
./tools/check_env.sh
bash tools/check_env.sh
cat build/meta/toolchain-versions.txt
clang --target=x86_64-unknown-none -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -Wall -Wextra -Werror -std=c17 -c smoke/freestanding.c -o build/smoke/freestanding.o
bash tools/check_env.sh
=== Memulai Validasi Lingkungan MCSOS ===
cat > smoke/freestanding.c <<'EOF'
#include <stdint.h>
#include <stddef.h>

#define MCSOS_M0_MAGIC 0x4D435330u /* "MCS0" */

struct m0_smoke_record {
    uint32_t magic;
    uint32_t version;
    uintptr_t pointer_width;
    size_t size_width;
};

__attribute__((used))
const struct m0_smoke_record m0_smoke_record = {
    .magic = MCSOS_M0_MAGIC,
    .version = 260502u,
    .pointer_width = sizeof(void *),
    .size_width = sizeof(size_t),
};

int m0_smoke_add(int a, int b) {
    return a + b;
}
EOF

clang --target=x86_64-unknown-none -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -Wall -Wextra -Werror -std=c17 -c smoke/freestanding.c -o build/smoke/freestanding.o
sudo apt update && sudo apt install -y clang
bash tools/check_env.sh
cat > smoke/freestanding.c <<'EOF'
#include <stdint.h>
#include <stddef.h>

#define MCSOS_M0_MAGIC 0x4D435330u /* "MCS0" */

struct m0_smoke_record {
    uint32_t magic;
    uint32_t version;
    uintptr_t pointer_width;
    size_t size_width;
};

__attribute__((used))
const struct m0_smoke_record m0_smoke_record = {
    .magic = MCSOS_M0_MAGIC,
    .version = 260502u,
    .pointer_width = sizeof(void *),
    .size_width = sizeof(size_t),
};

int m0_smoke_add(int a, int b) {
    return a + b;
}
EOF

cat > Makefile <<'EOF'
.PHONY: meta check smoke qemu-version clean distclean tree

BUILD_DIR := build
SMOKE_DIR := smoke

meta:
	@bash tools/check_env.sh

check:
	@bash tools/check_env.sh
	@shellcheck tools/check_env.sh

smoke:
	@mkdir -p $(BUILD_DIR)/smoke
	clang --target=x86_64-unknown-none \
		-ffreestanding \
		-fno-stack-protector \
		-fno-pic \
		-mno-red-zone \
		-mno-mmx -mno-sse -mno-sse2 \
		-Wall -Wextra -Werror \
		-std=c17 \
		-c $(SMOKE_DIR)/freestanding.c \
		-o $(BUILD_DIR)/smoke/freestanding.o
	readelf -h $(BUILD_DIR)/smoke/freestanding.o | tee $(BUILD_DIR)/smoke/readelf-header.txt
	objdump -drwC $(BUILD_DIR)/smoke/freestanding.o | tee $(BUILD_DIR)/smoke/objdump.txt >/dev/null
	file $(BUILD_DIR)/smoke/freestanding.o | tee $(BUILD_DIR)/smoke/file.txt

qemu-version:
	@qemu-system-x86_64 --version
	@echo "QEMU exists. M0 does not boot a kernel image."

tree:
	@tree -a -L 3

clean:
	rm -rf $(BUILD_DIR)/smoke

distclean:
	rm -rf $(BUILD_DIR)
EOF

sudo apt update && sudo apt install -y build-essential bison flex libgmp-dev libmpc-dev libmpfr-dev texinfo libisl-dev
cat > docs/architecture/qemu_baseline.md <<'EOF'
# QEMU Baseline MCSOS 260502

Target awal MCSOS menggunakan QEMU system emulator untuk x86_64.

Baseline M0:
- M0 hanya memverifikasi keberadaan QEMU dan OVMF.
- M0 belum menjalankan kernel image.
- Jalur UEFI/OVMF akan digunakan pada milestone boot berikutnya.

Command template untuk M1/M2, belum wajib berhasil pada M0:
```bash
qemu-system-x86_64 \
    -machine q35 \
    -cpu qemu64 \
    -m 512M \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
    -serial file:build/qemu-serial.log \
    -display none \
    -no-reboot \
    -no-shutdown
EOF

mkdir -p docs/requirements
cat > docs/requirements/system_requirements.md <<'EOF'
# System Requirements MCSOS 260502 - Baseline M0

## Scope

Dokumen ini menetapkan requirement awal untuk proyek MCSOS 260502. Requirement pada M0 berfokus pada lingkungan, governance, dan evidence. Requirement runtime kernel akan diperinci pada milestone berikutnya.

| ID | Requirement | Rationale | Verification evidence |
|---|---|---|---|
| REQ-M0-001 | Repository MCSOS harus berada di filesystem Linux WSL, bukan `/mnt/c`. | Mengurangi risiko permission, case, dan IO mismatch. | Output `pwd` dan `tools/check_env.sh`. |
| REQ-M0-002 | Semua tool wajib harus terdeteksi oleh script validasi. | Build lanjutan tidak boleh bergantung pada tool manual tak tercatat. | Output `bash tools/check_env.sh`. |
| REQ-M0-003 | Versi toolchain harus dicatat pada `build/meta/toolchain-versions.txt`. | Traceability dan reproducibility. | Isi file metadata. |
| REQ-M0-004 | Repository harus memiliki struktur `docs`, `tools`, `smoke`, dan `build`. | Menyeragamkan artefak praktikum. | Output `tree -a -L 3`. |
| REQ-M0-005 | Smoke test harus menghasilkan object ELF64 x86-64 relocatable. | Validasi awal target toolchain. | Output `readelf -h`. |
| REQ-M0-006 | Proyek harus memiliki assumptions dan non-goals. | Mencegah scope creep dan klaim readiness berlebih. | `docs/requirements/assumptions_and_nongoals.md`. |
| REQ-M0-007 | Proyek harus memiliki ADR awal untuk toolchain dan boot baseline. | Keputusan teknis harus dapat dilacak. | `docs/adr/ADR-0001-toolchain-and-boot-baseline.md`. |
| REQ-M0-008 | Proyek harus memiliki threat model awal. | Security from phase 0. | `docs/security/threat_model.md`. |
| REQ-M0-009 | Proyek harus memiliki risk register. | Risiko teknis dan operasional harus dikelola. | `docs/governance/risk_register.md`. |
| REQ-M0-010 | Proyek harus memiliki verification matrix. | Setiap requirement harus punya bukti validasi. | `docs/testing/verification_matrix.md`. |
| REQ-M0-011 | Semua perubahan M0 harus dikomit ke Git. | Traceability penilaian. | `git log --oneline`. |
| REQ-M0-012 | Laporan M0 harus memuat log, command, screenshot seperlunya, commit hash, dan analisis failure mode. | Evidence-first assessment. | `docs/reports/M0-laporan.md`. |
EOF

cat > smoke/freestanding.c <<'EOF' #include <stdint.h> #include <stddef.h> #define MCSOS_M0_MAGIC 0x4D435330u /* "MCS0" */ struct m0_smoke_record { uint32_t magic; uint32_t version; uintptr_t pointer_width; size_t size_width; }; __attribute__((used)) const struct m0_smoke_record m0_smoke_record = { .magic = MCSOS_M0_MAGIC, .version = 260502u, .pointer_width = sizeof(void *), .size_width = sizeof(size_t), }; int m0_smoke_add(int a, int b) { return a + b; } EOF
EOF

clang --target=x86_64-unknown-none -ffreestanding -fno-stack-protector -fno-pic -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -Wall -Wextra -Werror -std=c17 -c smoke/freestanding.c -o build/smoke/freestanding.o
Command 'clang' not found, but can be installed with:
sudo apt install clang
readelf -h build/smoke/freestanding.o | tee build/smoke/readelf-header.txt objdump -drwC build/smoke/freestanding.o | tee build/smoke/objdump.txt file build/smoke/freestanding.o | tee build/smoke/file.txt
cat > Makefile <<'EOF'
.PHONY: meta check smoke qemu-version clean distclean tree

BUILD_DIR := build
SMOKE_DIR := smoke

meta:
	@bash tools/check_env.sh

check:
	@bash tools/check_env.sh
	@shellcheck tools/check_env.sh

smoke:
	@mkdir -p $(BUILD_DIR)/smoke
	clang --target=x86_64-unknown-none \
		-ffreestanding \
		-fno-stack-protector \
		-fno-pic \
		-mno-red-zone \
		-mno-mmx -mno-sse -mno-sse2 \
		-Wall -Wextra -Werror \
		-std=c17 \
		-c $(SMOKE_DIR)/freestanding.c \
		-o $(BUILD_DIR)/smoke/freestanding.o
	readelf -h $(BUILD_DIR)/smoke/freestanding.o | tee $(BUILD_DIR)/smoke/readelf-header.txt
	objdump -drwC $(BUILD_DIR)/smoke/freestanding.o | tee $(BUILD_DIR)/smoke/objdump.txt >/dev/null
	file $(BUILD_DIR)/smoke/freestanding.o | tee $(BUILD_DIR)/smoke/file.txt

qemu-version:
	@qemu-system-x86_64 --version
	@echo "QEMU exists. M0 does not boot a kernel image."

tree:
	@tree -a -L 3

clean:
	rm -rf $(BUILD_DIR)/smoke

distclean:
	rm -rf $(BUILD_DIR)
EOF

make smoke
make check
make smoke
make qemu-version
sudo apt update && sudo apt install -y build-essential bison flex libgmp-dev libmpc-dev libmpfr-dev texinfo libisl-dev
export TARGET=x86_64-elf
export PREFIX="$HOME/opt/cross"
export PATH="$PREFIX/bin:$PATH"
mkdir -p "$HOME/src/toolchain-src"
cd "$HOME/src/toolchain-src"
qemu-system-x86_64 --version
qemu-system-x86_64 -machine help | head -n 30
find /usr/share -iname 'OVMF_CODE*.fd' -o -iname 'OVMF_VARS*.fd' | sort
cat > docs/architecture/qemu_baseline.md <<'EOF' # QEMU Baseline MCSOS 260502 Target awal MCSOS menggunakan QEMU system emulator untuk x86_64. Baseline M0:- M0 hanya memverifikasi keberadaan QEMU dan OVMF.- M0 belum menjalankan kernel image.- Jalur UEFI/OVMF akan digunakan pada milestone boot berikutnya. Command template untuk M1/M2, belum wajib berhasil pada M0: ```bash qemu-system-x86_64 \-machine q35 \-cpu qemu64 \-m 512M \-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \-serial file:build/qemu-serial.log \-display none \-no-reboot \-no-shutdown
EOF

qemu-system-x86_64 -s -S ...
gdb -ex "target remote localhost:1234"
mkdir -p docs/requirements
cat > docs/requirements/system_requirements.md <<'EOF'
# System Requirements MCSOS 260502 - Baseline M0

## Scope

Dokumen ini menetapkan requirement awal untuk proyek MCSOS 260502. Requirement pada M0 berfokus pada lingkungan, governance, dan evidence. Requirement runtime kernel akan diperinci pada milestone berikutnya.

| ID | Requirement | Rationale | Verification evidence |
|---|---|---|---|
| REQ-M0-001 | Repository MCSOS harus berada di filesystem Linux WSL, bukan `/mnt/c`. | Mengurangi risiko permission, case, dan IO mismatch. | Output `pwd` dan `tools/check_env.sh`. |
| REQ-M0-002 | Semua tool wajib harus terdeteksi oleh script validasi. | Build lanjutan tidak boleh bergantung pada tool manual tak tercatat. | Output `bash tools/check_env.sh`. |
| REQ-M0-003 | Versi toolchain harus dicatat pada `build/meta/toolchain-versions.txt`. | Traceability dan reproducibility. | Isi file metadata. |
| REQ-M0-004 | Repository harus memiliki struktur `docs`, `tools`, `smoke`, dan `build`. | Menyeragamkan artefak praktikum. | Output `tree -a -L 3`. |
| REQ-M0-005 | Smoke test harus menghasilkan object ELF64 x86-64 relocatable. | Validasi awal target toolchain. | Output `readelf -h`. |
| REQ-M0-006 | Proyek harus memiliki assumptions dan non-goals. | Mencegah scope creep dan klaim readiness berlebih. | `docs/requirements/assumptions_and_nongoals.md`. |
| REQ-M0-007 | Proyek harus memiliki ADR awal untuk toolchain dan boot baseline. | Keputusan teknis harus dapat dilacak. | `docs/adr/ADR-0001-toolchain-and-boot-baseline.md`. |
| REQ-M0-008 | Proyek harus memiliki threat model awal. | Security from phase 0. | `docs/security/threat_model.md`. |
| REQ-M0-009 | Proyek harus memiliki risk register. | Risiko teknis dan operasional harus dikelola. | `docs/governance/risk_register.md`. |
| REQ-M0-010 | Proyek harus memiliki verification matrix. | Setiap requirement harus punya bukti validasi. | `docs/testing/verification_matrix.md`. |
| REQ-M0-011 | Semua perubahan M0 harus dikomit ke Git. | Traceability penilaian. | `git log --oneline`. |
| REQ-M0-012 | Laporan M0 harus memuat log, command, screenshot seperlunya, commit hash, dan analisis failure mode. | Evidence-first assessment. | `docs/reports/M0-laporan.md`. |
EOF

cat > docs/requirements/assumptions_and_nongoals.md <<'EOF' # Assumptions and Non-Goals MCSOS 260502 — M0 ## Assumptions 1. Target arsitektur awal adalah x86_64 long mode. 2. Host pengembangan adalah Windows 11 x64. 3. Build dilakukan di WSL 2 Linux environment. 4. Repository utama berada di filesystem Linux WSL. 5. Emulator utama untuk milestone awal adalah QEMU system x86_64. 6. Firmware emulator untuk jalur boot awal adalah OVMF/UEFI. 7. Bootloader awal yang direkomendasikan untuk milestone boot adalah Limine atau bootloader setara yang memiliki handoff terdokumentasi. 8. Bahasa kernel awal adalah freestanding C17 dengan assembly minimal. 9. Compatibility target awal adalah POSIX-like subset, bukan Linux ABI penuh. 10. Setiap milestone harus menghasilkan bukti: log, command output, image, checksum, map file, disassembly, trace, atau laporan. ## Non-goals M0 1. M0 tidak membuat kernel bootable. 2. M0 tidak mengimplementasikan bootloader. 3. M0 tidak membuat linker script final. 4. M0 tidak mengimplementasikan interrupt, paging, scheduler, syscall, VFS, driver, networking, graphics, atau security enforcement. 5. M0 tidak mengklaim MCSOS siap produksi. 6. M0 tidak mengklaim semua mesin x86_64 akan kompatibel. 7. M0 tidak mengharuskan hardware bring-up. 8. M0 tidak mengharuskan byte-for-byte reproducible build; nondeterminism cukup dicatat. EOF
EOF

cat > docs/adr/ADR-0001-toolchain-and-boot-baseline.md <<'EOF' # ADR-0001 — Toolchain dan Boot Baseline MCSOS 260502 ## Status Accepted for M0 baseline. ## Context MCSOS dikembangkan pada host Windows 11 x64, tetapi targetnya adalah baremetal x86_64. Program kernel tidak boleh bergantung pada ABI Windows atau Linux host. Lingkungan build harus dapat direproduksi oleh mahasiswa, asisten, dan dosen. ## Decision ## Consequences Keuntungan: 1. Build environment utama adalah WSL 2 Linux environment. 2. Repository utama ditempatkan di filesystem Linux WSL, bukan `/mnt/c`. 3. Toolchain awal M0 memakai paket distro: Clang/LLVM, LLD, binutils, NASM, Make, CMake, Ninja, Python 3. 4. Smoke test M0 memakai `clang --target=x86_64-unknown-none` untuk menghasilkan object freestanding. 5. Emulator utama untuk milestone berikutnya adalah QEMU system x86_64. 6. Firmware emulator adalah OVMF untuk jalur UEFI. 7. Bootloader awal yang direkomendasikan untuk milestone boot adalah Limine karena mendukung x86-64 dan protokol boot modern; keputusan final tetap harus divalidasi pada M1/M2. 8. GCC `x86_64-elf` dari source bersifat opsional pada M0 kecuali ditetapkan wajib oleh dosen.- Setup lebih seragam di Windows 11.- Toolchain Linux tersedia melalui package manager.- QEMU/GDB workflow selaras dengan praktik OS development.- Struktur evidence dapat direproduksi. Trade-off:- WSL 2 memiliki boundary VM yang harus dikonfigurasi.- Akselerasi KVM di WSL dapat bergantung pada konfigurasi host; TCG harus diterima sebagai baseline lambat tetapi deterministik.- Versi paket distro dapat berbeda antar mesin; karena itu metadata versi wajib dicatat. ## Review Trigger ADR ini harus ditinjau ulang jika: 1. Target arsitektur berubah dari x86_64. 2. Distro WSL distandarkan ulang. 3. Bootloader diganti dari Limine ke GRUB/custom UEFI loader. 4. Toolchain utama diganti dari LLVM ke GCC-only atau sebaliknya. 5. CI resmi proyek diperkenalkan. EOF
EOF

cat > docs/architecture/invariants.md <<'EOF' # Invariants MCSOS 260502 — Baseline M0 ## Repository invariants 1. Repository utama berada di filesystem Linux WSL. 2. Semua generated artifact berada di `build/` atau lokasi generated yang terdokumentasi. 3. Source, dokumen, dan script validasi dikomit ke Git. 4. File generated besar seperti image, object, ISO, dan log penuh tidak dikomit kecuali diminta sebagai fixture. ## Toolchain invariants 1. Setiap praktikum mencatat versi tool pada `build/meta/toolchainversions.txt` atau file metadata setara. 2. Compiler target harus dinyatakan eksplisit; kernel tidak boleh diamdiam memakai ABI host. 3. Object smoke test harus diperiksa dengan `readelf`, `objdump`, atau tool setara. 4. Flag freestanding dan red-zone policy harus terdokumentasi sebelum kode kernel nyata dibuat. ## Documentation invariants 1. Requirement harus memiliki metode verifikasi. 2. Risiko harus memiliki mitigasi atau trigger review. 3. Threat model harus ada sejak M0 dan diperbarui ketika subsistem baru ditambahkan. 4. Readiness label harus berbasis bukti. ## Evidence invariants 1. Klaim “berhasil” harus memiliki command output, log, checksum, screenshot, commit, atau artefak yang dapat diperiksa. 2. Error tidak boleh dihapus dari laporan; error harus diklasifikasi dan dianalisis. 3. Setiap rollback harus didokumentasikan. EOF
EOF

cat > docs/security/threat_model.md <<'EOF' # Threat Model Awal MCSOS 260502 — M0 ## Assets | Asset | Alasan dilindungi | |---|---| | Source code repository | Menentukan perilaku kernel dan tools. | | Toolchain | Compiler/linker yang salah dapat menghasilkan artefak salah. | | Build scripts | Script dapat menyisipkan flag berbahaya atau target salah. | | Documentation baseline | Menjadi sumber requirement dan acceptance criteria. | | Generated artifacts | Image/log/map dapat menjadi bukti penilaian. | | Signing keys masa depan | Belum dibuat pada M0, tetapi harus direncanakan. | ## Actors | Actor | Capability | |---|---| | Mahasiswa | Mengubah repository dan menjalankan build. | | Anggota kelompok | Mengubah branch dan dokumen. | | Dosen/asisten | Melakukan review dan penilaian. | | Dependency eksternal | Menyediakan paket, source, dan tools. | | Malicious local process | Dapat memodifikasi file jika permission buruk. | ## Trust boundaries 1. Windows host ↔ WSL Linux environment. 2. Repository source ↔ generated build output. 3. Package manager ↔ toolchain lokal. 4. Script praktikum ↔ shell pengguna. 5. QEMU guest masa depan ↔ host environment. ## Initial threats and mitigations | Threat | Dampak | Mitigasi M0 | |---|---|---| | Repository ditempatkan di `/mnt/c` dan permission/line ending berubah | Build tidak reproducible | Check script memberi warning; repository dipindah ke `~/src/mcsos`. | | Compiler host dipakai tanpa target eksplisit | Object salah ABI | Smoke test memakai `--target` dan `readelf`. | | Tool versi tidak tercatat | Hasil tidak dapat diaudit | `build/meta/toolchain-versions.txt`. | | Script dari internet dieksekusi tanpa review | Supply-chain compromise | Gunakan package manager resmi atau source resmi; catat URL dan checksum untuk source manual. | | Klaim readiness berlebihan | Penilaian tidak valid | Gunakan readiness label berbasis bukti. | | Anggota kelompok tidak memahami keseluruhan baseline | Integrasi gagal | Laporan mencantumkan peran dan review lintas anggota. | ## Out of scope M0 1. Enforcement MAC/RBAC/capability. 2. Secure Boot penuh. 3. TPM measured boot. 4. Kernel exploit mitigation. 5. Syscall fuzzing. Semua item out-of-scope akan masuk milestone berikutnya setelah boot, memory, syscall, dan userspace baseline tersedia. EOF
EOF

cat > docs/governance/risk_register.md <<'EOF' # Risk Register MCSOS 260502 — M0 | ID | Risiko | Probabilitas | Dampak | Mitigasi | Owner | Trigger review | |---|---|---:|---:|---|---|---| | R-M0-001 | WSL tidak aktif atau memakai WSL 1 | Medium | High | Verifikasi `wsl --list --verbose`; konversi ke WSL 2 | Toolchain engineer | `VERSION` bukan 2 | | R-M0-002 | Repository berada di `/mnt/c` | High | Medium | Pindahkan ke `~/src/mcsos`; check script warning | Koordinator | `pwd` menunjukkan `/mnt/c` | | R-M0-003 | QEMU tidak tersedia | Medium | High | Pasang `qemu-systemx86`; catat versi | Toolchain engineer | `command -v qemu-system-x86_64` gagal | | R-M0-004 | OVMF path berbeda | Medium | Medium | Cari dengan `find /usr/share`; jangan hardcode tanpa verifikasi | Toolchain engineer | `OVMF_CODE.fd` tidak ditemukan | | R-M0-005 | Compiler menghasilkan target host | Medium | High | Pakai `-- target`; inspeksi `readelf` | Verification engineer | `Machine` bukan x8664 | | R-M0-006 | Dokumen requirement tidak testable | Medium | Medium | Verification matrix wajib | Documentation engineer | Requirement tanpa evidence | | R-M0-007 | Kelompok tidak sinkron branch | Medium | Medium | Kebijakan branch dan pull sebelum commit | Koordinator | Konflik merge berulang | | R-M0-008 | Mahasiswa menghapus log error | Medium | Medium | Laporan wajib mencantumkan failure mode | Semua | Error tidak tercatat | | R-M0-009 | Build bergantung pada package version tidak tercatat | Medium | High | `make meta` sebelum submit | Verification engineer | Metadata kosong | | R-M0-010 | Scope M0 melebar menjadi implementasi kernel | Medium | Medium | Ikuti non-goals; tunda kernel ke M1/M2 | Koordinator | Ada kode kernel fungsional tanpa kontrak | EOF
EOF

cat > docs/testing/verification_matrix.md <<'EOF' # Verification Matrix MCSOS 260502 — M0 | Requirement | Verification command | Expected evidence | Pass/Fail | |---|---|---|---| | REQ-M0-001 | `pwd` | Path berada di `/home/.../src/mcsos` | TBD | | REQ-M0-002 | `bash tools/check_env.sh` | Semua tool wajib `[OK]` atau warning terdokumentasi | TBD | | REQ-M0-003 | `cat build/meta/toolchain-versions.txt` | Versi tool tercatat | TBD | | REQ-M0-004 | `tree -a -L 3` | Struktur docs/tools/smoke/build tersedia | TBD | | REQ-M0-005 | `make smoke` | Object ELF64 x86-64 relocatable | TBD | | REQ-M0-006 | `test -s docs/requirements/assumptions_and_nongoals.md` | File ada dan tidak kosong | TBD | | REQ-M0-007 | `test -s docs/adr/ADR-0001-toolchain-and-boot-baseline.md` | File ada dan tidak kosong | TBD | | REQ-M0-008 | `test -s docs/security/threat_model.md` | File ada dan tidak kosong | TBD | | REQ-M0-009 | `test -s docs/governance/risk_register.md` | File ada dan tidak kosong | TBD | | REQ-M0-010 | `test -s docs/testing/verification_matrix.md` | File ada dan tidak kosong | TBD | | REQ-M0-011 | `git log --oneline -n 3` | Minimal satu commit M0 | TBD | | REQ-M0-012 | `test -s docs/reports/M0-laporan.md` | Laporan tersedia | TBD | EOF
EOF

cat > docs/reports/M0-laporan.md <<'EOF' # Laporan Praktikum M0 — Baseline Requirements, Governance, dan Lingkungan Pengembangan ## 1. Sampul- Judul praktikum: Praktikum M0 — Baseline Requirements, Governance, dan Lingkungan Pengembangan Reproducible MCSOS 260502- Nama mahasiswa / kelompok:- NIM:- Kelas:- Dosen: Muhaemin Sidiq, S.Pd., M.Pd.- Program Studi: Pendidikan Teknologi Informasi, Institut Pendidikan Indonesia- Tanggal: ## 2. Tujuan Tuliskan capaian teknis dan konseptual M0. ## 3. Dasar teori ringkas Jelaskan host vs target, WSL 2, cross-compilation, ELF object, QEMU, OVMF, Git, reproducibility, dan evidence-first engineering. ## 4. Lingkungan | Komponen | Versi / output | |---|---| | Windows | | | WSL distro | | | Kernel Linux WSL | | | Git | | | Clang | | | LLD | | | binutils/readelf | | | NASM | | | QEMU | | | GDB | | | Python | | Lampirkan isi `build/meta/toolchain-versions.txt`. ## 5. Desain baselineJelaskan struktur repository, dokumen baseline, assumptions, non-goals, dan threat model awal. ## 6. Langkah kerja Tuliskan perintah yang dijalankan, alasan teknis, dan hasilnya. ## 7. Hasil uji | Pengujian | Command | Hasil | Pass/Fail | |---|---|---|---| | WSL version | `wsl --list --verbose` | | | | Tool check | `bash tools/check_env.sh` | | | | Metadata | `cat build/meta/toolchain-versions.txt` | | | | Smoke object | `make smoke` | | | | ELF header | `readelf -h build/smoke/freestanding.o` | | | | Git status | `git status` | | | ## 8. Analisis Jelaskan kendala, error, penyebab, perbaikan, dan bukti bahwa perbaikan berhasil. ## 9. Keamanan dan reliability Jelaskan risiko supply-chain, toolchain mismatch, repository path, permission, log integrity, dan mitigasi yang diterapkan. ## 10. Failure modes dan rollback | Failure mode | Gejala | Diagnosis | Rollback/perbaikan | |---|---|---|---| | WSL bukan versi 2 | | | | | Tool tidak ditemukan | | | | | Repository di `/mnt/c` | | | | | Smoke object salah target | | | | | OVMF tidak ditemukan | | | | ## 11. Kesimpulan Nyatakan apakah M0 hanya siap uji lingkungan, belum siap boot, dan apa syarat masuk M1. ## 12. Lampiran- Output `tools/check_env.sh`- Isi `build/meta/toolchain-versions.txt`- Output `readelf -h`- Output `objdump` ringkas- Screenshot relevan- Commit hash ## 13. Referensi Gunakan format IEEE sesuai panduan praktikum. EOF
EOF

make check
make smoke
make tree
git status --short
git add README.md Makefile .gitignore tools smoke docs
git commit -m "M0: initialize reproducible OS development baseline"
git rev-parse HEAD
git log --oneline -n 3
gif init
git add README.md Makefile .gitignore tools smoke docs
git commit -m "MO davelopment baseline"
git init
git add README.md Makefile .gitignore tools smoke docs
ls
git add .docs
gif add docs
git commit -m "development baseline"
git add
git commit -m "MO development baseline"
git add .
git commit -m "MO development baseline"
git log --oneline -n 3
make meta
make check
make smoke
make qemu-version
git status --short
git log --oneline -n 3
find ~ -name Makefile
cd ..
ls
cd mcsos
make meta
make check
sudo apt update && sudo apt install -y shellcheck
make meta
make check
notepad.exe tools/check_env.sh
make check
make smoke
make qemu-version
sudo apt update && sudo apt install -y qemu-system-x86
make qemu-version
git status --short
git add.
git commit -m "MO complete and biildable"
git commit -m "MO complete and buildable"
git log --oneline -n 3
git add .
git commit -m "MO complete and buildable"
git log --oneline -n 3
cat /etc/os-release
uname -a
nproc
free -h
pwd
cd ~/src
mkdir -p mcsos
cd mcsos
git init
mkdir -p docs/architecture docs/readiness docs/security docs/testing tools/scripts tests/toolchain build/meta build/proof
cat > .gitignore <<'GITIGNORE'
build/
*.o
*.elf
*.bin
*.iso
*.img
*.map
*.log
.cache/
.vscode/
GITIGNORE

sudo apt update
sudo apt install -y build-essential git make cmake ninja-build pkg-config clang lld llvm binutils nasm qemu-system-x86 qemu-utils ovmf gdb gdb-multiarch python3 python3-pip python3-venv shellcheck cppcheck clang-tidy xorriso mtools dosfstools file coreutils findutils
ping -c 3 google.com
sudo nano /etc/resolv.conf
ping -c 3 google.com
wsl --version
wsl --status
wsl --verbose
cd ~
pwd
mkdir -p ~/src
cd ~/scr
cd ~/src/mcsos
sudo apt update
vsudo apt install -y EOF
wsl
mkdir -p ~/src
cd ~/src
mkdir -p mcsos
cd mcsos
git init
pwd
echo "# safira-URAA" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/sfp685/safira-URAA.git
git push -u origin main
echo "# safira-URAA" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/sfp685/safira-URAA.git
git push -u origin main
make meta
make check
make smoke
# safira-URAA
tree -L 3
sudo apt install tree
tree -L 3
mv smoke/freestanding.c tests/toolchain/freestanding_probe.c
ls tests/toolchain
ls tools/scripts
nano tools/scripts/check_toolchain.sh
chmod +x tools/scripts/check_toolchain.sh
./tools/scripts/check_toolchain.sh
sudo apt update
sudo apt install -y cmake ninja-build lld llvm nasm gdb cppcheck clang-tidy
./tools/scripts/check_toolchain.sh
nano tools/scripts/collect_meta.sh
ls buid/meta
nano tools/scripts/collect_meta.sh
chmod +x tools/scripts/collect_meta.sh
./tools/scripts/collect_meta.sh
ls build/meta
nano tools/scripts/proof_compile.sh
chmod +x tools/scripts/proof_compile.sh
./tools/scripts/proof_compile.sh
cat > tools/scripts/qemu_probe.sh <<'SH' #!/usr/bin/env bash set -euo pipefail ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" OUT="$ROOT/build/meta" mkdir -p "$OUT" { echo "[qemu-version]" qemu-system-x86_64 --version echo echo "[qemu-machine-help-q35]" qemu-system-x86_64 -machine help | grep -E "q35|pc-q35" || true echo echo "[qemu-accel-help]" qemu-system-x86_64 -accel help || true echo echo "[ovmf-candidates]" for path in /usr/share/OVMF/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/ovmf/OVMF.fd /usr/share/qemu/OVMF.fd; do if [ -r "$path" ]; then echo "$path" fi done } | tee "$OUT/qemu-capabilities.txt" if ! grep -q "q35" "$OUT/qemu-capabilities.txt"; then echo "ERROR: q35 machine not found in QEMU machine list" >&2 exit 1 fi if ! grep -q "OVMF" "$OUT/qemu-capabilities.txt" && ! grep -q "ovmf" "$OUT/qemu-capabilities.txt"; then echo "ERROR: OVMF firmware candidate not found" >&2 exit 1 fi echo "OK: QEMU and OVMF probe complete" SH chmod +x tools/scripts/qemu_probe.sh
EOF
EOF
SH

chmod +x tools/scripts/qemu_probe.sh
./tools/scripts/qemu_probe.sh
rm tools/scripts/qemu_probe.sh
nano tools/scripts/qemu_probe.sh
chmod +x tools/scripts/qemu_probe.sh
./tools/scripts/qemu_probe.sh
cat > tools/scripts/repro_check.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/build/repro"

mkdir -p "$OUT"

sha256sum "$ROOT/build/proof/freestanding_probe.o" \
| tee "$OUT/proof.sha256"

sha256sum "$ROOT/build/proof/freestanding_probe.elf" \
| tee -a "$OUT/proof.sha256"

echo "OK: reproducibility metadata captured"
EOF

chmod +x tools/scripts/repro_check.sh
./tools/scripts/repro_check.sh
ls buid/repro
ls build/repro
cat > Makefile << 'EOF'
SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

.PHONY: help meta check proof qemu-probe repro test clean distclean

help:
	@echo "MCSOS M1 targets:"
	@echo " make meta"
	@echo " make check"
	@echo " make proof"
	@echo " make qemu-probe"
	@echo " make repro"
	@echo " make test"

meta:
	@./tools/scripts/collect_meta.sh

check:
	@./tools/scripts/check_toolchain.sh

proof:
	@./tools/scripts/proof_compile.sh

qemu-probe:
	@./tools/scripts/qemu_probe.sh

repro:
	@./tools/scripts/repro_check.sh

test: meta check proof qemu-probe repro
	@echo "OK: M1 test suite passed"

clean:
	@rm -rf build/proof build/repro

distclean:
	@rm -rf build
EOF

make test
git status
git add Makefile .gitignore docs tools tests
git commit -m "M1: add reproducible toolchain readiness baseline"
git rev-parse HEAD
git status
./tools/scripts/collect_meta.sgit add -u
git commit -m "M1: remove old smoke freestanding source"
git status
git add -u
git commit -m "M1: remove old smoke freestanding source"
git status
git push origin main
cd ~/src/mcsos
pwd
git rev-parse --show-toplevel
git status --short
git branch --show-current
git log --oneline -5
test -f docs/architecture/overview.md
test -f docs/architecture/invariants.md
test -f docs/security/threat_model.md
test -f docs/testing/verification_matrix.md
test -f docs/readiness/gates.md
echo $
echo $?
make meta
make check
make proof
make inspect-proof
make repro-check
mkdir -p tools/scripts
cat > tools/scripts/m2_preflight.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

mkdir -p build/meta
REPORT="build/meta/m2-preflight.txt"
: > "$REPORT"

log() {
printf '%s\n' "$*" | tee -a "$REPORT"
}

fail() {
log "ERROR: $*"
exit 1
}

need_cmd() {
if command -v "$1" >/dev/null 2>&1; then
log "OK command: $1 -> $(command -v "$1")"
else
fail "command tidak ditemukan: $1"
fi
}

log "== M2 preflight MCSOS 260502 =="
log "root=$ROOT"
log "date_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

case "$ROOT" in
/mnt/c/*|/mnt/d/*|/mnt/e/*)
fail "repository berada di filesystem Windows. Pindahkan ke filesystem Linux WSL, misalnya ~/src/mcsos."
;;
*)
log "OK filesystem: repository bukan /mnt/c, /mnt/d, atau /mnt/e"
;;
esac

need_cmd git
need_cmd make
need_cmd clang
need_cmd ld.lld
need_cmd readelf
need_cmd objdump
need_cmd nm
need_cmd qemu-system-x86_64
need_cmd xorriso
need_cmd python3

for f in \
docs/architecture/overview.md \
docs/architecture/invariants.md \
docs/security/threat_model.md \
docs/testing/verification_matrix.md; do
if [ -f "$f" ]; then
log "OK M0 file: $f"
else
fail "artefak M0 belum ada: $f"
fi
done

if [ -f build/meta/toolchain-versions.txt ]; then
log "OK M1 metadata: build/meta/toolchain-versions.txt"
else
log "WARN: build/meta/toolchain-versions.txt belum ada"
fi

if [ -f build/proof/freestanding_probe.o ]; then
readelf -hW build/proof/freestanding_probe.o > build/meta/m2-check-m1-object-readelf.txt

grep -q 'Class:.*ELF64' build/meta/m2-check-m1-object-readelf.txt || fail "object M1 bukan ELF64"

grep -q 'Machine:.*Advanced Micro Devices X86-64' build/meta/m2-check-m1-object-readelf.txt || fail "object M1 bukan x86_64"

log "OK M1 proof object: ELF64 x86_64"
else
log "WARN: build/proof/freestanding_probe.o tidak ditemukan"
fi

if find /usr/share -type f \( -name 'OVMF_CODE*.fd' -o -name 'OVMF_VARS*.fd' \) 2>/dev/null | grep -q OVMF; then
find /usr/share -type f \( -name 'OVMF_CODE*.fd' -o -name 'OVMF_VARS*.fd' \) 2>/dev/null | sort | tee -a "$REPORT"
else
fail "OVMF tidak ditemukan pada /usr/share. Pasang paket ovmf."
fi

log "OK: preflight M2 selesai"
EOF

chmod +x tools/scripts/m2_preflight.sh
bash -n tools/scripts/m2_preflight.sh
./tools/scripts/m2_preflight.sh
sudo apt update
./tools/scripts/m2_preflight.sh
sudo apt install -y xorriso
./tools/scripts/m2_preflight.sh
ls docs/architecture
mkdir -p docs/architecture
touch docs/architecture/overview.md
./tools/scripts/m2_preflight.sh
mkdir -p docs/architecture docs/security docs/testing
touch docs/architecture/invariants.md
touch docs/security/threat_model.md
touch docs/testing/verification_matrix.md
./tools/scripts/m2_preflight.sh
mkdir -p kernel/arch/x86_64/include/mcsos/arch
cat > kernel/arch/x86_64/include/mcsos/arch/io.h <<'EOF' #ifndef MCSOS_ARCH_IO_H #define MCSOS_ARCH_IO_H #include <stdint.h> static inline void outb(uint16_t port, uint8_t value) { __asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port) : "memory"); } static inline uint8_t inb(uint16_t port) { uint8_t value; __asm__ volatile ("inb %1, %0" : "=a"(value) : "Nd"(port) : "memory"); return value; } static inline void io_wait(void) { outb(0x80, 0); } #endif EOF
EOF

cat > kernel/arch/x86_64/include/mcsos/arch/io.h <<'EOF'
#ifndef MCSOS_ARCH_IO_H
#define MCSOS_ARCH_IO_H

#include <stdint.h>

static inline void outb(uint16_t port, uint8_t value) {
__asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port) : "memory");
}

static inline uint8_t inb(uint16_t port) {
uint8_t value;
__asm__ volatile ("inb %1, %0" : "=a"(value) : "Nd"(port) : "memory");
return value;
}

static inline void io_wait(void) {
outb(0x80, 0);
}

#endif
EOF

cat kernel/arch/x86_64/include/mcsos/arch/io.h
mkdir -p kernel/arch/x86_64/serial
cat > kernel/arch/x86_64/serial/serial.c <<'EOF'
#include <stdint.h>
#include <stddef.h>

#include <mcsos/arch/io.h>

#define COM1_PORT 0x3F8

static int serial_transmit_ready(void) {
return inb(COM1_PORT + 5) & 0x20;
}

void serial_init(void) {
outb(COM1_PORT + 1, 0x00);
outb(COM1_PORT + 3, 0x80);
outb(COM1_PORT + 0, 0x03);
outb(COM1_PORT + 1, 0x00);
outb(COM1_PORT + 3, 0x03);
outb(COM1_PORT + 2, 0xC7);
outb(COM1_PORT + 4, 0x0B);
}

void serial_write_char(char c) {
while (!serial_transmit_ready()) {
}

outb(COM1_PORT, (uint8_t)c);
}

void serial_write(const char* s) {
if (s == NULL) {
return;
}

while (*s) {
if (*s == '\n') {
serial_write_char('\r');
}

serial_write_char(*s++);
}
}
EOF

cat kernel/arch/x86_64/serial/serial.c
mkdir -p kernel/include/mcsos
cat > kernel/include/mcsos/serial.h <<'EOF'
#ifndef MCSOS_SERIAL_H
#define MCSOS_SERIAL_H

void serial_init(void);
void serial_write_char(char c);
void serial_write(const char* s);

#endif
EOF

cat kernel/include/mcsos/serial.h
mkdir -p kernel
cat > kernel/kmain.c <<'EOF'
#include <mcsos/serial.h>

void kmain(void) {
serial_init();

serial_write("MCSOS kernel start\n");
serial_write("serial: COM1 online\n");
serial_write("M2: serial logging active\n");

for (;;) {
__asm__ volatile ("hlt");
}
}
EOF

cat kernel/kmain.c
mkdir -p kernel/core
cat > kernel/core/kmain.c <<'EOF'
void serial_init(void);
void serial_write(const char *s);

__attribute__((noreturn)) static void halt_forever(void) {
for (;;) {
__asm__ volatile ("cli; hlt" : : : "memory");
}
}

void kmain(void) {
serial_init();
serial_write("MCSOS 260502 M2 boot path entered\n");
serial_write("[M2] early serial online\n");
serial_write("[M2] kernel reached controlled halt loop\n");
halt_forever();
}
EOF

cat kernel/core/kmain.c
mkdir -p kernel/lib
cat > kernel/lib/memory.c <<'EOF'
#include <stddef.h>

void *memset(void *dest, int value, size_t count) {
unsigned char *d = (unsigned char *)dest;
while (count-- != 0u) {
*d++ = (unsigned char)value;
}
return dest;
}

void *memcpy(void *dest, const void *src, size_t count) {
unsigned char *d = (unsigned char *)dest;
const unsigned char *s = (const unsigned char *)src;
while (count-- != 0u) {
*d++ = *s++;
}
return dest;
}

void *memmove(void *dest, const void *src, size_t count) {
unsigned char *d = (unsigned char *)dest;
const unsigned char *s = (const unsigned char *)src;

if (d == s || count == 0u) {
return dest;
}

if (d < s) {
while (count-- != 0u) {
*d++ = *s++;
}
} else {
d += count;
s += count;
while (count-- != 0u) {
*--d = *--s;
}
}

return dest;
}
EOF

cat kernel/lib/memory.c
cat > linker.ld <<'EOF'
OUTPUT_FORMAT(elf64-x86-64)
ENTRY(kmain)

PHDRS
{
text PT_LOAD FLAGS(5);
rodata PT_LOAD FLAGS(4);
data PT_LOAD FLAGS(6);
}

SECTIONS
{
. = 0xffffffff80000000;

__kernel_start = .;

.text : ALIGN(4096)
{
*(.text .text.*)
} :text

.rodata : ALIGN(4096)
{
*(.rodata .rodata.*)
} :rodata

.data : ALIGN(4096)
{
*(.data .data.*)
} :data

.bss : ALIGN(4096)
{
*(COMMON)
*(.bss .bss.*)
} :data

__kernel_end = .;
}
EOF

cat linker.ld
cat > Makefile <<'EOF'
CC := clang
LD := ld.lld

CFLAGS := -ffreestanding -fno-stack-protector -fno-pic -m64 -Wall -Wextra
LDFLAGS := -nostdlib -static -z max-page-size=0x1000

OBJS := \
kernel/arch/x86_64/serial.o \
kernel/core/kmain.o \
kernel/lib/memory.o

all: build/kernel.elf

kernel/arch/x86_64/serial.o: kernel/arch/x86_64/serial.c
	@mkdir -p build
	$(CC) $(CFLAGS) -Ikernel/include -c $< -o $@

kernel/core/kmain.o: kernel/core/kmain.c
	$(CC) $(CFLAGS) -Ikernel/include -c $< -o $@

kernel/lib/memory.o: kernel/lib/memory.c
	$(CC) $(CFLAGS) -Ikernel/include -c $< -o $@

build/kernel.elf: $(OBJS) linker.ld
	$(LD) $(LDFLAGS) -T linker.ld -o $@ $(OBJS)

clean:
	rm -rf build *.o
EOF

cat Makefile
make
ls kernel/arch/x86_64
cat > kernel/arch/x86_64/serial.c <<'EOF'
#include <stdint.h>
#include <mcsos/arch/io.h>

#define COM1_PORT 0x3F8

static int serial_transmit_ready(void) {
return inb(COM1_PORT + 5) & 0x20;
}

void serial_init(void) {
outb(COM1_PORT + 1, 0x00);
outb(COM1_PORT + 3, 0x80);
outb(COM1_PORT + 0, 0x03);
outb(COM1_PORT + 1, 0x00);
outb(COM1_PORT + 3, 0x03);
outb(COM1_PORT + 2, 0xC7);
outb(COM1_PORT + 4, 0x0B);
}

void serial_write_char(char c) {
while (!serial_transmit_ready()) {
}
outb(COM1_PORT, (uint8_t)c);
}

void serial_write(const char* s) {
if (s == 0) {
return;
}
while (*s) {
if (*s == '\n') {
serial_write_char('\r');
}
serial_write_char(*s++);
}
}
EOF

ls kernel/arch/x86_64
make
sed -i 's|-Ikernel/include|-Ikernel/include -Ikernel/arch/x86_64/include|g' Makefile
make
file build/kernel.elf
readelf -hW build/kernel.elf | grep 'Entry point'
qemu-system-x86_64 -kernel build/kernel.elf -nographic -serial mon:stdio
qemu-system-x86_64 -machine q35 -drive format=raw,file=build/kernel.elf -nographic
ls build
git clone https://github.com/limine-bootloader/limine.git --branch=v8.x-binary --depth=1
cd limine
make
cd ..
mkdir -p iso_root/boot
cp build/kernel.elf iso_root/boot/
cat > iso_root/boot/limine.conf <<'EOF'
TIMEOUT=0

:mcsos
PROTOCOL=limine

KERNEL_PATH=boot():/boot/kernel.elf
EOF

cat iso_root/boot/limine.conf
mkdir -p configs/limine
cat > configs/limine/limine.conf <<'EOF'
timeout: 0
serial: yes
/MCSOS 260502 M2
protocol: limine
path: boot():/boot/kernel.elf
cmdline: mcsos.version=260502 mcsos.milestone=M2 console=serial
EOF

cat configs/limine/limine.conf
mkdir -p tools/scripts
cat > tools/scripts/fetch_limine.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIMINE_DIR="${ROOT_DIR}/third_party/limine"

mkdir -p "${ROOT_DIR}/third_party"

if [ ! -d "${LIMINE_DIR}" ]; then
    git clone https://github.com/limine-bootloader/limine.git "${LIMINE_DIR}"
fi

cd "${LIMINE_DIR}"
git checkout v8.x-binary
make
EOF

chmod +x tools/scripts/fetch_limine.sh
./tools/scripts/fetch_limine.sh
mkdir -p iso_root/boot
mkdir -p iso_root/boot/limine
cp build/kernel.elf iso_root/boot/
cp third_party/limine/limine-bios.sys iso_root/boot/limine/
cp third_party/limine/limine-bios-cd.bin iso_root/boot/limine/
cp third_party/limine/limine-uefi-cd.bin iso_root/boot/limine/
cp configs/limine/limine.conf iso_root/boot/limine/
find iso_root
xorriso -as mkisofs -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot boot/limine/limine-uefi-cd.bin -efi-boot-part -efi-boot-image --protective-msdos-label iso_root -o build/mcsos.iso
third_party/limine/limine bios-install build/mcsos.iso
qemu-system-x86_64 -cdrom build/mcsos.iso -m 256M -serial stdio
rm -f build/mcsos.iso
xorriso -as mkisofs -o build/mcsos.iso -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot boot/limine/limine-uefi-cd.bin --efi-boot-part --efi-boot-image --protective-msdos-label iso_root
third_party/limine/limine bios-install build/mcsos.iso
qemu-system-x86_64 -cdrom build/mcsos.iso -m 256M -serial stdio
nano iso_root/boot/limine.conf
xorriso -as mkisofs -o build/mcsos.iso -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot boot/limine/limine-uefi-cd.bin --efi-boot-part --efi-boot-image --protective-msdos-label iso_root
third_party/limine/limine bios-install build/mcsos.iso
qemu-system-x86_64 -cdrom build/mcsos.iso -m 256M -serial stdio
cat iso_root/boot/limine.conf
cat > iso_root/boot/limine.conf <<'EOF'
TIMEOUT=0

:mcsos
PROTOCOL=limine
KERNEL_PATH=boot():/boot/kernel.elf
EOF

cat iso_root/boot/limine.conf
rm -f build/mcsos.iso
xorriso -as mkisofs -o build/mcsos.iso -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot boot/limine/limine-uefi-cd.bin --efi-boot-part --efi-boot-image --protective-msdos-label iso_root
third_party/limine/limine bios-install build/mcsos.iso
qemu-system-x86_64 -cdrom build/mcsos.iso -m 256M -serial stdio
cat > iso_root/boot/limine.conf <<'EOF'
TIMEOUT=0

:mcsos
PROTOCOL=limine
KERNEL_PATH=boot:///boot/kernel.elf
EOF

cat > iso_root/boot/limine/limine.conf <<'EOF'
TIMEOUT=0

:mcsos
PROTOCOL=limine
KERNEL_PATH=boot:///boot/kernel.elf
EOF

cat iso_root/boot/limine.conf
cat iso_root/boot/limine/limine.conf
rm -f build/mcsos.iso
xorriso -as mkisofs -o build/mcsos.iso -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot boot/limine/limine-uefi-cd.bin --efi-boot-part --efi-boot-image --protective-msdos-label iso_root
third_party/limine/limine bios-install build/mcsos.iso
qemu-system-x86_64 -cdrom build/mcsos.iso -m 256M -serial stdio
cat iso_root/boot/limine.conf
echo "----"
cat iso_root/boot/limine/limine.conf
cat > iso_root/boot/limine.conf <<'EOF'
TIMEOUT=0

:mcsos
PROTOCOL=stivale2
KERNEL_PATH=boot:///boot/kernel.elf
EOF

cat > iso_root/boot/limine/limine.conf <<'EOF'
TIMEOUT=0

:mcsos
PROTOCOL=stivale2
KERNEL_PATH=boot:///boot/kernel.elf
EOF

rm -f build/mcsos.iso
xorriso -as mkisofs -o build/mcsos.iso -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot boot/limine/limine-uefi-cd.bin --efi-boot-part --efi-boot-image --protective-msdos-label iso_root
third_party/limine/limine bios-install build/mcsos.iso
qemu-system-x86_64 -cdrom build/mcsos.iso -m 256M -serial stdio
rm -f iso_root/boot/limine.conf
cat > iso_root/boot/limine/limine.conf <<'EOF'
TIMEOUT=0

/mcsos
    PROTOCOL=stivale2
    KERNEL_PATH=boot:///boot/kernel.elf
EOF

rm -f build/mcsos.iso
xorriso -as mkisofs -o build/mcsos.iso -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot boot/limine/limine-uefi-cd.bin --efi-boot-part --efi-boot-image --protective-msdos-label iso_root
third_party/limine/limine bios-install build/mcsos.iso
qemu-system-x86_64 -cdrom build/mcsos.iso -m 256M -serial stdio
rm -f iso_root/boot/limine/limine.conf
cat > iso_root/boot/limine/limine.conf <<'EOF'
TIMEOUT=0

:mcsos
PROTOCOL=stivale2
KERNEL_PATH=boot:///boot/kernel.elf
EOF

cat iso_root/boot/limine/limine.conf
rm -f build/mcsos.iso
xorriso -as mkisofs -o build/mcsos.iso -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot boot/limine/limine-uefi-cd.bin --efi-boot-part --efi-boot-image --protective-msdos-label iso_root
third_party/limine/limine bios-install build/mcsos.iso
qemu-system-x86_64 -cdrom build/mcsos.iso -m 256M -serial stdio
find iso_root -name "limine.conf"
cp iso_root/boot/limine/limine.conf iso_root/boot/limine.conf
cat iso_root/boot/limine.conf
rm -f build/mcsos.iso
xorriso -as mkisofs -o build/mcsos.iso -b boot/limine/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot boot/limine/limine-uefi-cd.bin --efi-boot-part --efi-boot-image --protective-msdos-label iso_root
third_party/limine/limine bios-install build/mcsos.iso
qemu-system-x86_64 -cdrom build/mcsos.iso -m 256M -serial stdio'
EOF
qemu-system-x86_64 -cdrom build/mcsos.iso -m 256M -serial stdio
rm -f iso_root/boot/limine.conf
rm -f iso_root/boot/limine/limine.conf
cat > iso_root/boot/limine.conf <<'EOF'
timeout: 0

/MCSOS
protocol: limine
kernel_path: boot():/boot/kernel.elf
EOF

cd ~/src/mcsos
git status --short
git branch --show-current
git log --oneline -5
git add <nama_file>
/build/
/iso_root/
/third_party/
*.sh
git commit -m "Perbaiki status file yang belum dilacak dan update .gitignore"
git add .
git commit -m "Perbaiki status file yang belum dilacak dan update .gitignore"
git add .
git status
git commit -m "Perbaiki status file yang belum dilacak dan update .gitignore"
/build/
/iso_root/
/third_party/
*.sh
git push
pwd
case "$(pwd)" in /mnt/c/*|/mnt/d/*|/mnt/e/*) echo "ERROR: repository berada di filesystem Windows. Pindahkan ke ~/src/mcsos."; exit 1; ;; *) echo "OK: repository berada di filesystem Linux WSL."; ;; esac
git rev-parse --show-toplevel
git status --short
git branch --show-current
git log --oneline -5
git init
cd ~/src/mcsos
git add .
git commit -m "Initial commit: setup M2 repository"
test -f docs/architecture/overview.md
test -f docs/architecture/invariants.md
test -f docs/security/threat_model.md
test -f docs/testing/verification_matrix.md
make distclean
make check-src
make build
ls Makefile
.RECIPEPREFIX := >
SHELL := /usr/bin/env bash
ARCH := x86_64
BUILD_DIR := build
KERNEL := $(BUILD_DIR)/kernel.elf
MAP := $(BUILD_DIR)/kernel.map
CC := clang
LD := ld.lld
OBJDUMP := objdump
READELF := readelf
NM := nm
CFLAGS := --target=x86_64-unknown-none-elf -std=c17 -ffreestanding -fno-stack-protector -fno-stack-check -fno-pic -fno-pie -fno-lto -m64 -march=x86-64 -mabi=sysv -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -mcmodel=kernel -Wall -Wextra -Werror -Ikernel/arch/x86_64/include
LDFLAGS := -nostdlib -static -z max-page-size=0x1000 -T linker.ld -Map=$(MAP)
SRC_C := $(shell find kernel -name '*.c' | LC_ALL=C sort)
OBJ := $(patsubst %.c,$(BUILD_DIR)/%.o,$(SRC_C))
.PHONY: all build inspect image run debug check-prev check-src check-scripts grade clean distclean
all: build
check-prev:
>./tools/scripts/m2_preflight.sh
check-src:
>$(CC) --version | head -n 1
>$(LD) --version | head -n 1
>test -f linker.ld
>test -d kernel/core
>test -d kernel/lib
check-scripts:
>for s in tools/scripts/*.sh; do bash -n "$$s"; done
>if command -v shellcheck >/dev/null 2>&1; then shellcheck tools/scripts/*.sh; else echo "WARN: shellcheck tidak tersedia"; fi
build: $(KERNEL)
>mkdir -p $(BUILD_DIR)
>$(LD) $(LDFLAGS) -o $@ $(OBJ)
inspect: $(KERNEL)
>./tools/scripts/inspect_kernel.sh
image: $(KERNEL)
>./tools/scripts/make_iso.sh
run: image
>./tools/scripts/run_qemu.sh
debug: image
>./tools/scripts/run_qemu_debug.sh
grade: check-src check-scripts build inspect image run
>./tools/scripts/grade_m2.sh
clean:
>rm -rf $(BUILD_DIR)/kernel $(BUILD_DIR)/*.elf $(BUILD_DIR)/*.map $(BUILD_DIR)/inspect
distclean:
>rm -rf $(BUILD_DIR) iso_root
nano Makefile
make distclean
sudo apt update
sudo apt install clang lld build-essential
make distclean
clean:
make distclean
make build
make image
make run
nano Makefile
make distclean
make build
make image
make run
nano Makefile
make distclean
make build
make image
make run
case "$(pwd)" in /mnt/c/*|/mnt/d/*|/mnt/e/*) echo "ERROR: repository berada di filesystem Windows. Pindahkan ke ~/src/mcsos."; exit 1; ;; *) echo "OK: repository berada di filesystem Linux WSL."; ;; esac
git status --short
git add .
git commit -m "Menambahkan file yang belum terlacak"
test -f docs/architecture/overview.md
test -f docs/security/threat_model.md
test -f build/meta/toolchain-versions.txt
test -f build/proof/freestanding_probe.o
test -f build/mcsos.iso
test -f build/kernel.elf
test -f build/kernel.map
#ifndef MCSOS_ARCH_IO_H
#define MCSOS_ARCH_IO_H
#include <stdint.h>
static inline void outb(uint16_t port, uint8_t value) {
}
static inline uint8_t inb(uint16_t port) {
}
static inline void io_wait(void) {
}
#endif
#include <stdint.h>  // Untuk tipe data uint8_t dan uint16_t
// Fungsi untuk menulis byte ke port I/O
static inline void outb(uint16_t port, uint8_t value) {
}
// Fungsi untuk membaca byte dari port I/O
static inline uint8_t inb(uint16_t port) {
}
make distclean
make build
#include <stdint.h>  // Untuk tipe data uint8_t dan uint16_t
// Fungsi untuk menulis byte ke port I/O
static inline void outb(uint16_t port, uint8_t value) {
}
// Fungsi untuk membaca byte dari port I/O
static inline uint8_t inb(uint16_t port) {
}
make distclean
make build
pwd
case "$(pwd)" in /mnt/c/*|/mnt/d/*|/mnt/e/*)   echo "ERROR: repository berada di filesystem Windows. Pindahkan ke ~/src/mcsos.";   exit 1; ;; *)   echo "OK: repository berada di filesystem Linux WSL."; ;; esac
git rev-parse --show-toplevel
git status --short
git branch --show-current
git log --oneline -5
test -f build/meta/toolchain-versions.txt
make check-scripts
find . -name "Makefile"
