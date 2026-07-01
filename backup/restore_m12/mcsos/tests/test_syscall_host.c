#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "mcsos/syscall.h"

static uint64_t fake_ticks(void) { return 12345u; }
static int g_yield_count = 0;
static int g_exit_code = 0;
static void fake_yield(void) { g_yield_count++; }
static void fake_exit(int code) { g_exit_code = code; }
static int64_t fake_write(const char *buf, size_t len) {
    assert(buf != NULL);
    assert(len == 5u);
    assert(memcmp(buf, "hello", 5u) == 0);
    return (int64_t)len;
}

int main(void) {
    char user_buf[16] = "hello";
    char kernel_buf[16] = {0};
    mcsos_syscall_ops_t ops = {
        .get_ticks = fake_ticks,
        .yield_current = fake_yield,
        .exit_current = fake_exit,
        .write_serial = fake_write
    };
    mcsos_syscall_init(&ops);
    mcsos_syscall_set_user_region((mcsos_user_region_t){
        .base = (uintptr_t)&user_buf[0],
        .limit = (uintptr_t)&user_buf[0] + sizeof(user_buf)
    });

    assert(mcsos_syscall_dispatch(MCSOS_SYS_PING,0,0,0,0,0,0) == 0x2605020AL);
    printf("[OK] ping\n");

    assert(mcsos_syscall_dispatch(MCSOS_SYS_GET_TICKS,0,0,0,0,0,0) == 12345);
    printf("[OK] get_ticks\n");

    assert(mcsos_syscall_dispatch(MCSOS_SYS_WRITE_SERIAL,(uintptr_t)user_buf,5,0,0,0,0) == 5);
    printf("[OK] write_serial\n");

    assert(mcsos_copy_from_user(kernel_buf, user_buf, 5) == MCSOS_OK);
    assert(memcmp(kernel_buf, "hello", 5u) == 0);
    printf("[OK] copy_from_user valid\n");

    assert(mcsos_copy_from_user(kernel_buf, (void *)1, 5) == MCSOS_EFAULT);
    printf("[OK] copy_from_user invalid -> EFAULT\n");

    assert(mcsos_syscall_dispatch(999,0,0,0,0,0,0) == MCSOS_ENOSYS);
    printf("[OK] invalid nr -> ENOSYS\n");

    assert(mcsos_syscall_dispatch(MCSOS_SYS_YIELD,0,0,0,0,0,0) == MCSOS_OK);
    assert(g_yield_count == 1);
    printf("[OK] yield\n");

    assert(mcsos_syscall_dispatch(MCSOS_SYS_EXIT_THREAD,7,0,0,0,0,0) == MCSOS_OK);
    assert(g_exit_code == 7);
    printf("[OK] exit_thread(7)\n");

    mcsos_syscall_frame_t frame = { .nr = MCSOS_SYS_GET_TICKS };
    mcsos_syscall_dispatch_frame(&frame);
    assert(frame.ret == 12345);
    printf("[OK] dispatch_frame\n");

    puts("M10 syscall host tests passed");
    return 0;
}
