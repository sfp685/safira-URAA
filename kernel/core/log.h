#ifndef LOG_H
#define LOG_H

#include <stdint.h>

void log_write(const char* str);
void log_hex64(uint64_t val);

#endif
