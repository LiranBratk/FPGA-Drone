#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include "hwlib.h"
#include "socal/socal.h"
#include "socal/hps.h"
#include "socal/alt_gpio.h"
#include "hps_0.h"

#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_SPAN ( 0x04000000 )
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )
#define GPIO0_BASE 0xFC000000

void print_binary(uint32_t value) {
    char binary[33]; // Enough space to hold 32-bit integer + null terminator
    binary[32] = '\0'; // Null-terminate the string

    int i;
    for (i = 31; i >= 0; i--) {
        binary[i] = (value & (1 << (31 - i))) ? '1' : '0';
    }

    printf("%s\n", binary);
}

int main() {

	void *virtual_base;
	int fd;
	int loop_count;
	int led_direction;
	int led_mask;
	void *h2p_lw_led_addr;

	void *gpio0_base;
	volatile uint32_t *gpio0_ptr;

	// map the address space for the LED registers into user space so we can interact with them.
	// we'll actually map in the entire CSR span of the HPS since we want to access various registers within that span

	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return( 1 );
	}
	
	virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );

	if(virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap() failed...\n" );
		close( fd );
		return( 1 );
	}

	h2p_lw_led_addr=virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + PIO_LED_BASE ) & ( unsigned long)( HW_REGS_MASK ) );

	printf("%p \n", (void *)virtual_base);
	printf("%p \n", (void *)h2p_lw_led_addr);

	// toggle the LEDs a bit

	loop_count = 0;
	led_mask = 0x01; // 0000 0001
	led_direction = 0; // 0: left to right direction
	while( loop_count < 60 ) {

		// control led
		*(uint32_t *)h2p_lw_led_addr = ~(led_mask); // NOT on the binary - if 0000 0000 then all leds are on

		// wait 100ms
		usleep( 100*1000 );

		// update led mask
		print_binary(led_mask);
		if (led_direction == 0){
			led_mask <<= 1;
			if (led_mask == (0x01 << (PIO_LED_DATA_WIDTH-1)))
				 led_direction = 1;
		}else{
			led_mask >>= 1;
			if (led_mask == 0x01){ 
				led_direction = 0;
				loop_count++;
			}
		}

	} // while

	if (munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( fd );
		return( 1 );
	}
    close(fd);

	return( 0 );
}
