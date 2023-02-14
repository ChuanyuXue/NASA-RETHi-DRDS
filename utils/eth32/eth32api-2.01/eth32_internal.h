/* Winford Engineering ETH32 API
 * Copyright 2005 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */

#ifndef eth32_internal_h
#define eth32_internal_h

// Force a definition of CALLCONVENTION here - if
// somebody else has defined it first, we don't want to 
// compile, because they may not have defined it correctly
// for exporting DLL symbols, etc.
#ifdef CALLCONVENTION
i_wont_compile!@#$;
#endif

#ifdef WINDOWS
#define CALLCONVENTION __stdcall
//#define CALLEXTRA __declspec(dllexport) 
#define CALLEXTRA
#endif

#ifdef LINUX
#define CALLCONVENTION
#define CALLEXTRA
#endif


#ifdef LINUX
#include <signal.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <netinet/tcp.h>
#include <pthread.h>
#include <netdb.h>
#include <errno.h>

#ifndef WORD_TYPEDEF
#define WORD_TYPEDEF
typedef unsigned short WORD;
#endif

#endif

#ifdef WINDOWS
#include <winsock2.h>
#include <windows.h>
#else
#include <sys/time.h>
#include <unistd.h>


#endif



// Indicate to eth32_types.h that we're going to define the eth32 type.
// And, give it a stub so that the eth32 types used will compile.
#define ETH32_TYPEDEF
typedef struct _eth32 *eth32;

#include "eth32.h"
#include "socket.h"
#include "commands.h"
#include "threads.h"
#include "dbllist.h"
#include <sys/types.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>



/* These are declarations and definitions intended only
 * for internal use within the API itself.
 * That's in constrast to eth32.h which is meant to
 * be distributed with the API.
 */

// Number of full-blown Digital Ports
// PORTG has the two LEDs and two misc I/O lines that come out on the
// analog DB25.  We DO NOT count those ports here.
#define NUM_DIGPORTS     4

// Number of "ports" we have events on
// Event port indexes are:
//   0-3: Digital ports 0-3
//     4: Analog Event Bank 0
//     5: Analog Event Bank 1
//     6: Counter Rollovers
//     7: Counter Event Thresholds
#define NUM_EVTPORTS  8

// Index into the event structures:
// Analog banks 0 and 1
#define EVT_INDEX_ANALOG_0          4
#define EVT_INDEX_ANALOG_1          5
#define EVT_INDEX_COUNTER_ROLLOVER  6
#define EVT_INDEX_COUNTER_EVENT     7


// Which port is the analog port?
#define ANALOG_PORT 3

// Number of analog event banks
#define NUM_ANALOG_EVENT_BANKS   2

// Number of ports on which we allow the user to set the
// direction register
#define NUM_DIRECTIONPORTS  6

// TOTAL number of ports, including regular ports as
// well as special ports, and LEDs that are represented
// as ports.
#define NUM_ALLPORTS  8

// Number of Counters
#define NUM_COUNTERS       2

// Number of PWM Output Channels
#define NUM_PWM_OUTPUTS    2

// PWM Clock frequency, in HZ
#define PWM_CLOCK 2000000

// Minimum allowed PWM base period (clock cycles-1)
#define PWM_MINIMUM_BASE   49


// Modes for Set Port Direction firmware command
#define DIRECTION_SET   0
#define DIRECTION_OR    1
#define DIRECTION_AND   2

// ##########################################################
//   Internal API Configuration

// Default timeout for API functions, in milliseconds
#define TIMEOUT_DEFAULT  10000

// Number of seconds that queries will be allowed
// to linger in the queries_replies list.  
#define QUERIES_EXPIRE    30

// Default [maximum queue size] for the callback event thread queue
#define CALLBACK_DEFAULT    1000
// Minimum allowed [maximum queue size] for the callback queue
#define CALLBACK_MIN           1

// ##########################################################

// Data type for a node in the query/replies list.
typedef struct
{
	dbll_header header;
	int flags; // Should start out as 0.  See QRFLAG contstants below
	unsigned char reply[CMDLEN]; // Initially, this contains data that should match the reply we're expecting ("matchbytes" count)
	                             // Once a reply has been received, all the data that the ETH32 sent is stored here.
	int matchbytes; // How many bytes of the reply buffer have been pre-filled to indicate what we're expecting
	
} queryreplynode_t;

// Flags for the query/reply list nodes:
// Response received
#define QRFLAG_RECEIVED (1)
// Abandoned (requesting thread has timed out and is no longer interested in response
#define QRFLAG_ABANDONED (2)


// Data type for a node in the event queue
typedef struct
{
	dbll_header header;
	eth32_event event;
} evtqueuenode_t;

// Event Enabled structure - for each possible event, hold
// whether it is enabled and, if so, the user-defined ID given to it.
typedef struct
{
	int enabled; // nonzero means enabled
	int id; // user-defined ID
} evt_enab_t;

// Structure for holding/pointing to a descriptive string explaining
// an error code.
typedef struct
{
	int code;
	char *description;
} eth_errinfo_t;
extern const eth_errinfo_t eth_errinfo[];
extern const char error_unknown[];

