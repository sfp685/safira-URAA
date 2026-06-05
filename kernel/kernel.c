#include <serial.h>
#include <idt.h>
#include <pmm.h>
#include <limine.h>

__attribute__((used, section(".requests_start_marker")))
static volatile LIMINE_REQUESTS_START_MARKER;

__attribute__((used, section(".requests")))
static volatile struct limine_memmap_request memmap_req = {
    .id = LIMINE_MEMMAP_REQUEST,
    .revision = 0
};

__attribute__((used, section(".requests_end_marker")))
static volatile LIMINE_REQUESTS_END_MARKER;

static struct pmm_state kernel_pmm;
static uint8_t kernel_pmm_bitmap[PMM_BITMAP_BYTES] __attribute__((aligned(4096)));

static void kernel_memory_init(void) {
    struct limine_memmap_response *memmap = memmap_req.response;
    if (!memmap) {
        serial_write_string("[m6] ERROR: no memmap response\n");
        for (;;) asm volatile ("hlt");
    }
    struct boot_mem_region regions[128];
    size_t count = 0;
    for (uint64_t i = 0; i < memmap->entry_count && count < 128; i++) {
        struct limine_memmap_entry *e = memmap->entries[i];
        uint32_t type;
        switch (e->type) {
            case LIMINE_MEMMAP_USABLE:                 type = BOOT_MEM_USABLE; break;
            case LIMINE_MEMMAP_RESERVED:               type = BOOT_MEM_RESERVED; break;
            case LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE: type = BOOT_MEM_BOOTLOADER_RECLAIMABLE; break;
            case LIMINE_MEMMAP_KERNEL_AND_MODULES:     type = BOOT_MEM_KERNEL_AND_MODULES; break;
            case LIMINE_MEMMAP_FRAMEBUFFER:            type = BOOT_MEM_FRAMEBUFFER; break;
            case LIMINE_MEMMAP_ACPI_RECLAIMABLE:       type = BOOT_MEM_ACPI_RECLAIMABLE; break;
            case LIMINE_MEMMAP_ACPI_NVS:               type = BOOT_MEM_ACPI_NVS; break;
            case LIMINE_MEMMAP_BAD_MEMORY:             type = BOOT_MEM_BAD_MEMORY; break;
            default:                                   type = BOOT_MEM_RESERVED; break;
        }
        regions[count].base   = e->base;
        regions[count].length = e->length;
        regions[count].type   = type;
        count++;
    }
    bool ok = pmm_init_from_map(&kernel_pmm, regions, count,
                                kernel_pmm_bitmap, sizeof(kernel_pmm_bitmap),
                                PMM_MAX_PHYS_BYTES);
    if (!ok) {
        serial_write_string("[m6] ERROR: pmm_init_from_map failed\n");
        for (;;) asm volatile ("hlt");
    }
    serial_write_string("[m6] pmm initialized\n");
    uint64_t f = pmm_alloc_frame(&kernel_pmm);
    if (f != PMM_INVALID_FRAME) {
        serial_write_string("[m6] sample frame alloc OK\n");
        pmm_free_frame(&kernel_pmm, f);
        serial_write_string("[m6] sample frame free OK\n");
    }
}

#include "mcsos/kmem.h"

#define M8_BOOT_HEAP_SIZE (64u * 1024u)
static unsigned char m8_boot_heap[M8_BOOT_HEAP_SIZE] __attribute__((aligned(4096)));

void kernel_main(void) {
    serial_init();
    idt_init();
    kernel_memory_init();

    /* M8: kernel heap bootstrap */
    int rc = kmem_init(m8_boot_heap, sizeof(m8_boot_heap));
    if (rc != 0) {
        serial_write_string("[M8 FAIL] kmem_init failed\n");
        for (;;) asm volatile ("hlt");
    }
    serial_write_string("[M8] heap initialized\n");

    void *probe = kmem_alloc(128);
    if (probe == (void*)0) {
        serial_write_string("[M8 FAIL] kmem_alloc probe failed\n");
        for (;;) asm volatile ("hlt");
    }
    if (kmem_free_checked(probe) != 0) {
        serial_write_string("[M8 FAIL] kmem_free_checked failed\n");
        for (;;) asm volatile ("hlt");
    }
    serial_write_string("[M8 SUCCESS] kernel heap alloc/free probe OK\n");

    asm volatile ("sti");
    for (;;) asm volatile ("hlt");
}
