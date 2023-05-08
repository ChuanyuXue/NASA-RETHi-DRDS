// This code is a minimum prototype for the testing
// This code only sends one-time signal to the ETH32 converter to change the output voltage
// TODO: An C based agent keeps alive and interact with Python

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include "eth32.h"

// Usage: ./receive_state <ip> <pin> <value>

int main(int argc, char *argv[])
{
	char hostname[200];
	int eth32result;
	eth32 handle;

	char *ip = argv[1];
	strcpy(hostname, ip);

	char *pin_arg = argv[2];
	int pin = atoi(pin_arg);
	// char *direction_arg = argv[3];
	// int direction = atoi(direction_arg);
	int direction = 1;
	char *value_arg = argv[3];
	int value = atoi(value_arg);

	// Open a connection to the ETH32
	handle = eth32_open(hostname, ETH32_PORT, 5000, &eth32result);

	// printf("%d\n", eth32result);

	// printf("Set up the direction: \n");
	eth32result = eth32_set_direction_bit(handle, 3, pin, direction);

	// printf("%d\n", eth32result);

	// printf("Change the voltage to on pin %d as value %d \n", pin, value);
	eth32result = eth32_output_bit(handle, 3, pin, value);

	// printf("%d\n", eth32result);
	// Close the board and exit.
	eth32_close(handle);
	return (0);
}