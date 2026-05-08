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
