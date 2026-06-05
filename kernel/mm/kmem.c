#include "mcsos/kmem.h"

#define KMEM_MIN_SPLIT 32u

typedef struct kmem_block {
    uint64_t magic;
    size_t   size;
    int      free;
    int      _pad;
    struct kmem_block *prev;
    struct kmem_block *next;
    uint8_t  _align[0];
} __attribute__((aligned(16))) kmem_block_t;

static unsigned char  *g_heap_base   = (unsigned char *)0;
static unsigned char  *g_heap_end    = (unsigned char *)0;
static kmem_block_t   *g_head        = (kmem_block_t *)0;
static int             g_initialized = 0;

static void *kmem_memset(void *dst, int val, size_t n) {
    unsigned char *p = (unsigned char *)dst;
    while (n--) *p++ = (unsigned char)val;
    return dst;
}

static uintptr_t kmem_align_up_ptr(uintptr_t v, size_t align) {
    return (v + (uintptr_t)(align - 1u)) & ~(uintptr_t)(align - 1u);
}

static size_t kmem_align_up_size(size_t v, size_t align) {
    return (v + (align - 1u)) & ~(align - 1u);
}

static unsigned char *kmem_payload(kmem_block_t *b) {
    return (unsigned char *)b + sizeof(kmem_block_t);
}

static kmem_block_t *kmem_header_from_payload(void *ptr) {
    return (kmem_block_t *)((unsigned char *)ptr - sizeof(kmem_block_t));
}

static int kmem_ptr_in_heap(void *ptr) {
    return (unsigned char *)ptr >= g_heap_base &&
           (unsigned char *)ptr <  g_heap_end;
}

static void kmem_split_if_useful(kmem_block_t *block, size_t wanted) {
    uintptr_t new_addr = (uintptr_t)kmem_payload(block) + wanted;
    new_addr = kmem_align_up_ptr(new_addr, KMEM_ALIGN);
    if (new_addr + sizeof(kmem_block_t) >= (uintptr_t)g_heap_end) return;
    const size_t consumed = (size_t)(new_addr - (uintptr_t)kmem_payload(block));
    if (block->size <= consumed + sizeof(kmem_block_t) + KMEM_MIN_SPLIT) return;
    kmem_block_t *nb = (kmem_block_t *)new_addr;
    nb->magic = KMEM_MAGIC;
    nb->size  = block->size - consumed - sizeof(kmem_block_t);
    nb->free  = 1;
    nb->_pad  = 0;
    nb->prev  = block;
    nb->next  = block->next;
    if (block->next) block->next->prev = nb;
    block->next = nb;
    block->size = wanted;
}

static void kmem_coalesce_forward(kmem_block_t *block) {
    while (block && block->next && block->next->free) {
        kmem_block_t *next = block->next;
        unsigned char *expected = kmem_payload(block) + block->size;
        expected = (unsigned char *)kmem_align_up_ptr((uintptr_t)expected, KMEM_ALIGN);
        if (expected != (unsigned char *)next) return;
        block->size += sizeof(kmem_block_t) + next->size;
        block->next  = next->next;
        if (next->next) next->next->prev = block;
        next->magic = 0u;
        next->size  = 0u;
        next->prev  = (kmem_block_t *)0;
        next->next  = (kmem_block_t *)0;
    }
}

