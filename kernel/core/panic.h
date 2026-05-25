#ifndef PANIC_H
#define PANIC_H

#define KERNEL_PANIC(msg) kernel_panic_at(__FILE__, __LINE__, msg)

void kernel_panic_at(const char* file, int line, const char* msg);

#endif
