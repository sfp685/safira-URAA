OUTPUT_FORMAT("elf64-x86-64")
ENTRY(kmain)
SECTIONS
{
    . = 0xffffffff80000000;
    .text : ALIGN(0x1000) { *(.text .text.*) }
    .rodata : ALIGN(0x1000) { *(.rodata .rodata.*) }
    .requests_start_marker : ALIGN(0x1000) { *(.requests_start_marker) }
    .requests : { *(.requests) }
    .requests_end_marker : { *(.requests_end_marker) }
    .data : ALIGN(0x1000) { *(.data .data.*) }
    .bss : ALIGN(0x1000) {
        *(.bss .bss.*)
        *(COMMON)
    }
}
