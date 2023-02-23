/* Winford Engineering ETH32 API
 * Copyright 2005 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */

// Function code for most of the publicly declared functions for
// the ETH32 API.

#include "eth32_internal.h"
#include "eth32.h"
#include "eth32cfg.h"
#include "threads.h"
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>

#define ROUND(x) ((int) ((x) >= 0.0 ? (x) + 0.5 : (x) - 0.5))

// Error strings
const eth_errinfo_t eth_errinfo[]={
		{ETH_SUCCESS, "ETH_SUCCESS: No error occurred."},
		{ETH_GENERAL_ERROR, "ETH_GENERAL_ERROR: A miscellaneous or uncategorized error has occurred."},
		{ETH_CLOSING, "ETH_CLOSING: Function aborted because the device is being closed."},
		{ETH_NETWORK_ERROR, "ETH_NETWORK_ERROR: Network communications error.  Connection was unable to be established or existing connection was broken."},
		{ETH_THREAD_ERROR, "ETH_THREAD_ERROR: Internal error occurred in the threads and synchronization library."},
		{ETH_NOT_SUPPORTED, "ETH_NOT_SUPPORTED: Function not supported by this platform or device."},
		{ETH_PIPE_ERROR, "ETH_PIPE_ERROR: Internal API error dealing with data pipes."},
		{ETH_RTHREAD_ERROR, "ETH_RTHREAD_ERROR: Internal API error dealing with the \"Reader thread.\""},
		{ETH_ETHREAD_ERROR, "ETH_ETHREAD_ERROR: Internal API error dealing with the \"Event thread.\""},
		{ETH_MALLOC_ERROR, "ETH_MALLOC_ERROR: Error dynamically allocating memory."},
		{ETH_WINDOWS_ERROR, "ETH_WINDOWS_ERROR: Internal API error specific to the Microsoft Windows platform."},
		{ETH_WINSOCK_ERROR, "ETH_WINSOCK_ERROR: Internal API error in dealing with the Microsoft Winsock library."},
		{ETH_NETWORK_INTR, "ETH_NETWORK_INTR: Network read/write operation was interrupted."},
		{ETH_WRONG_MODE, "ETH_WRONG_MODE: Something is not configured correctly in order to allow this functionality."},
		{ETH_BCAST_OPT, "ETH_BCAST_OPT: Error setting the SO_BROADCAST option on a socket."},
		{ETH_REUSE_OPT, "ETH_REUSE_OPT: Error setting the SO_REUSEADDR option on a socket."},
		{ETH_CFG_NOACK, "ETH_CFG_NOACK: Warning - device did not acknowledge our attempt to store a new configuration."},
		{ETH_CFG_REJECT, "ETH_CFG_REJECT: Device has rejected the new configuration data we attempted to store.  Configuration switch on device may be disabled."},
		{ETH_LOADLIB, "ETH_LOADLIB: Error loading an external DLL library."},
		{ETH_PLUGIN, "ETH_PLUGIN: General error with the currently configured plugin/sniffer library."},
		{ETH_BUFSIZE, "ETH_BUFSIZE: A buffer provided was either invalid size or too small."},
		{ETH_INVALID_HANDLE, "ETH_INVALID_HANDLE: Invalid device handle was given."},
		{ETH_INVALID_PORT, "ETH_INVALID_PORT: The given port number does not exist on this device."},
		{ETH_INVALID_BIT, "ETH_INVALID_BIT: The given bit number does not exist on this port."},
		{ETH_INVALID_CHANNEL, "ETH_INVALID_CHANNEL: The given channel number does not exist on this device."},
		{ETH_INVALID_POINTER, "ETH_INVALID_POINTER: The pointer passed in to an API function was invalid."},
		{ETH_INVALID_OTHER, "ETH_INVALID_OTHER: One of the parameters passed in to an API function was invalid."},
		{ETH_INVALID_VALUE, "ETH_INVALID_VALUE: The given value is out of range for this I/O port, counter, etc."},
		{ETH_INVALID_IP, "ETH_INVALID_IP: The IP address provided was invalid."},
		{ETH_INVALID_NETMASK, "ETH_INVALID_NETMASK: The subnet mask provided was invalid."},
		{ETH_INVALID_INDEX, "ETH_INVALID_INDEX: Invalid index value."},
		{ETH_TIMEOUT, "ETH_TIMEOUT: Operation timed out before it could be completed."}
	};
const char error_unknown[]="Unknown error code.";

#ifdef LINUX


static int eth32_loaded=0;

void _eth32_fork_child(void)
{
	// This function will be called in the context of a new child whenever
	// this process (or one of its threads) forks off a new process.
	// We will automatically free any memory that we can and close our
	// copy of the socket on any open boards.
	// NOTE: Note that because this fork handler is permanently installed,
	// the user must realize he cannot unload our library until either he
	// has done his last fork or his program is exiting anyways.

	if(eth32_loaded)
	{
		eth32_devtable_cleanup(1);
	
		eth32_loaded=0;
	}
}

void __attribute__ ((constructor)) eth32lib_init(void)
{
	// This function is called when an application linked with 
	// the shared library is loaded OR when an application 
	// dynamically loads the library with dlopen


	if(eth32_loaded==0)
	{
		
		eth32_devtable_init();
	
		// Install fork handler
		pthread_atfork(NULL, NULL, _eth32_fork_child);
		
		eth32_loaded=1;
	}


}

void __attribute__ ((destructor)) eth32_lib_fini(void)
{
	// This function is called when the program ends OR
	// when an application unloads the library with dlclose

	if(eth32_loaded)
	{
		eth32_devtable_cleanup(0);

		eth32_loaded=0;
	}
}


#endif

#ifdef WINDOWS
BOOL CALLCONVENTION DllMain(HINSTANCE hDllInst, DWORD fdwReason, LPVOID lpvReserved)
{
	/* This function is called whenever this Dll is loaded or unloaded
	 * by a process. 
	 * 
	 * NOTE: When unloading, lpvReserved is NULL if the Dll is being
	 * dynamically unloaded with FreeLibrary.  In this case, we'll
	 * clean up our devices, otherwise we won't.
	 */

	switch(fdwReason)
	{
	case DLL_PROCESS_ATTACH:
		eth32_devtable_init();
		break;
	case DLL_PROCESS_DETACH:

		if(lpvReserved == NULL) /* if we're being unloaded by FreeLibrary */
		{
			
			eth32_devtable_cleanup(0);
		}

		/* otherwise, the process is ending, and we'll just let everything
		 * die by itself
		 */
		break;
	}
	return(TRUE);
}
#endif



