#!/usr/bin/env bash
set -e

# Versi minimum yang dibutuhkan
REQUIRED_CLANG=14
export REQUIRED_MAKE=4.0

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
