#include "io.h"
#include "pit.h"
#include "serial.h"
#include "pic.h"

#define PIT_BASE_FREQUENCY 1193182u
#define PIT_CHANNEL0_DATA  0x40u
#define PIT_MODE_COMMAND   0x43u

static volatile uint64_t g_ticks = 0;

void pit_configure_hz(uint32_t hz) {
    uint32_t divisor = PIT_BASE_FREQUENCY / hz;
    if ((PIT_BASE_FREQUENCY % hz) >= (hz / 2u)) {
        divisor++;
    }
    
    outb(PIT_MODE_COMMAND, 0x36u); // Channel 0, lobyte/hibyte, Mode 3, Binary
    outb(PIT_CHANNEL0_DATA, (uint8_t)(divisor & 0xFFu));
    outb(PIT_CHANNEL0_DATA, (uint8_t)((divisor >> 8) & 0xFFu));
}

void timer_on_irq0(void) {
    g_ticks++;
    if ((g_ticks % 100u) == 0) {
        serial_write_string("[MCSOS:TIMER] ticks=");
        serial_write_dec64(g_ticks);
        serial_write_string("\n");
    }
}

uint64_t timer_ticks(void) {
    return g_ticks;
}
