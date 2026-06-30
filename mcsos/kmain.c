void serial_write_string(char* str) {
    for (int i = 0; str[i] != '\0'; i++) {
        __asm__ volatile ("outb %0, %1" : : "a"(str[i]), "Nd"((unsigned short)0x3F8));
    }
}

extern void block_demo_run(void);

void kmain() {
    serial_write_string("Halo Safira, Kernel M6 berhasil jalan!\n");
    block_demo_run();
    while(1);
}
