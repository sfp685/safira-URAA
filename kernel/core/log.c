#include <core/log.h>
#include <driver/serial.h>

/* Menulis string ke log serial - Halaman 27 */
void log_write(const char* str) {
    serial_send_string(str);
}

/* Menulis angka 64-bit dalam format heksadesimal - Halaman 28 */
void log_hex64(uint64_t val) {
    char hex_chars[] = "0123456789ABCDEF";
    char buffer[19]; // "0x" + 16 digit + null
    
    buffer[0] = '0';
    buffer[1] = 'x';
    
    for (int i = 15; i >= 0; i--) {
        buffer[i + 2] = hex_chars[val & 0xF];
        val >>= 4;
    }
    
    buffer[18] = '\0';
    log_write(buffer);
}
