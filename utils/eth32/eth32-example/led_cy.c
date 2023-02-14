#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include "eth32.h"

#define ID_BUTTON0 100
#define ID_BUTTON1 101

int main(int argc, char *argv[])
{
	char hostname[200];
	char garbage[100];
	char *result;
	int eth32result;
	eth32_handler event_handler_config = {0}; // Initialize contents to all zeroes
	eth32 handle;

	printf("Enter hostname or IP address of ETH32 to connect to.\n"
		   "Address: ");
	result = fgets(hostname, sizeof(hostname), stdin);

	if (result)
	{
		// If something was read from the user, trim off any newlines or
		// other whitespace at the end of it
		while (isspace(hostname[strlen(hostname) - 1]))
			hostname[strlen(hostname) - 1] = 0; // Shorten the string by NULL terminating the last byte
	}

	if (result == 0 || strlen(hostname) == 0)
	{
		printf("You must specify a hostname or address to connect to.  Please rerun the program and try again.\n");
		return (1);
	}

	// Open a connection to the ETH32
	handle = eth32_open(hostname, ETH32_PORT, 5000, &eth32result);
	if (handle == 0)
	{
		printf("Error connecting to ETH32: %s\n", eth32_error_string(eth32result));
		return (1);
	}

	// Enable pullup resistors on pushbutton lines
	eth32result = eth32_output_bit(handle, 0, 0, 1);
	if (eth32result)
	{
		printf("Error configuring the ETH32: %s\n", eth32_error_string(eth32result));
		return (1);
	}

	// A demo of lights to show the connectivity

	printf("Set up the direction:");
	// Change the direction of io pin of 0 and 1 to OUTPUT
	for (int port = 0; port < 6; port++)
	{
		eth32result = eth32_set_direction(handle, port, 1);
		if (eth32result)
		{
			printf("Failed to set up the direction on port-%d!", port);
		}
	}

	while (1)
	{
		// Set up the LED light
		eth32_set_led(handle, 1, 0);
		eth32_set_led(handle, 0, 1);

		// Set up the bit 0 and 2 value as 1 for port 3
		printf("Set up the bit 0 and 2 value as 1 for port 3");
		eth32result = eth32_output_bit(handle, 3, 0, 0);
		eth32result = eth32_output_bit(handle, 3, 2, 0);
		// wait for
		sleep(1);

		eth32_set_led(handle, 0, 0);
		eth32_set_led(handle, 1, 1);
		eth32result = eth32_output_bit(handle, 3, 0, 1);
		eth32result = eth32_output_bit(handle, 3, 2, 1);
		sleep(1);

		if (eth32result)
		{
			printf("Failed to set up the bit value");
		}
	}

	// Now just wait for the user to press Enter - everything else is
	// handled by the event routine.
	fgets(garbage, sizeof(garbage), stdin);
	printf("\n");

	// Close the board and exit.
	eth32_close(handle);
	return (0);
}