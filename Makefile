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
