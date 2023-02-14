// This code is a minimum prototype for the testing
// This code only sends one-time signal to the ETH32 converter to change the output voltage
// TODO: An C based agent keeps alive and interact with Python

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include "eth32.h"

int main(int argc, char *argv[])
{
	char hostname[200];
	char *result;
	int eth32result;
	eth32 handle;

	results = '192.168.0.64';

	char *pin_arg = argv[1];
	int pin = atoi(pin_arg);
	char *value_arg = argv[2];
	int value = atoi(value_arg);

	// Open a connection to the ETH32
	handle = eth32_open(hostname, ETH32_PORT, 5000, &eth32result);

	printf("Set up the direction:");
	for (int port = 0; port < 6; port++)
	{
		eth32result = eth32_set_direction(handle, port, 1);
	}

	printf("Change the voltage to on pin %d as value %d", pin, value);
	eth32result = eth32_output_bit(handle, 3, pin, value);

	// Close the board and exit.
	eth32_close(handle);
	return (0);
}