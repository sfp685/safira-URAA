#include "io.h"
#include "serial.h"
#include "idt.h"
#include "pic.h"
#include "pit.h"

void kmain(void) {
    cpu_cli();                 
    serial_init();             
    serial_write_string("[MCSOS:M5] boot: external interrupt bring-up start\n");

    idt_init();                
    serial_write_string("[MCSOS:M5] idt: loaded\n");

    pic_remap(PIC_MASTER_OFFSET, PIC_SLAVE_OFFSET); 
    pic_mask_all();            
    pic_unmask_irq(0);         
    serial_write_string("[MCSOS:M5] pic: remapped and masked\n");

    pit_configure_hz(100);     
    serial_write_string("[MCSOS:M5] pit: configured 100Hz\n");

    serial_write_string("[MCSOS:M5] sti: enabling interrupts\n");
    cpu_sti();                 

    for (;;) {
        cpu_hlt();
    }
}