eth32 CALLCONVENTION eth32_open(char *address, WORD port, unsigned int timeout, int *result)
{
	// timeout specifies, in milliseconds, how long the connection attempt may take,
	// excluding resolving DNS if a non-numeric address is given.
	// Specify a timeout of zero to indicate using the system's timeout.
	eth32_data *data;
	int erresult=0; /* error code to be returned */


	// Allocate zeroed memory for our device data structure
	if( (data=(eth32_data*)calloc(sizeof(eth32_data), 1)) == 0 )
	{
		if(result)
			*result = ETH_MALLOC_ERROR; 
		return(0);
	}
	
	// Initialize events, mutexes, linked lists, etc, within the data structure
	if( wth_event_init(&(data->refcount_event)) )
	{
		erresult = ETH_THREAD_ERROR;
		goto error_10;
	}
	
	if( wth_event_init(&(data->doneflags_event)) )
	{
		erresult = ETH_THREAD_ERROR;
		goto error_15;
	}
	
	if( (data->queries_replies=dbll_new()) == NULL )
	{
		// Problem creating empty list for queries/replies
		erresult = ETH_MALLOC_ERROR;
		goto error_20;
	}

	if( wth_event_init(&(data->replies_event)) )
	{
		erresult = ETH_THREAD_ERROR;
		goto error_30;
	}
	
	if( wth_mutex_init(&(data->timeout_mutex)) )
	{
		erresult = ETH_THREAD_ERROR;
		goto error_35;
	}

	if( (data->evt_queue=dbll_new()) == NULL )
	{
		// Problem creating empty list for events
		erresult = ETH_MALLOC_ERROR;
		goto error_40;
	}


	if( wth_mutex_init(&(data->event_handler_change_mutex)) )
	{
		erresult = ETH_THREAD_ERROR;
		goto error_45;
	}

	
	if( wth_event_init(&(data->evt_info_event)) )
	{
		erresult = ETH_THREAD_ERROR;
		goto error_50;
	}


	if( (data->evt_callback_queue=dbll_new()) == NULL )
	{
		erresult = ETH_THREAD_ERROR;
		goto error_55;
	}


	if( wth_mutex_init(&(data->sequence_mutex)) )
	{
		erresult = ETH_THREAD_ERROR;
		goto error_60;
	}


	// Open a network socket to the device
	if( (erresult=eth32_socket_open(address, port, &(data->socket), timeout))  )
	{
		// erresult is already set from the above function call.
		goto error_65;
	}

	
	// At this point, keep the socket in blocking mode.
	// Uncomment to put into nonblocking.
	//eth32_socket_blocking(data->socket, 0);
	// Disable any buffering delays
	//eth32_socket_nodelay(data->socket, 1);
	
	// Set default values for any data member that doesn't default to zero
	data->timeout = TIMEOUT_DEFAULT; // API call timeout
	// These aren't critical, but give some reasonable defaults for the event_handler
	// fields if the user is to do a get_event_handler and inspect them.
	data->event_handler.maxqueue = CALLBACK_DEFAULT; // max queue size for callback events
	
	// Launch a thread dedicated to reading from the socket
	if( wth_thread_create(eth32_readthread, (void*)data, &(data->readthread_handle)) )
	{
		erresult=ETH_RTHREAD_ERROR;
		goto error_70;
	}

	/* If we're on a Windows machine, keep track of this opened device */
	eth32_devtable_add(data);

	if(result)
		*result = 0;

	// All seems to be success
	return(data); /* return a pointer to the structure we just allocated and initialized */


error_70: /* Failed to launch reading thread, need to close socket */
	eth32_socket_close(data->socket);

error_65: /* destroy sequence_mutex */
	wth_mutex_destroy(&(data->sequence_mutex));

error_60: /* destroy evt_callback_queue */
	dbll_destroy_list(data->evt_callback_queue);

error_55: /* destroy evt_info_event */
	wth_event_destroy(&(data->evt_info_event));

error_50: /* destroy event_handler_change_mutex */
	wth_mutex_destroy(&(data->event_handler_change_mutex));

error_45: /* Failed to init evt_info_event, destroy evt_queue list */
	dbll_destroy_list(data->evt_queue);

error_40: /* destroy timeout_mutex */
	wth_mutex_destroy(&(data->timeout_mutex));

error_35: /* destroy replies_event */
	wth_event_destroy(&(data->replies_event));

error_30: /* failed to init replies_event, destroy replies list */
	dbll_destroy_list(data->queries_replies);

error_20: /* failed to init replies list, destroy flags_event */
	wth_event_destroy(&(data->doneflags_event));

error_15: /* failed to init doneflags_event, destroy refcount_event */
	wth_event_destroy(&(data->refcount_event));
	
error_10: /* just free the memory and return an error */
	free(data);

	if(result)
		*result = erresult;
	return(0);
}

int CALLCONVENTION eth32_close(eth32 handle)
{
	if(!handle)
		return(ETH_INVALID_HANDLE);
	
	// Don't increase reference counter for this.
		
	// A normal close doesn't force without waiting for a graceful
	// exit of the various threads, etc, so specify zero here.

	
	return(eth32_close_int(handle, 0));
}

