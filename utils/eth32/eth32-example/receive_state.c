// This code is a minimum prototype for the testing
// This code only sends one-time signal to the ETH32 converter to change the output voltage
// TODO: An C based agent keeps alive and interact with Python

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include "eth32.h"

// void voltage_monitor(eth32 handle, eth32_event *event, void *extra){

// }

int main(int argc, char *argv[])
{
	char hostname[200];
	int eth32result;
	eth32 handle;

	strcpy(hostname, "192.168.0.64");

	char *pin_arg = argv[1];
	int pin = atoi(pin_arg);

	int direction = 0;

	// Open a connection to the ETH32
	handle = eth32_open(hostname, ETH32_PORT, 5000, &eth32result);

	// printf("%d\n", eth32result);

	// printf("Set up the direction: \n");
	// eth32result = eth32_set_direction_bit(handle, 3, pin, direction);
	eth32result = eth32_set_analog_state(handle, ADC_ENABLED);
	eth32result = eth32_set_analog_assignment(handle, 0, pin);
	eth32result = eth32_set_analog_reference(handle, REF_INTERNAL);

	// printf("%d\n", eth32result);

	// printf("Change the voltage to on pin %d as value %d \n", pin, value);
	int value = -1;
	while (1)
	{
		eth32result = eth32_input_analog(handle, 0, &value);
		printf("Current Voltage: %f \n", (value / 1024.0) * 5.0);
		printf("Refered Value: %d \n", value);
		usleep(1000000);
	}
	// eth32result = eth32_input_analog(handle, pin, &value);

	// printf("eth32_input_analog(): %d\n", eth32result);
	// Close the board and exit.
	eth32_close(handle);
	printf("Current Voltage: %f \n", (value / 1024.0) * 5.0);
	printf("Refered Value: %d \n", value);
	return value;
}