int kmem_init(void *base, size_t bytes) {
    if (!base || bytes < sizeof(kmem_block_t) + KMEM_MIN_SPLIT) return -1;
    uintptr_t start = kmem_align_up_ptr((uintptr_t)base, KMEM_ALIGN);
    if (!start || start < (uintptr_t)base) return -2;
    const size_t lost = (size_t)(start - (uintptr_t)base);
    if (bytes <= lost + sizeof(kmem_block_t) + KMEM_MIN_SPLIT) return -3;
    size_t usable = (bytes - lost) & ~(size_t)(KMEM_ALIGN - 1u);
    if (usable <= sizeof(kmem_block_t) + KMEM_MIN_SPLIT) return -4;
    g_heap_base = (unsigned char *)start;
    g_heap_end  = g_heap_base + usable;
    g_head = (kmem_block_t *)g_heap_base;
    g_head->magic = KMEM_MAGIC;
    g_head->size  = usable - sizeof(kmem_block_t);
    g_head->free  = 1;
    g_head->_pad  = 0;
    g_head->prev  = (kmem_block_t *)0;
    g_head->next  = (kmem_block_t *)0;
    g_initialized = 1;
    return kmem_validate();
}

void *kmem_alloc(size_t bytes) {
    if (!g_initialized || !bytes) return (void *)0;
    const size_t wanted = kmem_align_up_size(bytes, KMEM_ALIGN);
    if (!wanted) return (void *)0;
    for (kmem_block_t *cur = g_head; cur; cur = cur->next) {
        if (cur->magic != KMEM_MAGIC) return (void *)0;
        if (cur->free && cur->size >= wanted) {
            kmem_split_if_useful(cur, wanted);
            cur->free = 0;
            return (void *)kmem_payload(cur);
        }
    }
    return (void *)0;
}

void *kmem_calloc(size_t count, size_t bytes) {
    if (count && bytes > (size_t)-1 / count) return (void *)0;
    const size_t total = count * bytes;
    void *ptr = kmem_alloc(total);
    if (ptr) kmem_memset(ptr, 0, total);
    return ptr;
}

int kmem_free_checked(void *ptr) {
    if (!ptr) return 0;
    if (!kmem_ptr_in_heap(ptr)) return -1;
    if ((uintptr_t)ptr & (KMEM_ALIGN - 1u)) return -2;
    kmem_block_t *block = kmem_header_from_payload(ptr);
    if (!kmem_ptr_in_heap(block) || block->magic != KMEM_MAGIC) return -3;
    if (block->free) return -4;
    block->free = 1;
    kmem_coalesce_forward(block);
    if (block->prev && block->prev->free) kmem_coalesce_forward(block->prev);
    return kmem_validate();
}

void kmem_get_stats(kmem_stats_t *out) {
    if (!out) return;
    kmem_memset(out, 0, sizeof(*out));
    if (!g_initialized) return;
    out->total_bytes = (size_t)(g_heap_end - g_heap_base);
    for (kmem_block_t *cur = g_head; cur; cur = cur->next) {
        out->block_count++;
        if (cur->free) {
            out->free_count++;
            out->free_bytes += cur->size;
            if (cur->size > out->largest_free) out->largest_free = cur->size;
        } else {
            out->used_bytes += cur->size;
        }
    }
}

int kmem_validate(void) {
    if (!g_initialized || !g_heap_base || g_heap_end <= g_heap_base || !g_head) return -1;
    if ((unsigned char *)g_head != g_heap_base) return -2;
    kmem_block_t  *prev   = (kmem_block_t *)0;
    unsigned char *cursor = g_heap_base;
    size_t guard = 0u;
    for (kmem_block_t *cur = g_head; cur; cur = cur->next) {
        if (++guard > 1048576u) return -3;
        if ((unsigned char *)cur != cursor) return -4;
        if ((unsigned char *)cur < g_heap_base ||
            (unsigned char *)cur + sizeof(kmem_block_t) > g_heap_end) return -5;
        if (cur->magic != KMEM_MAGIC) return -6;
        if (cur->prev != prev) return -7;
        if (cur->size > (size_t)(g_heap_end - kmem_payload(cur))) return -8;
        cursor = (unsigned char *)kmem_align_up_ptr(
            (uintptr_t)(kmem_payload(cur) + cur->size), KMEM_ALIGN);
        if (!cursor || cursor > g_heap_end) return -9;
        prev = cur;
    }
    return 0;
}
