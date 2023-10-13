/* This file is the Linux version of the eth32.h header */
#ifndef LINUX
#define LINUX
#endif


/* eth32.h
 * 
 * Provides constants and declarations for the 
 * ETH32 device API.
 * 
 * Copyright (C) 2010, Winford Engineering.
 * 
 * Winford Engineering
 * www.winford.com
 */
#ifndef eth32_h
#define eth32_h



#if defined WINDOWS || defined _WINDOWS || defined WIN32

#ifndef WINDOWS
#define WINDOWS
#endif
#include <windows.h>

#elif defined LINUX || defined _POSIX_SOURCE

#ifndef LINUX
#define LINUX
#endif
// A few Windows types in order to keep our
// data structures consistent
typedef void *HWND;
typedef unsigned int WPARAM;
typedef long LPARAM;
#ifndef WORD_TYPEDEF
#define WORD_TYPEDEF
typedef unsigned short WORD;
#endif

#else

#error Either WINDOWS or LINUX must be defined before including eth32.h

#endif


// Prohibit C++ name mangling on these prototypes
#ifdef __cplusplus
extern "C"
{
#endif



// Define any extra modifications for API function prototypes
// None at this time
#ifndef CALLEXTRA
#define CALLEXTRA
#endif


// Use __stdcall for publicly accessible functions on windows.
// This makes us compatible with VB, Windows API, etc.
#ifndef CALLCONVENTION
#ifdef WINDOWS
#define CALLCONVENTION __stdcall
#endif
#ifdef LINUX
#define CALLCONVENTION 
#endif
#endif


// Port the ETH32 listens on
#define ETH32_PORT    7152

// ETH32 Product ID (a portion of each serial number)
#define ETH32_PRODUCT_ID  105

// Common port direction settings
#define DIR_INPUT  0x00
#define DIR_OUTPUT 0xff

// Event type codes
#define EVENT_DIGITAL             0
#define EVENT_ANALOG              1
#define EVENT_COUNTER_ROLLOVER    2
#define EVENT_COUNTER_THRESHOLD   3
#define EVENT_HEARTBEAT           4

// Event Handler types
#define HANDLER_NONE            0
#define HANDLER_CALLBACK        1
#define HANDLER_MESSAGE         2

// Analog channel assignments
/* Single ended channels */
#define ANALOG_SE0              0x00 /* Channel 0 */
#define ANALOG_SE1              0x01
#define ANALOG_SE2              0x02
#define ANALOG_SE3              0x03
#define ANALOG_SE4              0x04
#define ANALOG_SE5              0x05
#define ANALOG_SE6              0x06
#define ANALOG_SE7              0x07
/* Differential channels */
#define ANALOG_DI00X10          0x08 /* Difference of channel 0 and 0 (for calibration), with 10X gain */
#define ANALOG_DI10X10          0x09 /* Difference of channel 1 and 0, with 10X gain */
#define ANALOG_DI00X200         0x0A
#define ANALOG_DI10X200         0x0B
#define ANALOG_DI22X10          0x0C
#define ANALOG_DI32X10          0x0D
#define ANALOG_DI22X200         0x0E
#define ANALOG_DI32X200         0x0F
#define ANALOG_DI01X1           0x10
#define ANALOG_DI11X1           0x11
#define ANALOG_DI21X1           0x12
#define ANALOG_DI31X1           0x13
#define ANALOG_DI41X1           0x14
#define ANALOG_DI51X1           0x15
#define ANALOG_DI61X1           0x16
#define ANALOG_DI71X1           0x17
#define ANALOG_DI02X1           0x18
#define ANALOG_DI12X1           0x19
#define ANALOG_DI22X1           0x1A
#define ANALOG_DI32X1           0x1B
#define ANALOG_DI42X1           0x1C
#define ANALOG_DI52X1           0x1D
#define ANALOG_122V             0x1E /* 1.22V */
#define ANALOG_0V               0x1F /* 0V */




// Counter States: Disabled, increment on falling edge, or rising edge
#define COUNTER_DISABLED        0
#define COUNTER_FALLING         1
#define COUNTER_RISING          2

// Modes for Pulse Bit:  Falling edge or Rising edge
#define PULSE_FALLING           0
#define PULSE_RISING            1

// ADC State:
#define ADC_DISABLED            0
#define ADC_ENABLED             1

// Analog voltage reference
#define REF_EXTERNAL    0   // External
#define REF_INTERNAL    1   // Internal AVCC (5V)
#define REF_256         3   // Internal 2.56V

// Default values when defining analog event thresholds
#define ANEVT_DEFAULT_LOW   0
#define ANEVT_DEFAULT_HIGH  1

// PWM Clock States
#define PWM_CLOCK_DISABLED  0
#define PWM_CLOCK_ENABLED   1

// PWM Channel States
#define PWM_CHANNEL_DISABLED    0
#define PWM_CHANNEL_NORMAL      1
#define PWM_CHANNEL_INVERTED    2


// Connection flags
#define CONN_FLAG_NONE            0x00
#define CONN_FLAG_RESPONSE        0x01
#define CONN_FLAG_DIGITAL_EVENT   0x02
#define CONN_FLAG_ANALOG_EVENT    0x04
#define CONN_FLAG_COUNTER_EVENT   0x08


// Settings for handling a full queue condition
//  DISCARD_NEW prevents the new events from being added to the queue, 
//              so the actual queue remains unchanged
//  DISCARD_OLD shifts an old event off the queue to make room for the new
#define QUEUE_DISCARD_NEW   0
#define QUEUE_DISCARD_OLD   1


// ETH32 data types


#ifndef ETH32_TYPEDEF
// Data type for handle to the ETH32 device
typedef void *eth32;
#endif

// Relevant information about an event's firing.  This structure
// is passed in to the user-defined callback when an event fires.
// Note that 4-byte types are used here for a reason - it helps to 
// avoid problems with byte-alignment differences between different 
// programming languages using this API.
typedef struct
{
	int id; // User-defined event ID
	int type; // Event type, as defined by the EVENT_DIGITAL, EVENT_* definitions
	int port; // Digital port, Analog event bank, or Counter number
	int bit;  // Bit or Channel, or -1 for a port event
	int prev_value; // Value of the bit / port / channel before
	                // the event fired
	int value;      // New value of the bit / port / channel
	                // or the number of times the counter has fired an event or rolled
	int direction; // -1 for falling, 1 for rising
} eth32_event;

// Format for callback function used with events
typedef void (CALLCONVENTION *eth32_eventfn)(eth32 handle, eth32_event *event, void *extra);

// Event handler information
typedef struct
{
	int type; /* which method to use for event notification */
	          /* HANDLER_NONE     - none; disabled.
	           * HANDLER_CALLBACK - callback function
	           * HANDLER_MESSAGE  - Windows message notification: 
	           *     A windows message with the given message ID is sent 
	           *     to the specified window
	           *     whenever a new event fires.  This is intended to be 
	           *     used with the event queue such that when the windows
	           *     message is received, you attempt to dequeue any events
	           *     that are in the message queue.
	           */
	/* The following are only used with type HANDLER_CALLBACK */
	int maxqueue; // Maximum number of events that can be queued waiting for 
	               // the callback to finish
	int fullqueue; // What to do if queue ever gets full.  Specify one of the
	               // QUEUE_... constants
	eth32_eventfn eventfn; // Address of user-defined callback function.
	void *extra;  // Extra user-defined value to be passed to the callback
	              // whenever it is called.

	/* The following are only used with type HANDLER_MESSAGE: */
	HWND window; // Window handle to send messages to.
	unsigned int msgid; // Windows message to be sent to window.
	WPARAM wparam; // wparam to be included with any messages that are sent
	LPARAM lparam; // lparam to be included with any messages that are sent
	
} eth32_handler;





// API Functions
eth32 CALLCONVENTION CALLEXTRA eth32_open(char *address, WORD port, unsigned int timeout, int *result);
int CALLCONVENTION CALLEXTRA eth32_set_timeout(eth32 handle, unsigned int timeout);
int CALLCONVENTION CALLEXTRA eth32_get_timeout(eth32 handle, unsigned int *timeout);
int CALLCONVENTION CALLEXTRA eth32_verify_connection(eth32 handle);
int CALLCONVENTION CALLEXTRA eth32_output_byte(eth32 handle, int port, int value);
int CALLCONVENTION CALLEXTRA eth32_output_bit(eth32 handle, int port, int bit, int value);
int CALLCONVENTION CALLEXTRA eth32_pulse_bit(eth32 handle, int port, int bit, int edge, int count);
int CALLCONVENTION CALLEXTRA eth32_set_led(eth32 handle, int led, int value);
int CALLCONVENTION CALLEXTRA eth32_input_byte(eth32 handle, int port, int *value);
int CALLCONVENTION CALLEXTRA eth32_input_successive(eth32 handle, int port, int max, int *value, int *status);
int CALLCONVENTION CALLEXTRA eth32_input_bit(eth32 handle, int port, int bit, int *value);
int CALLCONVENTION CALLEXTRA eth32_readback(eth32 handle, int port, int *value);
int CALLCONVENTION CALLEXTRA eth32_get_led(eth32 handle, int led, int *value);
int CALLCONVENTION CALLEXTRA eth32_set_direction(eth32 handle, int port, int direction);
int CALLCONVENTION CALLEXTRA eth32_get_direction(eth32 handle, int port, int *direction);
int CALLCONVENTION CALLEXTRA eth32_set_direction_bit(eth32 handle, int port, int bit, int direction);
int CALLCONVENTION CALLEXTRA eth32_get_direction_bit(eth32 handle, int port, int bit, int *direction);
int CALLCONVENTION CALLEXTRA eth32_set_analog_state(eth32 handle, int state);
int CALLCONVENTION CALLEXTRA eth32_get_analog_state(eth32 handle, int *state);
int CALLCONVENTION CALLEXTRA eth32_set_analog_reference(eth32 handle, int reference);
int CALLCONVENTION CALLEXTRA eth32_get_analog_reference(eth32 handle, int *reference);
int CALLCONVENTION CALLEXTRA eth32_input_analog(eth32 handle, int channel, int *value);
int CALLCONVENTION CALLEXTRA eth32_set_analog_eventdef(eth32 handle, int bank, int channel, int lomark, int himark, int defaultval);
int CALLCONVENTION CALLEXTRA eth32_get_analog_eventdef(eth32 handle, int bank, int channel, int *lomark, int *himark);
int CALLCONVENTION CALLEXTRA eth32_set_analog_assignment(eth32 handle, int channel, int source);
int CALLCONVENTION CALLEXTRA eth32_get_analog_assignment(eth32 handle, int channel, int *source);
int CALLCONVENTION CALLEXTRA eth32_reset(eth32 handle);
int CALLCONVENTION CALLEXTRA eth32_get_serialnum(eth32 handle, int *batch, int *unit);
int CALLCONVENTION CALLEXTRA eth32_get_serialnum_string(eth32 handle, char *serial, int bufsize);
int CALLCONVENTION CALLEXTRA eth32_get_product_id(eth32 handle, int *prodid);
int CALLCONVENTION CALLEXTRA eth32_get_firmware_release(eth32 handle, int *major, int *minor);
int CALLCONVENTION CALLEXTRA eth32_connection_flags(eth32 handle, int reset, int *flags);

int CALLCONVENTION CALLEXTRA eth32_set_event_queue_config(eth32 handle, int maxsize, int fullqueue);
int CALLCONVENTION CALLEXTRA eth32_get_event_queue_status(eth32 handle, int *maxsize, int *fullqueue, int *cursize);
int CALLCONVENTION CALLEXTRA eth32_dequeue_event(eth32 handle, eth32_event *event, int timeout);
int CALLCONVENTION CALLEXTRA eth32_empty_event_queue(eth32 handle);
int CALLCONVENTION CALLEXTRA eth32_enable_event(eth32 handle, int type, int port, int bit, int id);
int CALLCONVENTION CALLEXTRA eth32_disable_event(eth32 handle, int type, int port, int bit);
int CALLCONVENTION CALLEXTRA eth32_set_event_handler(eth32 handle, eth32_handler *handler);
int CALLCONVENTION CALLEXTRA eth32_get_event_handler(eth32 handle, eth32_handler *handler);

int CALLCONVENTION CALLEXTRA eth32_set_counter_state(eth32 handle, int counter, int state);
int CALLCONVENTION CALLEXTRA eth32_get_counter_state(eth32 handle, int counter, int *state);
int CALLCONVENTION CALLEXTRA eth32_set_counter_value(eth32 handle, int counter, int value);
int CALLCONVENTION CALLEXTRA eth32_get_counter_value(eth32 handle, int counter, int *value);
int CALLCONVENTION CALLEXTRA eth32_set_counter_rollover(eth32 handle, int counter, int rollover);
int CALLCONVENTION CALLEXTRA eth32_get_counter_rollover(eth32 handle, int counter, int *rollover);
int CALLCONVENTION CALLEXTRA eth32_set_counter_threshold(eth32 handle, int counter, int threshold);
int CALLCONVENTION CALLEXTRA eth32_get_counter_threshold(eth32 handle, int counter, int *threshold);

int CALLCONVENTION CALLEXTRA eth32_set_pwm_clock_state(eth32 handle, int state);
int CALLCONVENTION CALLEXTRA eth32_get_pwm_clock_state(eth32 handle, int *state);
int CALLCONVENTION CALLEXTRA eth32_set_pwm_base_period(eth32 handle, int period);
int CALLCONVENTION CALLEXTRA eth32_get_pwm_base_period(eth32 handle, int *period);
int CALLCONVENTION CALLEXTRA eth32_set_pwm_channel(eth32 handle, int channel, int state);
int CALLCONVENTION CALLEXTRA eth32_get_pwm_channel(eth32 handle, int channel, int *state);
int CALLCONVENTION CALLEXTRA eth32_set_pwm_duty_period(eth32 handle, int channel, int period);
int CALLCONVENTION CALLEXTRA eth32_get_pwm_duty_period(eth32 handle, int channel, int *period);

int CALLCONVENTION CALLEXTRA eth32_set_pwm_parameters(eth32 handle, int channel, int state, float freq, float duty);
int CALLCONVENTION CALLEXTRA eth32_get_pwm_parameters(eth32 handle, int channel, int *state, float *freq, float *duty);

int CALLCONVENTION CALLEXTRA eth32_get_eeprom(eth32 handle, int address, int length, void *buffer);
int CALLCONVENTION CALLEXTRA eth32_set_eeprom(eth32 handle, int address, int length, void *buffer);

const char * CALLCONVENTION CALLEXTRA eth32_error_string(int errorcode);

int CALLCONVENTION CALLEXTRA eth32_close(eth32 handle);


// Functions and definitions used for configuring and discovering ETH32 devices.

// Port the ETH32 devices are listening on (UDP)
#define ETH32_CONFIG_PORT 7151

// Plugin types
#define ETH32CFG_PLUG_NONE      0
#define ETH32CFG_PLUG_SYS       1
#define ETH32CFG_PLUG_PCAP      2

// Interface name types that can be retrieved from the eth32cfg_plugin_interface_name function
#define ETH32CFG_IFACENAME_STANDARD     0
#define ETH32CFG_IFACENAME_FRIENDLY     1
#define ETH32CFG_IFACENAME_DESCRIPTION  2

// Network interface types
#define ETH32CFG_IFTYPE_NONE        0
#define ETH32CFG_IFTYPE_OTHER       1
#define ETH32CFG_IFTYPE_ETHERNET    6
#define ETH32CFG_IFTYPE_TOKENRING   9
#define ETH32CFG_IFTYPE_FDDI       15
#define ETH32CFG_IFTYPE_PPP        23
#define ETH32CFG_IFTYPE_LOOPBACK   24
#define ETH32CFG_IFTYPE_SLIP       28

// Flags for eth32cfg_discover_ip function
#define ETH32CFG_FILTER_NONE        0
#define ETH32CFG_FILTER_MAC         1
#define ETH32CFG_FILTER_SERIAL      2

typedef void *eth32cfg; // Data type for handle to ETH32 config data information
typedef void *eth32cfgiflist; // Data type for handle to network interface list

typedef struct // IP address stored in binary form, in network order (first octet stored at index 0)
{ 
	unsigned char byte[4];
} eth32cfg_ip_t;

// Some languages always align their structures on 4-byte boundaries,
// so this structure includes that.
typedef struct
{
	unsigned char product_id;
	unsigned char firmware_major;
	unsigned char firmware_minor;
	unsigned char config_enable;
	unsigned char mac[8]; // 8 to make alignment right, only need 6 though
	unsigned short serialnum_batch;
	unsigned short serialnum_unit; 
	eth32cfg_ip_t config_ip;
	eth32cfg_ip_t config_gateway;
	eth32cfg_ip_t config_netmask;
	eth32cfg_ip_t active_ip;
	eth32cfg_ip_t active_gateway;
	eth32cfg_ip_t active_netmask;
	unsigned char dhcp;

} eth32cfg_data_t;

int CALLCONVENTION CALLEXTRA eth32cfg_ip_to_string(const eth32cfg_ip_t *ipbinary, char *ipstring); // ipstring buffer MUST be at least 16 bytes long
int CALLCONVENTION CALLEXTRA eth32cfg_string_to_ip(const char *ipstring, eth32cfg_ip_t *ipbinary);

eth32cfg CALLCONVENTION CALLEXTRA eth32cfg_query(eth32cfg_ip_t *bcastaddr, int *number, int *result);
eth32cfg CALLCONVENTION CALLEXTRA eth32cfg_discover_ip(eth32cfg_ip_t *bcastaddr, unsigned int flags, unsigned char *mac, unsigned char product_id, unsigned short serialnum_batch, unsigned short serialnum_unit, int *number, int *result);
int CALLCONVENTION CALLEXTRA eth32cfg_get_config(eth32cfg handle, int index, eth32cfg_data_t *dataptr);
int CALLCONVENTION CALLEXTRA eth32cfg_set_config(eth32cfg_ip_t *bcastaddr, eth32cfg_data_t *dataptr);
int CALLCONVENTION CALLEXTRA eth32cfg_serialnum_string(unsigned char product_id, unsigned short batch, unsigned short unit, char *serialstring, int bufsize);
void CALLCONVENTION CALLEXTRA eth32cfg_free(eth32cfg handle);


int CALLCONVENTION CALLEXTRA eth32cfg_plugin_load(int option);
eth32cfgiflist CALLCONVENTION CALLEXTRA eth32cfg_plugin_interface_list(int *numd, int *result);
int CALLCONVENTION CALLEXTRA eth32cfg_plugin_interface_address(eth32cfgiflist handle, int index, eth32cfg_ip_t *ip, eth32cfg_ip_t *netmask);
int CALLCONVENTION CALLEXTRA eth32cfg_plugin_interface_type(eth32cfgiflist handle, int index, int *type);
int CALLCONVENTION CALLEXTRA eth32cfg_plugin_interface_name(eth32cfgiflist handle, int index, int nametype, char *name, int *length);
int CALLCONVENTION CALLEXTRA eth32cfg_plugin_choose_interface(eth32cfgiflist handle, int index);
void CALLCONVENTION CALLEXTRA eth32cfg_plugin_interface_list_free(eth32cfgiflist handle);




// ###########################################################
//      Error Codes
// ###########################################################

#define ETH_SUCCESS                   0   // No error
#define ETH_GENERAL_ERROR            -1   // Unknown or other error
#define ETH_CLOSING                  -2   // Function aborted since the device is being closed
#define ETH_NETWORK_ERROR            -10  // unable to open, read, or write to the network socket
#define ETH_THREAD_ERROR             -11  // General error ocurred in the threads library used by this API.
#define ETH_NOT_SUPPORTED            -12  // returned if functionality is not supported by platform or device
#define ETH_PIPE_ERROR               -13  // Internal API error
#define ETH_RTHREAD_ERROR            -14  // Internal API error
#define ETH_ETHREAD_ERROR            -15  // Internal API error
#define ETH_MALLOC_ERROR             -16  // Problem involving allocating memory
#define ETH_WINDOWS_ERROR            -17  // Internal API error - specific to Windows platform
#define ETH_WINSOCK_ERROR            -18  // Internal API error - specific to Windows sockets
#define ETH_NETWORK_INTR             -19  // Network read/write operation was interrupted.
#define ETH_WRONG_MODE               -20  // Something is not configured correctly in order to allow this functionality.
#define ETH_BCAST_OPT                -21  // Error setting SO_BROADCAST option on socket
#define ETH_REUSE_OPT                -22  // Error setting SO_REUSEADDR option on socket
#define ETH_CFG_NOACK                -23  // Really a warning - no acknowledgement after configuring IP settings of device
#define ETH_CFG_REJECT               -24  // The device refused to set its IP configuration settings
#define ETH_LOADLIB                  -25  // Error loading an external DLL library
#define ETH_PLUGIN                   -26  // General error with plugin being used (for device discovery, sniffing, etc)
#define ETH_BUFSIZE                  -27  // A buffer provided is either invalid size or too small
#define ETH_INVALID_HANDLE          -101  // Invalid device handle was passed in
#define ETH_INVALID_PORT            -104  // Port specified is invalid for the device model
#define ETH_INVALID_BIT             -109  // Value passed identifying bit is out of range
#define ETH_INVALID_CHANNEL         -111  // Invalid channel number specified
#define ETH_INVALID_POINTER         -112  // Invalid pointer given as a parameter to an API function
#define ETH_INVALID_OTHER           -113  // Some parameter passed to an API function was invalid or out of range
#define ETH_INVALID_VALUE           -114  // Value out of possible range for that I/O port
#define ETH_INVALID_IP              -115  // Invalid IP address was provided
#define ETH_INVALID_NETMASK         -116  // Invalid netmask was provided
#define ETH_INVALID_INDEX           -117  // Invalid index value
#define ETH_TIMEOUT                 -201  // Timeout ocurred. Most likely communication has been lost w/ device	




#ifdef __cplusplus
} // end of extern "C"
#endif


#endif //eth32_h
