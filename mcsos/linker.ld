ENTRY(_start)
SECTIONS
{
    . = 0x100000;
    .note.gnu.build-id : { *(.note.gnu.build-id) }
    .text : { *(.text) }
    .rodata : { *(.rodata) }
    .data : { *(.data) }
    .bss : {
        *(.bss)
        *(COMMON)
    }
}
