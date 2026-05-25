#ifndef MCSOS_PIT_H
#define MCSOS_PIT_H
#include "types.h"
void pit_configure_hz(uint32_t hz);
void timer_on_irq0(void);
uint64_t timer_ticks(void);
#endif