typedef struct _eth32
{
	int closing;  /* normally 0, 1 to indicate we're in the middle of closing this device. */
	int quitflag; /* normally 0, 1 to indicate that the device should be closed. 
	                 Both the reading thread and the event thread periodicaly 
	                 check this flag.
	               */
	int refcount; /* Reference counter of sorts.  Indicates how many public API functions 
	               * are currently active.
	               */
	wth_event refcount_event; /* Protects access to closing flag and the refcount variable, and
	                           * is signalled when the refcount is decremented.
	                           */
	int readthread_done; /* Normally 0, negative error code if exited on error,
	                      * positive if exited on request of quitflag.
	                      */
	int eventthread_done; /* Normally 0, negative error code if exited on error,
	                      * positive if exited on request of quitflag.
	                      */
	wth_event doneflags_event; /* Synchronize access to above *_done flags.  When 
	                            * the thread exits, it will broadcast an event on this. */
	               
	eth32_socket socket; // Socket for communicating with the ETH32
	
	dbll_base *queries_replies; // List of queries we've sent and/or reply data we've received that 
	                            // hasn't yet been "consumed" by the application
	wth_event replies_event;  // Used to synchronize access to the replies list
	                          // and indicate when new data is added to replies

	unsigned int timeout; /* timeout for user requests such as input (in milliseconds) 
	                         0 means infinite timeout */
	wth_mutex timeout_mutex; /* Protect reads/writes of the timeout */

	// General event-related variables
	// Port events - only applies to "full blown" digital ports.
	// Are port events enabled and, if so, what event ID is assigned?
	evt_enab_t evt_ports[NUM_DIGPORTS];
	
	// Bit/channel/counter events.  Individual bit events on digital ports
	// and analog channel events on the analog port.
	// Stores whether each of these possible events is enabled and, if so,
	// what event ID has been assigned to it.
	evt_enab_t evt_bit[NUM_EVTPORTS][8];

	// Heartbeat "event"
	evt_enab_t evt_heartbeat;
	
	// The above event information does not need to be synchronized
	// with a mutex.  The queue and the event handler information is
	// protected/synchronized with this mutex/event:
	wth_event  evt_info_event; /* protect and synchronize access to the evt_queue and
	                            * evt_callback_queue and signal when new data is added.  And protect 
	                             * changes to the event_handler structure. */
	// Variables for queueing up and retrieving event firings
	dbll_base *evt_queue; // the user queue of un-consumed event firing information
	                      // Regardless of the queue size, this stub should always be
	                      // initialized and be a valid pointer.
	int evt_queue_size; // 0 for queue disabled, otherwise how many events we can queue
	int evt_queue_fullqueue; // what to do if the evt_queue gets full and we have a new event
	// Currently configured event handler information:
	eth32_handler event_handler;
	wth_mutex event_handler_change_mutex; // protect against simultaneous calls to set_event_handler
	                                      // Note that both reading and writing of event_handler
	                                      // should still be protected by evt_info_event where applicable.


	// Variables exclusively for the event callback thread - these are also
	// protected and synchronized by the evt_info_event above.
	int event_quitflag; // same situation as quitflag, but this is for the event thread 
	// Queue for passing event firing information to the event thread.
	// This is not the queue that the user can retrieve from.
	dbll_base *evt_callback_queue;
	
	
	// Keep track of a small sequence ID that we use to match up
	// queries sent and replies received from the device.
	unsigned char sequence; // next available sequence number
	wth_mutex sequence_mutex;
	
	
	/* Handles to threads.  These are created by the threads themselves
	 * right at the beginning of the function.  These are used
	 * to terminate the thread if that is necessary at Dll unload
	 * time
	 */
	wth_thread_handle eventthread_handle;
	wth_thread_handle readthread_handle;
} eth32_data;

#ifdef LINUX
void *eth32_readthread(void *arg);
void *eth32_eventthread(void *arg);
#endif

#ifdef WINDOWS
//DWORD WINAPI eth32_readthread(void *arg);
//DWORD WINAPI eth32_eventthread(void *arg);
unsigned __stdcall eth32_readthread(void *arg);
unsigned __stdcall eth32_eventthread(void *arg);
#endif

int eth32_check(eth32_data *data, int skipreadthread);
int eth32_refcount(eth32_data *data, int change);
void eth32_process_incoming(eth32_data *data, unsigned char *buf);
void eth32_process_event(eth32_data *data, unsigned char *buf);
void eth32_dispatch_event(eth32_data *handle, eth32_event *event);
int eth32_create_eventthread(eth32_data *handle);
void eth32_close_eventthread(eth32_data *handle, int force);
int eth32_set_event_handler_int(eth32_data *handle, eth32_handler *handler, int force);
int eth32_write_data(eth32_data *data, unsigned char *buf, int len, unsigned int *timeout);
int eth32_query_reply(eth32_data *data, unsigned char *qbuf, unsigned char *rbuf, unsigned int extracompare, unsigned int *timeout);
void eth32_free_data(eth32_data *handle);
int eth32_close_int(eth32_data *handle, int force);


// Headers that most modules need, but we can't include above because they
// themselves need the things that we declare:
#include "devtable.h"


#endif // eth32_internal_h
