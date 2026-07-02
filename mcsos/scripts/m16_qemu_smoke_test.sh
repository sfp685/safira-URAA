#!/usr/bin/env bash
#
# M16 QEMU smoke test
#
# Tujuan: memastikan integrasi M16 tidak merusak boot path.
# CATATAN: ini BUKAN bukti crash consistency penuh. Bukti crash consistency
# utama M16 tetap berasal dari host fault-injection test, bukan dari script ini.
#
set -euo pipefail

LOG_DIR="logs/m16"
BUILD_LOG="${LOG_DIR}/build_kernel.log"
SERIAL_LOG="${LOG_DIR}/qemu_serial.log"
ISO_PATH="build/mcsos.iso"

# Batas waktu QEMU (detik). Bisa dioverride: QEMU_TIMEOUT=90 ./m16_qemu_smoke_test.sh
QEMU_TIMEOUT="${QEMU_TIMEOUT:-60}"

# Pola-pola yang dicari di serial log. Sesuaikan dengan string asli
# di kernel/log subsystem M16 kalau berbeda.
BOOT_BANNER_PATTERN="MCSOS"
FS_INIT_PATTERN="(fs|filesystem).*(init|mount)"
FSCK_REPLAY_PATTERN="(fsck|replay)"
TRIPLE_FAULT_PATTERN="triple fault"

mkdir -p "${LOG_DIR}"

echo "== [1/3] Build kernel =="
make clean all iso 2>&1 | tee "${BUILD_LOG}"

if [ ! -f "${ISO_PATH}" ]; then
  echo "ERROR: ${ISO_PATH} tidak ditemukan setelah build."
  echo "  -> Kembali ke panduan M2-M3 untuk memastikan image build tersedia."
  exit 1
fi

rm -f "${SERIAL_LOG}"
touch "${SERIAL_LOG}"

echo "== [2/3] Jalankan QEMU (timeout ${QEMU_TIMEOUT}s) =="
# timeout -k 5 memastikan proses benar-benar mati kalau kernel hang
# tanpa reboot/shutdown (mode -no-reboot -no-shutdown memang sengaja begitu,
# supaya state akhir tetap terekam di serial log untuk diperiksa).
set +e
timeout -k 5 "${QEMU_TIMEOUT}" qemu-system-x86_64 \
  -machine q35 \
  -m 512M \
  -serial file:"${SERIAL_LOG}" \
  -display none \