int CALLCONVENTION eth32_set_timeout(eth32 handle, unsigned int timeout)
{
	/* This function configures the timeout used for all applicable 
	 * API functions that wait for a response from the device, etc.
	 * timeout is specified in milliseconds.  A timeout of 0 means
	 * to never time out (infinite)
	 */
	int res;
	int retval;
	
	if( (res=eth32_check(handle, 1)) )
		return(res);
	
	if((res=eth32_refcount(handle, 1)))
		return(res);
	
	if( wth_mutex_wait(&(handle->timeout_mutex), 0) )
	{
		retval=ETH_THREAD_ERROR;
		goto release;
	}

	handle->timeout = timeout;

	if( wth_mutex_release(&(handle->timeout_mutex)) )
	{
		retval=ETH_THREAD_ERROR;
		goto release;
	}
	
	retval=0;
release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_timeout(eth32 handle, unsigned int *timeout)
{
	/* Returns the currently-configured timeout configured within 
	 * the API, whatever that may be.  The timeout is returned in 
	 * milliseconds
	 */
	int res;
	int retval;
	
	if( (res=eth32_check(handle, 1)) )
		return(res);

	if(!timeout)
		return(ETH_INVALID_POINTER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	if( wth_mutex_wait(&(handle->timeout_mutex), 0) )
	{
		retval=ETH_THREAD_ERROR;
		goto release;
	}

	*timeout = handle->timeout;

	if( wth_mutex_release(&(handle->timeout_mutex)) )
	{
		retval=ETH_THREAD_ERROR;
		goto release;
	}
		 
	retval=0;
release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_verify_connection(eth32 handle)
{
	/* Sends a ping to the board and waits for a response.
	 * Returns 0 if all is well, otherwise the appropriate
	 * error, most likely to be ETH_TIMEOUT
	 */

	unsigned char query[CMDLEN]={CMD_PING};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;
	
	retval=eth32_query_reply(handle, query, reply, 0, ptout);
	
//release:
	eth32_refcount(handle, -1);
	return(retval);	
}

int CALLCONVENTION eth32_output_byte(eth32 handle, int port, int value)
{
	// Write a new value to the given port's output register
	
	unsigned char cmd[CMDLEN]={CMD_OPORT};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	// Allow writing to all ports, including the special control lines
	// and the LEDs, even though there are separate functions for the LEDs
	if(port < 0 || port >= NUM_ALLPORTS)
		return(ETH_INVALID_PORT);
	
	if(value<0 || value>0xff)
		return(ETH_INVALID_VALUE);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	cmd[1]=port;
	cmd[2]=value;
	
	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
		retval=res;
	else
		retval=0;
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_output_bit(eth32 handle, int port, int bit, int value)
{
	// Set or clear an individual bit of the given port.
	// nonzero value sets the bit, zero value clears it.
	unsigned char cmd[CMDLEN]={0};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	// Allow writing to all ports, including the special control lines
	// and the LEDs, even though there are separate functions for the LEDs
	if(port < 0 || port >= NUM_ALLPORTS)
		return(ETH_INVALID_PORT);
	
	if(bit <0 || bit > 7)
		return(ETH_INVALID_BIT);


	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	cmd[1]=port;
	if(value)
	{
		cmd[0]=CMD_SBIT;
		cmd[2]= 1 << bit;
	}
	else
	{
		cmd[0]=CMD_CBIT;
		cmd[2]= ~(1 << bit);
	}
	
	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
		retval=res;
	else
		retval=0;
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_pulse_bit(eth32 handle, int port, int bit, int edge, int count)
{
	// Pulse an individual bit of the given port.
	// Pulse can be specified as having a falling edge, then going back to high
	// or rising edge, then going back to low.
	//  edge of 0 means falling, 1 means rising
	unsigned char cmd[CMDLEN]={CMD_PULSE};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	// Allow writing to all ports, including the special control lines
	// and the LEDs, even though there are separate functions for the LEDs
	if(port < 0 || port >= NUM_ALLPORTS)
		return(ETH_INVALID_PORT);
	
	if(bit < 0 || bit > 7)
		return(ETH_INVALID_BIT);
	
	if(edge != PULSE_FALLING && edge != PULSE_RISING)
		return(ETH_INVALID_OTHER);
	
	if(count<0 || count>0xff)
		return(ETH_INVALID_OTHER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================
	
		
	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	cmd[1]=port;
	cmd[2]=bit;
	cmd[3]=edge;
	cmd[4]=count;
	
	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
		retval=res;
	else
		retval=0;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_set_led(eth32 handle, int led, int value)
{
	// Set the value of one of the LEDs.  We'll just pass the information
	// off and return the value of output_byte
	// led should be either 0 or 1
	// value of 0 turns the LED off, nonzero turns it on.
	
	if(led<0 || led>1)
		return(ETH_INVALID_OTHER);
	
	return(eth32_output_byte(handle, 6+led, (value ? 1 : 0)));
}

int CALLCONVENTION eth32_input_byte(eth32 handle, int port, int *value)
{
	// Read a value from the given port.
	unsigned char query[CMDLEN]={CMD_IPORT};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if(!value)
		return(ETH_INVALID_POINTER);

	// Allow reading from all ports, including the special control lines
	// and the LEDs, even though there are separate functions for the LEDs
	if(port < 0 || port >= NUM_ALLPORTS)
		return(ETH_INVALID_PORT);
		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	query[2]=port;

	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
		*value=reply[3];
	retval=res;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_input_successive(eth32 handle, int port, int max, int *value, int *status)
{
	// Do a successive read on the given port.
	//  max: max times the port should be read
	//  value: the last value read from the port, regardless of
	//         whether there was a match.
	//  status: indicates the result of the command.  Any nonzero
	//          value indicates that a match was found after that
	//          many reads.  A zero value indicates that the maximum
	//          number of reads were done without finding a match.
	unsigned char query[CMDLEN]={CMD_SRD};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if(!value)
		return(ETH_INVALID_POINTER);

	// Allow reading from all ports, including the special control lines
	// and the LEDs, even though there are separate functions for the LEDs
	if(port < 0 || port >= NUM_ALLPORTS)
		return(ETH_INVALID_PORT);
	if(max < 2 || max>0xff)
		return(ETH_INVALID_OTHER);
	
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	query[2]=port;
	query[3]=max;

	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
	{
		// Return port value regardless, and return how many times
		// the port was actually read (or 0 for failure to find a match)
		*status=reply[3];
		*value=reply[4];
	}

	retval=res;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}


int CALLCONVENTION eth32_input_bit(eth32 handle, int port, int bit, int *value)
{
	int v;
	int res;

	// No reference counting needed since the only thing that accesses the handle
	// is eth32_input_byte and that's already taken care of.
	
	if(port < 0 || port >= NUM_ALLPORTS)
		return(ETH_INVALID_PORT);

	if(bit < 0 || bit > 7)
		return(ETH_INVALID_BIT);
		
	if(!value)
		return(ETH_INVALID_POINTER);

	if( (res=eth32_input_byte(handle, port, &v)) )
		return(res);
	
	*value = (v & (1 << bit)) ? 1 : 0;
	return(0);
}

int CALLCONVENTION eth32_readback(eth32 handle, int port, int *value)
{
	// Read back the output register from the given port.
	unsigned char query[CMDLEN]={CMD_RBOUT};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if(!value)
		return(ETH_INVALID_POINTER);

	// Allow reading from all ports, including the special control lines
	// and the LEDs, even though there are separate functions for the LEDs
	if(port < 0 || port >= NUM_ALLPORTS)
		return(ETH_INVALID_PORT);

		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	query[2]=port;

	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
		*value=reply[3];
	retval=res;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_led(eth32 handle, int led, int *value)
{
	// Return the current status of an LED
	
	return(eth32_readback(handle, 6+led, value));
}

int CALLCONVENTION eth32_set_direction(eth32 handle, int port, int direction)
{
	// Set the direction of a given port.  1-bits in direction configure
	// that bit as output.
	// User may use the constants DIR_OUTPUT and DIR_INPUT to configure
	// all lines of the port the same.

	unsigned char cmd[CMDLEN]={CMD_SPDIR};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	// Allow changing direction of all ports except the LEDs
	if(port < 0 || port >= NUM_DIRECTIONPORTS)
		return(ETH_INVALID_PORT);
	
	if(direction<0 || direction>0xff)
		return(ETH_INVALID_OTHER);

		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	cmd[1]=port;
	cmd[2]=direction;
	cmd[3]=0; // Copy mode - set register exactly as we specify it.
	
	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
		retval=res;
	else
		retval=0;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_direction(eth32 handle, int port, int *direction)
{
	// Return the direction register for the given port.
	unsigned char query[CMDLEN]={CMD_GPDIR};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if(!direction)
		return(ETH_INVALID_POINTER);

	// Allow reading from all ports
	if(port < 0 || port >= NUM_ALLPORTS)
		return(ETH_INVALID_PORT);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	query[2]=port;

	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
		*direction=reply[3];
	retval=res;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_set_direction_bit(eth32 handle, int port, int bit, int direction)
{
	// This function allows an individual direction register bit to be 
	// set or cleared without affecting the other bits of the register.
	
	unsigned char cmd[CMDLEN]={CMD_SPDIR};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	// Allow changing direction of all ports except the LEDs
	if(port < 0 || port >= NUM_DIRECTIONPORTS)
		return(ETH_INVALID_PORT);

	if(bit < 0 || bit > 7)
		return(ETH_INVALID_BIT);

		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;
	
	
	cmd[1]=port;
	
	if(direction)
	{
		// If set, we need to set the bit
		cmd[2]=(1 << bit);
		cmd[3]=1; // OR
	}
	else
	{
		// Otherwise, we need to clear the bit
		cmd[2]= ~(1 << bit);
		cmd[3]=2; // AND
	}
	
	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
		retval=res;
	else
		retval=0;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_direction_bit(eth32 handle, int port, int bit, int *direction)
{
	// This function is purely for convenience.  It calls the regular
	// get_direction and simply masks out the other bits.

	int v;
	int res;

	if(port < 0 || port >= NUM_ALLPORTS)
		return(ETH_INVALID_PORT);

	if(bit < 0 || bit > 7)
		return(ETH_INVALID_BIT);

	if(!direction)
		return(ETH_INVALID_POINTER);


	if( (res=eth32_get_direction(handle, port, &v)) )
	{
		// If there was an error, abort and return it
		return(res);
	}
	
	*direction = (v & (1 << bit)) ? 1 : 0;

	return(0);
}


int CALLCONVENTION eth32_set_analog_state(eth32 handle, int state)
{
	// Enable/disable the ADC
	//   state: 0 means disable the ADC
	//          1 means enable the ADC
	unsigned char cmd[CMDLEN]={CMD_SASTA};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(state != ADC_DISABLED && state != ADC_ENABLED)
		return(ETH_INVALID_OTHER);

	
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;


	cmd[1]=ANALOG_PORT; // only applies to the analog port
	cmd[2]=state;
	
	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
		retval=res;
	else
		retval=0;
	
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_analog_state(eth32 handle, int *state)
{
	// Return the status of the ADC
	unsigned char query[CMDLEN]={CMD_GASTA};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if(!state)
		return(ETH_INVALID_POINTER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	query[2]=ANALOG_PORT;

	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
		*state=reply[3];
	
	retval=res;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_input_analog(eth32 handle, int channel, int *value)
{
	// Read a value from the given analog channel.
	unsigned char query[CMDLEN]={CMD_IANLG};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if(!value)
		return(ETH_INVALID_POINTER);

	if(channel < 0 || channel > 7)
		return(ETH_INVALID_CHANNEL);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	query[2]=channel;

	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
		*value=(reply[3]<<2) | (reply[4]>>6);
	
	retval=res;
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_set_analog_reference(eth32 handle, int reference)
{
	// Set analog voltage reference selection
	unsigned char cmd[CMDLEN]={CMD_SREF};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(reference != REF_EXTERNAL &&
	   reference != REF_INTERNAL &&
	   reference != REF_256)
		return(ETH_INVALID_OTHER);
		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;


	cmd[1]=reference;

	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
		retval=res;
	else
		retval=0;
	
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_analog_reference(eth32 handle, int *reference)
{
	// Return the currently configured analog voltage reference source
	unsigned char query[CMDLEN]={CMD_GREF};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if(!reference)
		return(ETH_INVALID_POINTER);

		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	res=eth32_query_reply(handle, query, reply, 0, ptout);
	if(res==0)
		*reference=reply[2];
	retval=res;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_set_analog_eventdef(eth32 handle, int bank, int channel, int lomark, int himark, int defaultval)
{
	// Configure the threshold levels for the given analog event definition.
	//  bank: 0 or 1
	//  channel: 0-7
	//  lomark: low threshold for signal, specified as 8-bit value
	//  himark: high threshold for signal, specified as 8-bit value
	//  defaultval: specifies whether initial event level should be
	//              low (0) or high (1) if the signal is in between
	//              the given thresholds.
	unsigned char cmd[CMDLEN]={CMD_SAEVT};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(bank < 0 || bank >= NUM_ANALOG_EVENT_BANKS)
		return(ETH_INVALID_OTHER);
	
	if(channel < 0 || channel > 7)
		return(ETH_INVALID_CHANNEL);
	
	if(lomark < 0 || lomark > 0xff)
		return(ETH_INVALID_OTHER);
		
	if(himark < 0 || himark > 0xff)
		return(ETH_INVALID_OTHER);
	
	if(lomark >= himark)
		return(ETH_INVALID_OTHER);
	
	if(defaultval != ANEVT_DEFAULT_LOW &&
	   defaultval != ANEVT_DEFAULT_HIGH)
	   return(ETH_INVALID_OTHER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;


	cmd[1]=(defaultval ? 0x80 : 0x00) | (bank ? 0x08 : 0x00) | channel;
	cmd[2]=lomark;
	cmd[3]=himark;

	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
		retval=res;
	else
		retval=0;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_analog_eventdef(eth32 handle, int bank, int channel, int *lomark, int *himark)
{
	// Return the currently-defined analog event thresholds from the given
	// bank and channel.  This does not return what the "default state"
	// was when the event was initially defined since that only afffected that
	// moment of definition and does not have any lasting effect.
	unsigned char query[CMDLEN]={CMD_GAEVT};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if( (!lomark) || (!himark) )
		return(ETH_INVALID_POINTER);

	if(bank <0 || bank >= NUM_ANALOG_EVENT_BANKS)
		return(ETH_INVALID_OTHER);

	if(channel < 0 || channel > 7)
		return(ETH_INVALID_CHANNEL);


	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;
	
	query[2]=(bank ? 0x08 : 0x00) | channel;

	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
	{
		*lomark=reply[3];
		*himark=reply[4];
	}
	
	retval=res;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_set_analog_assignment(eth32 handle, int channel, int source)
{
	// Set the MUX selection for the given analog channel
	unsigned char cmd[CMDLEN]={CMD_SCHAS};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(channel < 0 || channel > 7)
		return(ETH_INVALID_CHANNEL);

	if(source < 0 || source > 0x1f)
		return(ETH_INVALID_OTHER);

		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

		
	cmd[1]=channel;
	cmd[2]=source;

	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
		retval=res;
	else
		retval=0;
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_analog_assignment(eth32 handle, int channel, int *source)
{
	// Return the current MUX value configured for the given analog channel
	unsigned char query[CMDLEN]={CMD_GCHAS};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(channel < 0 || channel > 7)
		return(ETH_INVALID_CHANNEL);

		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	query[2]=channel;

	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
		*source=reply[3];
	
	retval=res;	

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_reset(eth32 handle)
{
	// Reset the port configuration and assignments, 
	// disable all events and reset all event IDs.  This does
	// not remove any existing events from the event queue.
	unsigned char cmd[CMDLEN]={CMD_RST};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================
	
	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
	{
		retval=res;
		goto release;
	}

	// Reset our event information
	memset(handle->evt_ports, 0, sizeof(handle->evt_ports));
	memset(handle->evt_bit, 0, sizeof(handle->evt_bit));
	handle->evt_heartbeat.enabled=0;
	handle->evt_heartbeat.id=0;

	// Leave the event handler configuration untouched so that all the user has to do
	// to re-subscribe to an event is call enable_event.
	
	retval=0;
release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_serialnum(eth32 handle, int *batch, int *unit)
{
	// Return the device's serial number
	unsigned char query[CMDLEN]={CMD_SNBAT};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if((!batch) || (!unit))
		return(ETH_INVALID_POINTER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================
	
	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	// First get the batch number
	res=eth32_query_reply(handle, query, reply, 0, ptout);
	if(res==0)
		*batch=(reply[2]<<8) | reply[3];
	else
	{
		retval=res;
		goto release;
	}
	
	// Now get the unit number.  Note that our timeout
	// does NOT start over so this entire process must complete
	// within the normal timeout
	query[0]=CMD_SNUNT;
	res=eth32_query_reply(handle, query, reply, 0, ptout);
	if(res==0)
		*unit=(reply[2]<<8) | reply[3];
	
	
	retval=res;
release:
	eth32_refcount(handle, -1);
	return(retval);
}


int CALLCONVENTION eth32_get_serialnum_string(eth32 handle, char *serial, int bufsize)
{
	// Return the serial number as a human-readable string 
	// as it is printed on the product case.
	// serial - points to a buffer into which the serial number will be written
	// bufsize - size of the buffer pointed to by serial.  No more than
	//           this number of bytes will be written to the buffer, including
	//           the NULL terminator.

	int res;
	int prodid;
	int batch;
	int unit;
	
	// Make sure the buffer is long enough for everything, including
	// a dash and a NULL.
	// The eth32cfg_serialnum_string function will do the final check, but we want to return an 
	// error as quickly as possible if we know ahead of time the buffer is too small.
	if(bufsize < (SERLEN_PRODID + 1 + SERLEN_BATCH + SERLEN_UNIT + 1))
	{
		return(ETH_BUFSIZE);
	}
	
	
	// Retrieve the serial number information
	if( (res=eth32_get_product_id(handle, &prodid)) )
	{
		return(res);
	}
	if( (res=eth32_get_serialnum(handle, &batch, &unit)) )
	{
		return(res);
	}
	
	if( (res=eth32cfg_serialnum_string(prodid, batch, unit, serial, bufsize)) )
	{
		return(res);
	}

	return(0);
}


int CALLCONVENTION eth32_get_product_id(eth32 handle, int *prodid)
{
	// Return the device's product ID
	unsigned char query[CMDLEN]={CMD_PRID};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(!prodid)
		return(ETH_INVALID_POINTER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	res=eth32_query_reply(handle, query, reply, 0, ptout);
	if(res==0)
		*prodid=reply[2];

	retval=res;
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_firmware_release(eth32 handle, int *major, int *minor)
{
	// Return the device's firmware release numbers
	unsigned char query[CMDLEN]={CMD_FREL};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if((!major) || (!minor))
		return(ETH_INVALID_POINTER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	res=eth32_query_reply(handle, query, reply, 0, ptout);
	if(res==0)
	{
		*major=reply[2];
		*minor=reply[3];
	}

	retval=res;
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_connection_flags(eth32 handle, int reset, int *flags)
{
	// This function returns the connection flags for our connection to
	// the device.  The flags indicate whether data has been discarded 
	// due to a full queue.
	// If the reset argument is nonzero, this function will also result
	// in the flags being reset to zero.
	unsigned char query[CMDLEN]={CMD_CFLAG};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if( !flags )
		return(ETH_INVALID_POINTER);

		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	if(reset)
		query[2]=1;
	else
		query[2]=0;
	
	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
	{
		*flags=reply[3];
	}

	retval=res;
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_set_event_queue_config(eth32 handle, int maxsize, int fullqueue)
{
	// Set the maximum size of the event queue and what to do
	// if it ever gets full.
	// If 0 is specified, the queue is effectively disabled.
	
	int res;
	int retval;
	
	if( (res=eth32_check(handle, 1)) )
		return(res);

	if(maxsize<0)
		maxsize=0;
	
	if(fullqueue<QUEUE_DISCARD_NEW || fullqueue>QUEUE_DISCARD_OLD)
		return(ETH_INVALID_OTHER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	wth_event_prewait(&(handle->evt_info_event));

	// If we need to shorten the list, go ahead, removing from 
	// the head of the list.
	while(maxsize < handle->evt_queue->count)
	{
		dbll_remove_node(handle->evt_queue, handle->evt_queue->head);
	}
	
	// Store the new configuration
	handle->evt_queue_size=maxsize;
	handle->evt_queue_fullqueue=fullqueue;

	// Signal any waiters since if the size is now zero, anybody waiting for
	// data to arrive into the queue will no longer have reason to wait since
	// the queue would be disabled.  Currently, this is only real valuable
	// when we're setting the size to 0, but we'll go ahead and signal always
	// just in case someone wants to be aware of the size change.
	wth_event_broadcast(&(handle->evt_info_event));
	wth_event_release(&(handle->evt_info_event));
	
	retval=0;
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_event_queue_status(eth32 handle, int *maxsize, int *fullqueue, int *cursize)
{
	// Report on the current configuration of the event queue as well as how many
	// events are currently queued.
	//  None of the pointers are required (may be NULL).  If they are 
	//  not given, they will simply be ignored.
	int res;
	int retval;
	
	if( (res=eth32_check(handle, 1)) )
		return(res);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	
	wth_event_prewait(&(handle->evt_info_event));

	if(maxsize)
		*maxsize=handle->evt_queue_size;
	if(fullqueue)
		*fullqueue=handle->evt_queue_fullqueue;
	if(cursize)
		*cursize=handle->evt_queue->count;
	
	wth_event_release(&(handle->evt_info_event));
	
	retval=0;
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_dequeue_event(eth32 handle, eth32_event *event, int timeout)
{
	// Retrieve the next event from the user's event queue and store into
	//  *event.
	// If there is not currently an event in the queue to be retrieved,
	// the function's behavior is determined by the timeout parameter.
	//  timeout:  positive - max number of milliseconds to wait before returning TIMEOUT
	//                   0 - Return TIMEOUT immediately if no event is available
	//            negative - Wait indefinitely for an event to become available.

	unsigned int *ptout;
	int retval=0;
	int res;
	int check;
	evtqueuenode_t *node;

	// Since this doesn't involve any immediate network communication, don't
	// do the normal eth32_check here.  We want to be able to retrieve leftover
	// events even after we've been disconnected
	if(!handle)
		return(ETH_INVALID_HANDLE);

	if(!event)
		return(ETH_INVALID_POINTER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	if(timeout>=0)
		ptout=(unsigned int*)&timeout;
	else
		ptout=NULL; // Wait indefinitely

	
	wth_event_prewait( &(handle->evt_info_event) );
	
	// If the queue is disabled, we won't be getting anywhere with this.
	if(handle->evt_queue_size<=0)
	{
		retval=ETH_WRONG_MODE;
		goto exit_label;
	}
	
	// If there are no items in the queue and we're not willing to wait,
	// exit with a timeout immediately
	if(handle->evt_queue->count==0 && timeout==0)
	{
		retval=ETH_TIMEOUT;
		goto exit_label;
	}
	
	// Wait until there is data OR until we detect a problem that caused
	// the reading thread to exit, meaning no more data is ever on the way,
	// OR the queue has been disabled
	res=0;
	check=0;
	while( handle->evt_queue->count==0 && handle->evt_queue_size>0 && !(check=eth32_check(handle, 0)) )
	{
		if( (res=wth_event_wait( &(handle->evt_info_event), ptout)) )
			break; // error or timeout
	}
	/* handle any error */
	if(res)
	{
		if(res == 1)
			retval=ETH_TIMEOUT;
		else
			retval=ETH_THREAD_ERROR;
		goto exit_label;
	}
	if(check) // Problem with the reading thread, so we won't be getting any more data.
	{
		retval=check;
		goto exit_label;
	}
	
	// If we're here, then the event_wait was NOT the reason we exited
	// the above loop, NOR was a reading thread error.
	// So we either have queue data OR the event queue has since been disabled.
	// First check for data.
	if(handle->evt_queue->count)
	{
		node=handle->evt_queue->head;
		*event=node->event;
		dbll_remove_node(handle->evt_queue, node);
		// fall through to exit successfully.
	}
	else //if(handle->evt_queue_size<=0)
	{
		// The event queue has since been disabled "behind our back"
		// Return a late-breaking notice that this new configuration
		// won't allow us to wait for the queue
		retval=ETH_WRONG_MODE;
		goto exit_label;
	}


exit_label:
	wth_event_release( &(handle->evt_info_event) );
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_empty_event_queue(eth32 handle)
{
	// This function removes all events that are queued up in the event
	// queue, if any.  It discards all the information.
	eth32_event evtinfo;

	// The only way we should return an error is if they specify
	// an invalid handle.  Otherwise, even if the event queue isn't
	// even enabled, we should just deal with all situations.  If it
	// isn't enabled, then there's nothing to empty and our job is done.	
	if(!handle)
		return(ETH_INVALID_HANDLE);

	// Just keep dequeueing while it tells us we were successful
	while(eth32_dequeue_event(handle, &evtinfo, 0)==0)
		;
	
	return(0);
}

int CALLCONVENTION eth32_enable_event(eth32 handle, int type, int port, int bit, int id)
{
	// Enable reception of an event notification.  This sets up the information
	// locally and also tells the board to send the specified events.
	// Calling this function when the event is already enabled does not hurt
	// anything, it just will replace the ID with the new one given.
	unsigned char cmd[CMDLEN]={0};
	int res;
	int retval;
	int index; // index into event structure
	unsigned char bitmask;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;
	
	switch(type)
	{
		case EVENT_DIGITAL:
			if(port < 0 || port>=NUM_DIGPORTS)
			{
				retval=ETH_INVALID_PORT;
				goto release;
			}
			if(bit < -1  ||  bit > 7)
			{
				retval=ETH_INVALID_BIT;
				goto release;
			}
			if(bit == -1) // Port event
			{
				handle->evt_ports[port].id=id;
				handle->evt_ports[port].enabled=1;
				bitmask=0xff;
			}
			else
			{ // bit must be from 0 through 7
				handle->evt_bit[port][(int)bit].id=id;
				handle->evt_bit[port][(int)bit].enabled=1;
				bitmask=1<<bit;
			}
			cmd[0]=CMD_EEVT;
			cmd[1]=port;
			cmd[2]=bitmask;

			res=eth32_write_data(handle, cmd, CMDLEN, ptout);
			break;
		case EVENT_ANALOG:
			if(port < 0 || port>1) // used to indicate bank
			{
				retval=ETH_INVALID_PORT;
				goto release;
			}
			if(bit<0 || bit>7)
			{
				retval=ETH_INVALID_CHANNEL;
				goto release;
			}
			
			if(port==0)
				index=EVT_INDEX_ANALOG_0;
			else
				index=EVT_INDEX_ANALOG_1;
				
			handle->evt_bit[index][(int)bit].id=id;
			handle->evt_bit[index][(int)bit].enabled=1;
			
			cmd[0]=CMD_EEVT;
			cmd[1]=index;
			cmd[2]=1<<bit;
			res=eth32_write_data(handle, cmd, CMDLEN, ptout);
			break;
			
		case EVENT_COUNTER_ROLLOVER:
			if(port<0 || port>=NUM_COUNTERS)
			{
				retval=ETH_INVALID_PORT;
				goto release;
			}
			
			handle->evt_bit[EVT_INDEX_COUNTER_ROLLOVER][port].id=id;
			handle->evt_bit[EVT_INDEX_COUNTER_ROLLOVER][port].enabled=1;
			
			cmd[0]=CMD_EEVT;
			cmd[1]=EVT_INDEX_COUNTER_ROLLOVER;
			cmd[2]=1<<port;
			res=eth32_write_data(handle, cmd, CMDLEN, ptout);
			break;
			
		case EVENT_COUNTER_THRESHOLD:
			// This is only supported on counter 0
			if(port != 0)
			{
				retval=ETH_INVALID_PORT;
				goto release;
			}
			
			handle->evt_bit[EVT_INDEX_COUNTER_EVENT][port].id=id;
			handle->evt_bit[EVT_INDEX_COUNTER_EVENT][port].enabled=1;
			
			cmd[0]=CMD_EEVT;
			cmd[1]=EVT_INDEX_COUNTER_EVENT;
			cmd[2]=1<<port;
			res=eth32_write_data(handle, cmd, CMDLEN, ptout);
			break;
		case EVENT_HEARTBEAT:
			// Heartbeats are always enabled on the board itself, we just
			// need to indicate that we want to pass them through to the 
			// user application.
			handle->evt_heartbeat.id=id;
			handle->evt_heartbeat.enabled=1;
			res=0;
			break;
		default:
			retval=ETH_INVALID_OTHER;
			goto release;
	}

	if(res<0)
		retval=res;
	else
		retval=0;

release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_disable_event(eth32 handle, int type, int port, int bit)
{
	// Disable reception of the specified event notification
	unsigned char cmd[CMDLEN]={0};
	int res;
	int retval;
	int i;
	int index;
	unsigned char bitmask;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;
	
	switch(type)
	{
		case EVENT_DIGITAL:
			if(port<0 || port>=NUM_DIGPORTS)
			{
				retval=ETH_INVALID_PORT;
				goto release;
			}
			if(bit < -1  ||  bit > 7)
			{
				retval=ETH_INVALID_BIT;
				goto release;
			}
			if(bit == -1) // Port event
			{
				handle->evt_ports[port].enabled=0;
				// Figure out what bits to disable.  Start by
				// disabling all:
				bitmask=0;
				// If we're interested in any of the bit events for
				// this port, then don't disable those.
				for(i=0; i<8; i++)
				{
					if(handle->evt_bit[port][i].enabled)
						bitmask |= (1 << i);
				}
			}
			else
			{
				// Bit event - but must be from 0 to 7
				handle->evt_bit[port][(int)bit].enabled=0;
				// Figure out what bits to disable.
				// If the port event for this port is enabled, we can't 
				// disable any bits, otherwise just disable the bit that
				// the user specified.
				if(handle->evt_ports[port].enabled)
					bitmask = 0xff;
				else
					bitmask = ~(1<<bit);
			}
			
			// If the bitmask is 0xff, there's no sense in doing anything
			if(bitmask == 0xff)
				res=0;
			else
			{
				cmd[0]=CMD_DEVT;
				cmd[1]=port;
				cmd[2]=bitmask;

				res=eth32_write_data(handle, cmd, CMDLEN, ptout);
			}
			break;
		case EVENT_ANALOG:
			if(port<0 || port>1)
			{
				retval=ETH_INVALID_PORT;
				goto release;
			}
			if(bit<0 || bit>7)
			{
				retval=ETH_INVALID_CHANNEL;
				goto release;
			}
			
			if(port==0)
				index=EVT_INDEX_ANALOG_0;
			else
				index=EVT_INDEX_ANALOG_1;
			
			handle->evt_bit[index][(int)bit].enabled=0;
			
			cmd[0]=CMD_DEVT;
			cmd[1]=index;
			cmd[2]= ~(1<<bit);
			res=eth32_write_data(handle, cmd, CMDLEN, ptout);
			break;

		case EVENT_COUNTER_ROLLOVER:
			if(port < 0 || port>=NUM_COUNTERS)
			{
				retval=ETH_INVALID_PORT;
				goto release;
			}
			
			handle->evt_bit[EVT_INDEX_COUNTER_ROLLOVER][port].enabled=0;
			
			cmd[0]=CMD_DEVT;
			cmd[1]=EVT_INDEX_COUNTER_ROLLOVER;
			cmd[2]=~(1<<port);
			res=eth32_write_data(handle, cmd, CMDLEN, ptout);
			break;
			
		case EVENT_COUNTER_THRESHOLD:
			// This is only supported on counter 0
			if(port != 0)
			{
				retval=ETH_INVALID_PORT;
				goto release;
			}
			
			handle->evt_bit[EVT_INDEX_COUNTER_EVENT][port].enabled=0;
			
			cmd[0]=CMD_DEVT;
			cmd[1]=EVT_INDEX_COUNTER_EVENT;
			cmd[2]=~(1<<port);
			res=eth32_write_data(handle, cmd, CMDLEN, ptout);
			break;


		case EVENT_HEARTBEAT:
			// No need to send a command, just indicate that the user
			// doesn't want to see heartbeats
			handle->evt_heartbeat.enabled=0;
			res=0;
			break;
		default:
			retval=ETH_INVALID_OTHER;
			goto release;
	}

	if(res<0)
		retval=res;
	else
		retval=0;

release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_set_event_handler(eth32 handle, eth32_handler *handler)
{
	// The application calls this function to tell the API how it wants
	// to be notified of events.  There are a few possibilities
	// including no notification.

	int res;
	int retval;

	if( (res=eth32_check(handle, 1)) )
		return(res);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Call the real routine without forcing anything
	res=eth32_set_event_handler_int(handle, handler, 0);
	retval=res;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_event_handler(eth32 handle, eth32_handler *handler)
{
	// This function simply returns the currnetly-stored event handler configuration
	
	int res;
	int retval;

	if( (res=eth32_check(handle, 1)) )
		return(res);

	if(!handler)
		return(ETH_INVALID_POINTER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	wth_event_prewait( &(handle->evt_info_event) );
	
	// Just copy it over.
	*handler=handle->event_handler;

	wth_event_release( &(handle->evt_info_event) );

	retval=0;
//release:
	eth32_refcount(handle, -1);
	return(retval);
}



int CALLCONVENTION eth32_set_counter_state(eth32 handle, int counter, int state)
{
	// This function controls whether a counter is enabled, and, if it is
	// enabled, which edge of a signal it increments on.

	unsigned char cmd[CMDLEN]={CMD_SCSTA};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(counter < 0 || counter >= NUM_COUNTERS)
		return(ETH_INVALID_OTHER);

	if(   state != COUNTER_DISABLED
	   && state != COUNTER_FALLING
	   && state != COUNTER_RISING
	  )
		return(ETH_INVALID_OTHER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	cmd[1]=counter;
	cmd[2]=state;
	
	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
		retval=res;
	else
		retval=0;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_counter_state(eth32 handle, int counter, int *state)
{
	// This function retrieves the currently configured state of the 
	// specified counter and stores it into state
	unsigned char query[CMDLEN]={CMD_GCSTA};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(counter < 0 || counter >= NUM_COUNTERS)
		return(ETH_INVALID_OTHER);
	
	if(!state)
		return(ETH_INVALID_POINTER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	query[2]=counter;
	
	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
		*state=reply[3];
	retval=res;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_set_counter_value(eth32 handle, int counter, int value)
{
	// This function stores a given value as the current value of the 
	// specified counter.  The acceptable range of the value parameter
	// depends on which counter is specified.
	
	unsigned char cmd[CMDLEN]={CMD_CNTWR};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(counter < 0 || counter >= NUM_COUNTERS)
		return(ETH_INVALID_OTHER);

	if(value<0)
		return(ETH_INVALID_VALUE);
		
	if(counter==0 && value>0xffff)
		return(ETH_INVALID_VALUE);

	if(counter==1 && value>0xff)
		return(ETH_INVALID_VALUE);
	
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	cmd[1]=counter;
	cmd[2]=(unsigned char)((value >> 8)&0xff);
	cmd[3]=(unsigned char)(value & 0xff);
	
	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
		retval=res;
	else
		retval=0;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_counter_value(eth32 handle, int counter, int *value)
{
	// This function reads the current value of the counter.  Reading the 
	// counter does not affect its value in any way.
	unsigned char query[CMDLEN]={CMD_CNTRD};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(counter < 0 || counter >= NUM_COUNTERS)
		return(ETH_INVALID_OTHER);
	
	if(!value)
		return(ETH_INVALID_POINTER);
	
		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	query[2]=counter;
	
	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
	{
		// If the counter is 8-bit, don't consider the high byte
		if(counter==1)
			*value=reply[4];
		else
			*value=(reply[3]<<8) | reply[4];
		
	}
	retval=res;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_set_counter_rollover(eth32 handle, int counter, int rollover)
{
	// This function defines a rollover threshold for a counter.
	// When the counter's value would surpass the given value, the 
	// counter is instead reset to zero.
	// The acceptable range of the rollover parameter depends on the
	// size of the specified counter.

	unsigned char cmd[CMDLEN]={CMD_SCROL};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(counter<0 || counter >= NUM_COUNTERS)
		return(ETH_INVALID_OTHER);

	if(counter==0 && rollover>0xffff)
		return(ETH_INVALID_VALUE);

	if(counter==1 && rollover>0xff)
		return(ETH_INVALID_VALUE);


	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	cmd[1]=counter;
	cmd[2]=(unsigned char)(rollover >> 8);
	cmd[3]=(unsigned char)(rollover & 0xff);
	
	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
		retval=res;
	else
		retval=0;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_counter_rollover(eth32 handle, int counter, int *rollover)
{
	// This function retrieves the currently configured rollover threshold
	// for the given counter.
	
	unsigned char query[CMDLEN]={CMD_GCROL};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(counter<0 || counter >= NUM_COUNTERS)
		return(ETH_INVALID_OTHER);
	
	if(!rollover)
		return(ETH_INVALID_POINTER);
	
		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	query[2]=counter;
	
	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
	{
		// If the counter is 8-bit, don't consider the high byte
		if(counter==1)
			*rollover=reply[4];
		else
			*rollover=(reply[3]<<8) | reply[4];
		
	}
	
	retval=res;
	
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_set_counter_threshold(eth32 handle, int counter, int threshold)
{
	// This function defines a threshold that causes an event to be fired
	// when the counter value surpasses it.  The counter value is unaffected
	// when the event fires.  This functionality is only available with 
	// Counter 0 on the ETH32.

	unsigned char cmd[CMDLEN]={CMD_SCEVT};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(counter != 0) // Only applies to counter 0
		return(ETH_INVALID_OTHER);

	if(threshold<0 || threshold > 0xffff)
		return(ETH_INVALID_OTHER);	

		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	cmd[1]=counter;
	cmd[2]=(unsigned char)((threshold >> 8) & 0xff);
	cmd[3]=(unsigned char)(threshold & 0xff);
	
	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
		retval=res;
	else
		retval=0;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_counter_threshold(eth32 handle, int counter, int *threshold)
{
	// This function retrieves the currently configured event threshold
	// for the specified counter.
	
	unsigned char query[CMDLEN]={CMD_GCEVT};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(counter != 0) // Only applies to Counter 0
		return(ETH_INVALID_OTHER);
	
	if(!threshold)
		return(ETH_INVALID_POINTER);
	
		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	query[2]=counter;
	
	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
	{
		*threshold=(reply[3]<<8) | reply[4];
	}
	
	retval=res;	

//release:
	eth32_refcount(handle, -1);
	return(retval);
}




int CALLCONVENTION eth32_set_pwm_clock_state(eth32 handle, int state)
{
	// Enables or disables the main PWM clock from running
	// The state parameter is interpreted as follows:
	//    0 - disable (stop) the PWM clock
	//    1 - enable the PWM clock

	unsigned char cmd[CMDLEN]={CMD_SPCLK};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(state != PWM_CLOCK_DISABLED &&
	   state != PWM_CLOCK_ENABLED)
	   return(ETH_INVALID_OTHER);

	   
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	cmd[1]=(state) ? 1 : 0;
	
	res=eth32_write_data(handle, cmd, CMDLEN, ptout);
	if(res<0)
		retval=res;
	else
		retval=0;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_pwm_clock_state(eth32 handle, int *state)
{
	// Returns the status of the main PWM clock.
	// If successful, state will be written as follows:
	//   0 - PWM clock is disabled (stopped)
	//   1 - PWM clock is enabled (running)
	// Read a value from the given port.
	
	unsigned char query[CMDLEN]={CMD_GPCLK};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if(!state)
		return(ETH_INVALID_POINTER);

		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	res=eth32_query_reply(handle, query, reply, 0, ptout);
	if(res==0)
		*state=reply[2];
	
	retval=res;
	
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_set_pwm_base_period(eth32 handle, int period)
{
	// Define the base period of the PWM cycle
	// Values less than 3 or greater than 0xff are invalid

	unsigned char cmd[CMDLEN]={CMD_SPBAS};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(period<PWM_MINIMUM_BASE || period>0xffff)
		return(ETH_INVALID_OTHER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	cmd[1]=(unsigned char)(period>>8);
	cmd[2]=(unsigned char)(period & 0xff);
	
	res=eth32_write_data(handle, cmd, CMDLEN, ptout);

	if(res<0)
		retval=res;
	else
		retval=0;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_pwm_base_period(eth32 handle, int *period)
{
	// Get the base period of the PWM cycle

	unsigned char query[CMDLEN]={CMD_GPBAS};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if(!period)
		return(ETH_INVALID_POINTER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	res=eth32_query_reply(handle, query, reply, 0, ptout);
	if(res==0)
		*period=(reply[2]<<8) | (reply[3]);
	
	retval=res;
	
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_set_pwm_channel(eth32 handle, int channel, int state)
{
	// Set the state/mode of the specified channel
	// Channel can be 0 or 1
	// State can be 0, 1, or 2, as defined by the PWM_CHANNEL_* constants
	
	unsigned char cmd[CMDLEN]={CMD_SPCST};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(channel < 0 || channel >= NUM_PWM_OUTPUTS)
		return(ETH_INVALID_CHANNEL);
	
	if(state != PWM_CHANNEL_DISABLED &&
	   state != PWM_CHANNEL_NORMAL &&
	   state != PWM_CHANNEL_INVERTED)
	{
		return(ETH_INVALID_OTHER);
	}

	
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	cmd[1]=channel;
	cmd[2]=state;
	
	res=eth32_write_data(handle, cmd, CMDLEN, ptout);

	if(res<0)
		retval=res;
	else
		retval=0;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_pwm_channel(eth32 handle, int channel, int *state)
{
	// Retrieve the state/mode of the specified channel

	unsigned char query[CMDLEN]={CMD_GPCST};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if(channel < 0 || channel >= NUM_PWM_OUTPUTS)
		return(ETH_INVALID_CHANNEL);

	if(!state)
		return(ETH_INVALID_POINTER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================



	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	query[2]=channel;

	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
		*state=reply[3];
	
	retval=res;
	
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_set_pwm_duty_period(eth32 handle, int channel, int period)
{
	// Set the duty cycle of the specified channel, in terms of PWM clock counts

	unsigned char cmd[CMDLEN]={CMD_SPCDC};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(channel < 0 || channel >= NUM_PWM_OUTPUTS)
		return(ETH_INVALID_CHANNEL);
	
	if(period<0 || period>0xffff)
		return(ETH_INVALID_OTHER);
	
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	
	cmd[1]=channel;
	cmd[2]=(unsigned char)(period >> 8);
	cmd[3]=(unsigned char)(period & 0xff);

	
	res=eth32_write_data(handle, cmd, CMDLEN, ptout);

	if(res<0)
		retval=res;
	else
		retval=0;

//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_pwm_duty_period(eth32 handle, int channel, int *period)
{
	// Get the duty cycle of the specified channel, in terms of PWM clock counts
	
	unsigned char query[CMDLEN]={CMD_GPCDC};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int *ptout;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if(channel < 0 || channel >= NUM_PWM_OUTPUTS)
		return(ETH_INVALID_CHANNEL);

	if(!period)
		return(ETH_INVALID_POINTER);

		
	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================


	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	if(timeout)
		ptout=&timeout;
	else
		ptout=NULL;

	query[2]=channel;

	res=eth32_query_reply(handle, query, reply, 1, ptout);
	if(res==0)
		*period=(reply[3]<<8) | (reply[4]);
	
	retval=res;
	
//release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_set_pwm_parameters(eth32 handle, int channel, int state, float freq, float duty)
{
	// This function performs a variety of tasks in order to configure a PWM channel
	// It configures the PWM clock, the base frequency, the channel state, the channel
	// duty cycle, and puts the corresponding I/O pin into output mode.
	// All of this functionality could be done manually by calling the appropriate functions.
	// Note that if a channel is enabled, the I/O pin used for the output
	// will be put into output mode.  However, if a channel is disabled, 
	// the direction will not be affected.
	// NOTE:  All PWM signals on a board share the same frequency.  Therefore,
	//        if you specify a frequency different than the current setting, 
	//        it will affect any other active channels, and will also affect
	//        the duty cycle of those channels, since the duty cycle period
	//        will remain unchanged, but the base period doesn't.
	//    Parameters are as follows:
	//     channel: channel number (at the moment, 0 or 1)
	//     state:   channel state (PWM_CHANNEL_*)
	//     freq:    frequency of PWM signal, in HZ
	//              On the ETH32, the valid range is from 30.5 HZ
	//              to 40 KHZ.  If a frequency outside 
	//              of that range is given, it will be adjusted to the
	//              nearest possible setting.  Rounding will also occur
	//              (especially at higher frequencies)
	//     duty:    duty cycle ratio (percentage) specified as a fraction between 0 and 1

	int res;
	int retval;
	unsigned int timeout;
	int period;
	int dcperiod;

	if( (res=eth32_check(handle, 0)) )
		return(res);

	if(channel < 0 || channel >= NUM_PWM_OUTPUTS)
		return(ETH_INVALID_CHANNEL);

	if(state != PWM_CHANNEL_DISABLED &&
	   state != PWM_CHANNEL_NORMAL &&
	   state != PWM_CHANNEL_INVERTED)
	{
		return(ETH_INVALID_OTHER);
	}

	// If they passed in too small (or negative) frequency,
	// correct it.
	if(freq < ((float)PWM_CLOCK/65536.0))
		freq=((float)PWM_CLOCK/65536.0);
	
	// Same for duty cycle
	if(duty<0.0)
		duty=0.0;
	else if(duty>1.0)
		duty=1.0;

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

		
	
	// First we want to set up the PWM clock frequency
	// Calculate the period (how many clock cycles per waveform)
	period = ROUND((float)PWM_CLOCK/freq);
	
	// period is now the NUMBER of counts per wave, but what we
	// need to pass over the network is the THRESHOLD, which is
	// just one less than the number.
	period--;
	
	// Make sure period is within its limits
	if(period<PWM_MINIMUM_BASE)
		period=PWM_MINIMUM_BASE;
	else if(period>0xffff)
		period=0xffff;
	
	res=eth32_set_pwm_base_period(handle, period);
	// If there was an error, abort and return it
	if(res)
	{
		retval=res;
		goto release;
	}

			
	// NEXT TASK is to configure the duty cycle of the channel
	// Add 1 to period to make it the NUMBER of counts in the cycle
	// and we'll calculate the NUMBER of duty cycle counts.
	dcperiod = ROUND((float)(period+1)*duty);
	
	// Convert the duty cycle period back to threshold
	if(dcperiod > 0)
		dcperiod--;
	
	// Make sure it is within limits
	if(dcperiod < 0)
		dcperiod=0;
	else if(dcperiod>0xffff)
		dcperiod=0xffff;
	
	res=eth32_set_pwm_duty_period(handle, channel, dcperiod);
	// If there was an error, abort and return it
	if(res)
	{
		retval=res;
		goto release;
	}

	
	// Enable the main PWM clock
	res=eth32_set_pwm_clock_state(handle, 1);
	// If there was an error, abort and return it
	if(res)
	{
		retval=res;
		goto release;
	}

	
	// Configure the PWM channel state as desired
	res=eth32_set_pwm_channel(handle, channel, state);
	// If there was an error, abort and return it
	if(res)
	{
		retval=res;
		goto release;
	}

	if(state != PWM_CHANNEL_DISABLED)
	{
		// As long as the PWM channel is being enabled in some way,
		// we need to put the corresponding I/O pin in output mode.
		
		res=0;
		switch(channel)
		{
			case 0:
				res=eth32_set_direction_bit(handle, 2, 4, 1);
				break;
			
			case 1:
				res=eth32_set_direction_bit(handle, 2, 5, 1);
				break;
		}
		if(res)
		{
			retval=res;
			goto release;
		}
	}
	
	retval=0;
release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION eth32_get_pwm_parameters(eth32 handle, int channel, int *state, float *freq, float *duty)
{
	// This function retrieves several parameters that are configured for a
	// PWM channel and, where necessary, translates them into more
	// understandable terms.  All of this information could be individually 
	// obtained through other functions - this function simply makes it more
	// convenient.

	int res;
	int period;
	int dcperiod;

	// This function simply calls other publicly accessible functions, which are already 
	// protected with the reference counter, so we don't need to deal with the reference
	// counter in here.
	if( (res=eth32_check(handle, 0)) )
		return(res);

	
	if(channel < 0 || channel >= NUM_PWM_OUTPUTS)
		return(ETH_INVALID_CHANNEL);

	if( !state || !freq || !duty )
		return(ETH_INVALID_POINTER);
	
	// Get the channel state, and pass it directly through
	if( (res=eth32_get_pwm_channel(handle, channel, state)) )
		return(res);
	
	// Calculate the base frequency
	if( (res=eth32_get_pwm_base_period(handle, &period)) )
		return(res);
	
	*freq = (float)PWM_CLOCK/(float)(period+1);
	
	// Calculate the duty cycle
	if( (res=eth32_get_pwm_duty_period(handle, channel, &dcperiod)) )
		return(res);
	
	*duty = (float)(dcperiod+1)/(float)(period+1);
	
	return(0);
}

int CALLCONVENTION CALLEXTRA eth32_get_eeprom(eth32 handle, int address, int length, void *buffer)
{
	// This function retrieves data from the user-accessible EEPROM memory on-board the ETH32.
	// address specifies the starting address in the EEPROM.
	// "length" bytes will be stored into the user-provided buffer pointed to by buffer.
	
	unsigned char query[CMDLEN]={CMD_GEE2};
	unsigned char reply[CMDLEN];
	int res;
	int retval;
	unsigned int timeout;
	unsigned int timeouttemp;
	unsigned int *ptout;
	int i;
	unsigned char *userbuffer=buffer;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if(address<0 || address>255)
		return(ETH_INVALID_OTHER);
	
	if(length<0 || (address+length)>256)
		return(ETH_INVALID_OTHER);
	
	if(!userbuffer)
		return(ETH_INVALID_POINTER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	
	retval=0; // default to success return value
	for(i=0; i<length; i+=2)
	{
		if(timeout)
		{
			timeouttemp=timeout;
			ptout=&timeouttemp;
		}
		else
			ptout=NULL;
	
		
		query[2]=(unsigned char)(address+i);
	
		res=eth32_query_reply(handle, query, reply, 1, ptout);
		if(res==0)
		{
			userbuffer[i]=reply[3];
			if((i+1)<length)
				userbuffer[i+1]=reply[4];
		}
		else
		{
			retval=res;
			break;
		}
	}
	

// release:
	eth32_refcount(handle, -1);
	return(retval);
}

int CALLCONVENTION CALLEXTRA eth32_set_eeprom(eth32 handle, int address, int length, void *buffer)
{
	// This function stores data into the user-accessible EEPROM memory on-board the ETH32.
	// address specifies the starting address in the EEPROM.
	// "length" bytes will be stored and most be provided in the buffer.
	
	unsigned char cmd[CMDLEN]={0};
	int res;
	int retval;
	unsigned int timeout;
	unsigned int timeouttemp;
	unsigned int *ptout;
	int i;
	unsigned char *userbuffer=buffer;

	if( (res=eth32_check(handle, 0)) )
		return(res);
	
	if(address<0 || address>255)
		return(ETH_INVALID_OTHER);
	
	if(length<0 || (address+length)>256)
		return(ETH_INVALID_OTHER);
	
	if(!userbuffer)
		return(ETH_INVALID_POINTER);

	if((res=eth32_refcount(handle, 1)))
		return(res);
	// ================  Don't just return() after this point  =================

	// Set up timeout pointer.
	eth32_get_timeout(handle, &timeout);
	
	retval=0; // default to success return value
	// First write out all of the 3-byte sets that we can
	cmd[0]=CMD_SEE3;
	for(i=0; (i+2)<length; i+=3)
	{
		if(timeout)
		{
			timeouttemp=timeout;
			ptout=&timeouttemp;
		}
		else
			ptout=NULL;
	
		cmd[1]=(unsigned char)(address+i);
		cmd[2]=userbuffer[i];
		cmd[3]=userbuffer[i+1];
		cmd[4]=userbuffer[i+2];
	
		res=eth32_write_data(handle, cmd, CMDLEN, ptout);
		if(res<0)
		{
			retval=res;
			goto eeset_release;
		}
	}
	
	// Then finish off any remaining bytes:
	cmd[0]=CMD_SEE1;
	for(/* leave i unchanged */; i<length; i++)
	{
		if(timeout)
		{
			timeouttemp=timeout;
			ptout=&timeouttemp;
		}
		else
			ptout=NULL;
	
		cmd[1]=(unsigned char)(address+i);
		cmd[2]=userbuffer[i];
		cmd[3]=0;
		cmd[4]=0;
	
		res=eth32_write_data(handle, cmd, CMDLEN, ptout);
		if(res<0)
		{
			retval=res;
			goto eeset_release;
		}
	}
	

eeset_release:
	eth32_refcount(handle, -1);
	return(retval);
}



const char * CALLCONVENTION eth32_error_string(int errorcode)
{
	// Translate an error code into a string.
	int i;
	
	
	for(i=0; i<sizeof(eth_errinfo)/sizeof(eth_errinfo[0]); i++)
	{
		if(errorcode==eth_errinfo[i].code)
		{
			return(eth_errinfo[i].description);
		}
	}

	
	return(error_unknown);
}

// Undocumented, should never be used by most programs:
int CALLCONVENTION _eth32_socket_shutdown(eth32 handle, int how)
{
	int res;
	
	if( (res=eth32_check(handle, 0)) )
		return(res);

	return(eth32_socket_shutdown(handle->socket, how));
}
