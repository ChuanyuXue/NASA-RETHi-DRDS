#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "eth32.h"


#define ID_BUTTON0  100
#define ID_BUTTON1  101


void button_status(int which, int status)
{
	// This function writes a line to the screen to show the status
	// of the pushbuttons:
	//   which:  Which pushbutton is being specified (0 or 1)
	//   status: 1 means ON (pressed) and 0 means OFF (not pressed)
	static int button0=0;
	static int button1=0;

	if(which==0)
		button0=status;
	else if(which==1)
		button1=status;

	// Now write the line to the screen
	printf("\rButton 0: %s  Button 1: %s", (button0 ? " ON" : "OFF"), (button1 ? " ON" : "OFF"));
	fflush(stdout);

}

// Our event handler callback function.  On Windows, it must be declared __stdcall,
// and on Linux it must not.
#ifdef WINDOWS
void __stdcall event_handler(eth32 handle, eth32_event *event, void *extra)
#else
void event_handler(eth32 handle, eth32_event *event, void *extra)
#endif
{
	switch(event->id)
	{
		case ID_BUTTON0:
			if(event->value)
			{
				// Button has just been released
				button_status(0, 0);  // Update the screen
				eth32_set_led(handle, 0, 0);  // Turn off LED on ETH32
			}
			else
			{
				// Button has just been pressed
				button_status(0, 1);  // Update the screen
				eth32_set_led(handle, 0, 1);  // Turn on LED on ETH32
			}
			break;
	
		case ID_BUTTON1:
			if(event->value)
			{
				// Button has just been released
				button_status(1, 0);  // Update the screen
				eth32_set_led(handle, 1, 0);  // Turn off LED on ETH32
			}
			else
			{
				// Button has just been pressed
				button_status(1, 1);  // Update the screen
				eth32_set_led(handle, 1, 1);  // Turn on LED on ETH32
			}
			break;
	}
}




int main(int argc, char *argv[])
{
	char hostname[200];
	char garbage[100];
	char *result;
	int eth32result;
	eth32_handler event_handler_config={0}; // Initialize contents to all zeroes
	eth32 handle;

	printf("Enter hostname or IP address of ETH32 to connect to.\n"
               "Address: ");
	result=fgets(hostname, sizeof(hostname), stdin);

	if(result)
	{
		// If something was read from the user, trim off any newlines or
		// other whitespace at the end of it 
		while(isspace(hostname[strlen(hostname)-1]))
			hostname[strlen(hostname)-1]=0; // Shorten the string by NULL terminating the last byte
	}

	if(result==0 || strlen(hostname)==0)
	{
		printf("You must specify a hostname or address to connect to.  Please rerun the program and try again.\n");
		return(1);
	}

	// Open a connection to the ETH32
	handle=eth32_open(hostname, ETH32_PORT, 5000, &eth32result);
	if(handle==0)
	{
		printf("Error connecting to ETH32: %s\n", eth32_error_string(eth32result));
		return(1);
	}

	// Enable pullup resistors on pushbutton lines
	eth32result=eth32_output_bit(handle, 0, 0, 1);
	if(eth32result)
	{
		printf("Error configuring the ETH32: %s\n", eth32_error_string(eth32result));
		return(1);
	}

	eth32result=eth32_output_bit(handle, 0, 1, 1);
	if(eth32result)
	{
		printf("Error configuring the ETH32: %s\n", eth32_error_string(eth32result));
		return(1);
	}


	// Enable events on both pushbutton lines
	eth32result=eth32_enable_event(handle, EVENT_DIGITAL, 0, 0, ID_BUTTON0);
	if(eth32result)
	{
		printf("Error configuring the ETH32: %s\n", eth32_error_string(eth32result));
		return(1);
	}

	eth32result=eth32_enable_event(handle, EVENT_DIGITAL, 0, 1, ID_BUTTON1);
	if(eth32result)
	{
		printf("Error configuring the ETH32: %s\n", eth32_error_string(eth32result));
		return(1);
	}


	// Register our event handler function
	event_handler_config.type=HANDLER_CALLBACK;
	event_handler_config.maxqueue=1000;
	event_handler_config.fullqueue=QUEUE_DISCARD_NEW;
	event_handler_config.eventfn=event_handler;
	event_handler_config.extra=0;

	eth32result=eth32_set_event_handler(handle, &event_handler_config);
	if(eth32result)
	{
		printf("Error configuring the ETH32: %s\n", eth32_error_string(eth32result));
		return(1);
	}



	printf("Successfully connected to the ETH32 device.  Watch the screen and the LEDs as "
               "you press the external pushbuttons.  Due to being on the command-line, the "
               "screen may update slowly in some cases.  Press Enter when you are ready to quit.\n\n");

	// Call the button_status function once initially to get an initial
	// status display on the screen.
	button_status(0, 0);

	// Now just wait for the user to press Enter - everything else is  
	// handled by the event routine.
	fgets(garbage, sizeof(garbage), stdin);
	printf("\n");

	// Close the board and exit.
	eth32_close(handle);
	return(0);
}