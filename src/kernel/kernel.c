static void outb(unsigned short port, unsigned char val) {
    __asm__ volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

void _start(void) {
    char *msg = "MCSOS M2 is Running!\n";
    for (int i = 0; msg[i] != '\0'; i++) {
        outb(0x3f8, msg[i]); // Mengirim karakter ke port serial
    }

    while (1) {
        __asm__("hlt");
    }
}
