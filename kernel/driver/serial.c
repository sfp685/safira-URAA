#include <driver/serial.h>
#include <stdint.h>

#define PORT 0x3f8          /* COM1 */

void serial_init(void) {
    // Implementasi sederhana untuk inisialisasi serial COM1
}

void serial_send_string(const char* str) {
    for (int i = 0; str[i] != '\0'; i++) {
        // Logika pengiriman karakter ke I/O port
    }
}
