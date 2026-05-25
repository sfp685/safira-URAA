#ifndef CPU_H
#define CPU_H

/* Mematikan interupsi CPU - Halaman 13 */
static inline void cli(void) {
    __asm__ volatile("cli" : : : "memory");
}

/* Menghentikan CPU sampai ada interupsi - Halaman 13 */
static inline void hlt(void) {
    __asm__ volatile("hlt");
}

/* Loop tak terbatas (Infinite Halt) untuk Panic Path - Halaman 14 */
static inline void infinite_hlt(void) {
    while (1) {
        cli();
        hlt();
    }
}

#endif
