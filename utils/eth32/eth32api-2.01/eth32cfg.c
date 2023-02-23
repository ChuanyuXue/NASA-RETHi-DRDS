/* Winford Engineering ETH32 API
 * Copyright 2010 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */
// Function code for the configuration/discovery functionality of the API

#include "eth32_internal.h"
#include "eth32.h"
#include "eth32cfg.h"

#ifdef WINDOWS
#include "iphelper.h"
#include "eth32cfg_pcap.h"

#else
// Linux
#include <unistd.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <resolv.h>
#include <netinet/in.h>
#include <arpa/inet.h>

typedef int SOCKET;
#define closesocket(s) (close(s))

#endif

#include <malloc.h>

// Number of times to send out query packet when detecting devices
#define QUERYCOUNT   4
// How long, in milliseconds, to delay between times we send
#define QUERYDELAY   200



// Define a structure and global variable for storing library-wide settings
typedef struct 
{
	int plugin_type;
	char *pcap_ifacename; // the chosen interface, if pcap is being used.
	                    // this is a malloc-ed string at the time a interface is chosen.
#ifdef WINDOWS
	int wsock_init;
#endif
} eth32cfg_global_t;
eth32cfg_global_t eth32cfg_global={0};



// We need 25 bytes for max reply or send packet
typedef unsigned char eth32cfgbuf_t[25];


#define CMD_QUERY        1
#define CMD_QUERY_REPLY  2
#define CMD_SET_CONFIG   3
#define CMD_CONFIRM      4
#define CMD_IPCONF_QUERY 5
#define CMD_IPCONF_REPLY 6

// We can't just do a structure for all of our fields
// because of alignment to 4-byte boundaries.
// Locations of data within the buffer for:
//  Query Reply packet
#define QR_CMD      0
#define QR_DEVID    1
#define QR_MAC      2
#define QR_SER      8
#define QR_IP       12
#define QR_GATE     16
#define QR_NMB      20
#define QR_NMM      21
#define QR_FIRMJ    22
#define QR_FIRMN    23
#define QR_CFGEN    24
// Total # of bytes in the Query Reply command packet
#define QR_LEN      25

// IP configuration Query packet
#define IQ_CMD      0
#define IQ_MAGIC    1
#define IQ_FILTER   5
#define IQ_MAC      6
#define IQ_PROD     12
#define IQ_SER      13
// Total # of bytes in IP configuration Query packet
#define IQ_LEN      17

//  IP Configuration Response packet
#define IR_CMD      0
#define IR_DHCP     1
#define IR_MAC      2
#define IR_PROD     8
#define IR_SER      9
#define IR_IP       13
#define IR_GATE     17
#define IR_NMB      21
#define IR_NMM      22
// Total # of bytes in the IP Configuration Response
#define IR_LEN      23

// Set Config packet (what we send)
#define SC_CMD      0
#define SC_MAC      1
#define SC_SER      7
#define SC_IP       11
#define SC_GATE     15
#define SC_NMB      19
#define SC_NMM      20
#define SC_DHCP     21
#define SC_CKSUM    22
// Total # of bytes in the Set Config command packet
#define SC_LEN      24

// Confirm packet we receive after sending Set Config
#define CF_CMD      0
#define CF_STATUS   1
#define CF_LEN      2



// Internal function -- need not be exported
unsigned short checksum(unsigned short *addr, unsigned int count)
{
	/* Compute Internet Checksum for "count" bytes
	*         beginning at location "addr".  Note that 
	*         this function doesn't complement (~) the final result, so if you're generating 
	*         a checksum, you'll need to do that yourself on the returned result.
	*/
	unsigned int sum = 0;

	while( count > 1 )
	{
		/*  This is the inner loop */
		sum += *addr++;
		count -= 2;
	}
	
	   /*  Add left-over byte, if any */
	if( count > 0 )
	       sum += * (unsigned char *) addr;
	
	/*  Fold 32-bit sum to 16 bits */
	while (sum>>16)
	   sum = (sum & 0xffff) + (sum >> 16);
	
	return(sum);
}

int CALLCONVENTION CALLEXTRA eth32cfg_netmask_breakup(const eth32cfg_ip_t *netmask, unsigned char *bytes, unsigned char *mask)
{
	/* Takes a netmask and breaks it up into number 
	 * of whole bytes of 1-bits and number of left-over
	 * 1-bits, as required by the device configuration.
	 * Returns zero on success or error code if the netmask
	 * is invalid (such as having noncontiguous 1-bits)
	 */
	// This is not a documented function, but it does come in handy for validating a netmask in our configuration
	// utility, so it is callable.
	unsigned char i;
	unsigned char temp;
	
	
	for(i=0; i<4; i++)
		if(netmask->byte[i]!=0xff)
			break;
	*bytes=i;
	
	/* If not all 4 bytes were 1-bits, then we have a leftover.
	 * Grab it, then do a little validation.
	 */
	if(i<4)
	{
		*mask=netmask->byte[i];
	
		/* Our leftover should have contiguous 1-bits at MSB positions
		 * followed by at least one 0-bit in LSB positions
		 */
		temp=netmask->byte[i];
		while(temp & 0x80) // Go while we have MSB set
		{
			temp<<=1; /* shift left (get rid of MSB) */
		}
	
		/* If we are left with a nonzero temp, there were noncontiguous 1-bits */
		if(temp)
			return(ETH_INVALID_NETMASK);
	
		/* Go through any remaining netmask octets (perhaps none) 
		 * and make sure they're all 0.
		 */
		for(i++; i<4; i++)
			if(netmask->byte[i])
				return(ETH_INVALID_NETMASK);
	}
	else
	{
		// We will allow a 255.255.255.255 netmask in case somebody
		// wants to put EVERYTHING through the router
		*mask=0;
	}
	
	// If here, then all was successful.
	return(0);
}



static int bcastsocket(SOCKET *sock)
{
	// Creates a broadcast socket and stores file descriptor
	// into sock.
	// Returns 0 on success or nonzero on error.
	// The socket will need to be closed by the caller IF no
	// error is returned.
#ifdef WINDOWS
	WSADATA wsaData;
#endif
	SOCKET s;
	int ecode;
	int on=1;

#ifdef WINDOWS
	/* Initialize windows sockets */
	if( eth32cfg_global.wsock_init == 0 )
	{
		if( WSAStartup(MAKEWORD(1, 1), &wsaData) != 0 )
		{
			ecode=ETH_WINSOCK_ERROR;
			goto err1;
		}
		eth32cfg_global.wsock_init=1;
	}
#endif

	s=socket(PF_INET, SOCK_DGRAM, 0);

#ifdef WINDOWS
	if(s == INVALID_SOCKET)
#else	
	if(s<0)
#endif
	{
		ecode=ETH_WINSOCK_ERROR;
		goto err1;
	}
	
	
	if ( setsockopt(s, SOL_SOCKET, SO_BROADCAST, (const char *)&on, sizeof(on)) != 0 )
	{
		ecode=ETH_BCAST_OPT;
		goto err2;
	}
		
	if ( setsockopt(s, SOL_SOCKET, SO_REUSEADDR, (const char *)&on, sizeof(on)) != 0 )
	{
		ecode=ETH_REUSE_OPT;
		goto err2;
	}

	*sock=s;
	return(0);
	
	err2:
	closesocket(s);
	err1:
	return(ecode);
}


int CALLCONVENTION CALLEXTRA eth32cfg_ip_to_string(const eth32cfg_ip_t *ipbinary, char *ipstring)
{
	// Converts binary ip data to a string dotted-decimal representation.
	// The string will be written into the ipstring buffer, which the caller must 
	// have already allocated to be at least 16 bytes long.
	// Returns 0 on success or error code on failure.
	
	if( !ipbinary || !ipstring )
		return(ETH_INVALID_POINTER);

#ifdef _MSVC
	_snprintf_s(ipstring, 16, 15, "%d.%d.%d.%d", ipbinary->byte[0], ipbinary->byte[1], ipbinary->byte[2], ipbinary->byte[3]);
#else
	snprintf(ipstring, 16, "%d.%d.%d.%d", ipbinary->byte[0], ipbinary->byte[1], ipbinary->byte[2], ipbinary->byte[3]);
#endif
	return(0);
}

int CALLCONVENTION CALLEXTRA eth32cfg_string_to_ip(const char *ipstring, eth32cfg_ip_t *ipbinary)
{
	// Converts the dotted-decimal string representation of an IP address into binary data, which will 
	// be stored into structure pointed to by ipbinary
	// Returns 0 on success or error code on failure.
	
	eth32cfg_ip_t result;
	const char *start;
	char *loc;
	int i;
	int len;
	int tempint;
	int numdots=0;
	char temp[4];
	
	if( !ipbinary || !ipstring )
		return(ETH_INVALID_POINTER);
	
	
	len=(int)strlen(ipstring);
	for(i=0; i<len; i++)
	{
		// Limit all characters to digits and dots
		if( !(ipstring[i]>='0' && ipstring[i]<='9') && ipstring[i]!='.' )
			return(ETH_INVALID_IP);
		if(ipstring[i]=='.')
			numdots++;
	}
	if(numdots!=3)
		return(ETH_INVALID_IP);
			
	start=ipstring;
	for(i=0; i<4; i++)
	{
		// Find first dot from starting point
		if(i<3)
		{
			loc=strchr(start, '.'); // returns a pointer, or NULL if not found
			if(loc==0 || loc==start || (loc-start)>3)
				return(ETH_INVALID_IP);
			
			memcpy(temp, start, loc-start);
			temp[loc-start]=0; // null terminate
			tempint=atoi(start);
			if(tempint>255)
				return(ETH_INVALID_IP);
			result.byte[i]=(unsigned char)tempint;
			start=loc+1;
		}
		else
		{
			// We're on the last octet
			if(*start==0 || (len-(start-ipstring))>3)
				return(ETH_INVALID_IP);
			tempint=atoi(start);
			if(tempint>255)
				return(ETH_INVALID_IP);
			result.byte[i]=(unsigned char)tempint;
		}
	}

	// Once we're sure we have a valid IP, copy the result in.
	// We're trying to avoid copying in half an IP and then bailing out.
	for(i=0; i<4; i++)
		ipbinary->byte[i]=result.byte[i];
		
	return(0);
}

// Callback function type declarations for use with eth32cfg_cmd_response
// For receive callback:
//   If the callback returns 0, processing continues as normal
//   If it returns negative, processing stops and the returned value is returned from eth32cfg_cmd_response as an error code
//   If it returns positive, processing stops and eth32cfg_cmd_response returns 0, indicating success
typedef int (*cmd_response_recv_cb_t)(void *data, unsigned char *recvbuf, int recvlen);
typedef void (*cmd_response_send_cb_t)(void *data, SOCKET s, struct sockaddr_in *sendaddr);

int eth32cfg_cmd_response(eth32cfg_ip_t *bcastaddr, unsigned int sendcount, unsigned int responsewait, cmd_response_send_cb_t send_callback, const unsigned char *sendbuf, int sendlength, cmd_response_recv_cb_t recv_callback, void *data)
{
	// Internal function that does a lot of the work of sending out a command and listening for responses.
	// Sends out query to the broadcast address multiple times.  This function
	// also waits for responses for a predetermined time and
	// calls the provided callback function for each response that is received.
	// It is the responsibility of the callback function to inspect the response and see whether 
	// it is a legitimate response or whether it should be ignored.  The data parameter will be passed
	// on to the callback function at each call.
	//  bcastaddr - The address to broadcast to or may be left NULL to use 255.255.255.255.
	//  sendcount - how many times the buffer should be sent onto the network
	//  responsewait - how many milliseconds we should wait in between sending to receive responses
	//  send_callback - function to call to send each query -- if this is non-NULL, then it will be called
	//                  for each iteration, and NOTE THAT sendbuf and sendlength in this case will be ignored.
	//  sendbuf - the data to send onto the network (if send_callback is null)
	//  sendlength - how much data to send (if send_callback is null)
	//  recv_callback - function to call with each response
	//  data - parameter to pass to both callback functions
	// Return value:
	//  0 = success
	//  otherwise, error code

	SOCKET s;
	struct sockaddr_in sendaddr;
	struct sockaddr_in recvaddr;
	int ret, cbret;
	unsigned int i;
	int ecode;
	fd_set rdset;
	struct timeval tmout;
	unsigned char buf[2048];

#ifdef WINDOWS
	int recvaddrsize;
#else
	socklen_t recvaddrsize;
#endif
		
#ifdef WINDOWS
	DWORD starttime;	
	pcap_t *adhandle;

	switch(eth32cfg_global.plugin_type)
	{
		case ETH32CFG_PLUG_PCAP:
		if(eth32cfg_global.pcap_ifacename==0) // No pointer is set to the interface name.
			return(ETH_PLUGIN);
		if( (ret=eth32cfg_pcap_open(&adhandle, eth32cfg_global.pcap_ifacename)) )
			return(ret);
			break;	
	}
#endif
	
	

	if( (ecode=bcastsocket(&s)) )
		goto err1;

	memset(&sendaddr, 0, sizeof(sendaddr));
	memset(&recvaddr, 0, sizeof(recvaddr));
	sendaddr.sin_family = PF_INET;
	sendaddr.sin_port = htons(ETH32_CONFIG_PORT);
	
	if(bcastaddr)
	{
		char tempaddr[20]={0};
		eth32cfg_ip_to_string(bcastaddr, tempaddr);
		sendaddr.sin_addr.s_addr = inet_addr(tempaddr);
	}
	else
		sendaddr.sin_addr.s_addr = INADDR_BROADCAST;
	

	ecode=0; // Default to success
	
	// Send out query and wait for results several times just in case
	// there is corruption, collision, etc, that messes up the
	// first try.
	for(i=0; i<sendcount; i++)
	{
		if(send_callback)
			send_callback(data, s, &sendaddr);
		else
			sendto(s, (const char *)sendbuf, sendlength, 0, (struct sockaddr*)&sendaddr, sizeof(sendaddr));
		// The query has been sent out.  Now we need to listen for responses.
		// The way we do that will depend on what plugin is currently selected
		
		switch(eth32cfg_global.plugin_type)
		{
			case ETH32CFG_PLUG_NONE: // PLUG_SYS is only used for detecting interfaces, so we do this part the same
			case ETH32CFG_PLUG_SYS:  // as no plugin.
				/* Use an overall timeout regardless of number of replies*/
				/* Note that if we time out, a response can still be accepted during the 
				 * receiving stage of the next loop iteration */
				tmout.tv_sec=0;
				tmout.tv_usec=responsewait * 1000;
				FD_ZERO(&rdset);
				FD_SET(s, &rdset);

				// NOTE: Windows ignores the first parameter and passing in s+1 causes a warning on x64 platform,
				// so just pass in zero on Windows platforms.
#ifdef WINDOWS			
				while(select(0, &rdset, NULL, NULL, &tmout)>0)
#else
				while(select(s+1, &rdset, NULL, NULL, &tmout)>0)
#endif
				{
					recvaddrsize=sizeof(recvaddr);
					ret=recvfrom(s, (char *)buf, sizeof(buf), 0, (struct sockaddr*)&recvaddr, &recvaddrsize);
					
					cbret=recv_callback(data, buf, ret);
					// If the callback returns nonzero, we need to exit.
					if(cbret)
					{
						if(cbret<0)  // If negative, exit with error, otherwise with success
							ecode=cbret;
						else
							ecode=0;
						goto err2;
					}
						
		
					FD_ZERO(&rdset);
					FD_SET(s, &rdset);
				}
			
				break;
#ifdef WINDOWS
			case ETH32CFG_PLUG_PCAP:
				starttime=GetTickCount();
		
				while(GetTickCount() < (starttime+responsewait))
				{
					if( (ret=eth32cfg_pcap_recv(adhandle, buf, sizeof(buf))) <= 0)
						continue; // timeout or error (of this individual read attempt)
					else
					{
						cbret=recv_callback(data, buf, ret);
						// If the callback returns nonzero, we need to exit.
						if(cbret)
						{
							if(cbret<0)  // If negative, exit with error, otherwise with success
								ecode=cbret;
							else
								ecode=0;
							goto err2;
						}
					}
				}
			
			break;
#endif
		}
	}


err2: // This code is also executed on a normal exit
#ifdef WINDOWS
	switch(eth32cfg_global.plugin_type)
	{
		case ETH32CFG_PLUG_PCAP:
			eth32cfg_pcap_close(adhandle);
			break;	
	}
#endif

	
	
	closesocket(s);
	
	return(ecode);

err1:
#ifdef WINDOWS
	switch(eth32cfg_global.plugin_type)
	{
		case ETH32CFG_PLUG_PCAP:
			eth32cfg_pcap_close(adhandle);
			break;
	}
#endif

	return(ecode);
	
	
	
}

typedef struct
{
	unsigned char query_response;    // These two flags can be nonzero to indicate we have filled in response fields
	unsigned char ipconfig_response;
	eth32cfg_data_t data;
} query_reply_data_t;

typedef struct
{
	int count;
	int filter;  // this, along with the mac and serialnum info below, indicate to the receiving code
	             // how we should filter the responses.  We decided to filter in the API as well in case
	             // we pick up other responses "floating around" the network that are in response to someone else's request.
	unsigned char mac[6];
	unsigned short serialnum_batch;
	unsigned short serialnum_unit;
	query_reply_data_t replies[1];
} query_replies_t;


int query_replies_find(query_replies_t **query_results_ptr, unsigned char *mac)
{
	// This function takes a pointer to a pointer to the query replies data, 
	// and searches it to see if it already has a reply from the given MAC address.
	// If it is not found, it adds it and zeroes out the memory for that.
	// In this case, the pointer being pointed to may be changed due to the reallocation of memory.
	// Regardless, it returns an index into the replies array that entry.
	// If there is an error, a negative error code is returned.
	int i;
	query_replies_t *newmem;
	
	// Check for this MAC already existing
	for(i=0; i<(*query_results_ptr)->count; i++)
	{
		if(memcmp((*query_results_ptr)->replies[i].data.mac, mac, 6)==0)
			return(i); // Found it
	}
	
	// If it was not found, add it
	(*query_results_ptr)->count++;
	// Reallocate memory -- note that sizeof(query_replies_t) already includes space for one result,
	// so add in space for any replies over 1.
	newmem=realloc(*query_results_ptr, sizeof(query_replies_t)+sizeof(query_reply_data_t)*((*query_results_ptr)->count - 1));
	
	if(newmem) // success
		*query_results_ptr=newmem;
	else
		return(ETH_MALLOC_ERROR); // Return error and don't alter the original pointer -- it's still valid
	
	// Clear the memory to start out:
	memset(&((*query_results_ptr)->replies[(*query_results_ptr)->count-1]), 0, sizeof(query_reply_data_t));
	
	return((*query_results_ptr)->count-1);
}

void query_send_callback(void *data, SOCKET s, struct sockaddr_in *sendaddr_ptr)
{
	// This callback is called several times during a call to eth32cfg_query
	// in order to send out the queries onto the network

	unsigned char buf1[]={CMD_QUERY, 0x44, 0xEE, 0x44, 0x11};
	unsigned char buf2[]={CMD_IPCONF_QUERY, 0x44, 0xEE, 0x44, 0x11, 0x00, // filter:none
	                      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // MAC bytes
	                      0x00, 0x00, 0x00, 0x00 // Serial number bytes
	                     };
	
	sendto(s, (const char *)buf1, sizeof(buf1), 0, (struct sockaddr*)sendaddr_ptr, sizeof(*sendaddr_ptr));
	sendto(s, (const char *)buf2, sizeof(buf2), 0, (struct sockaddr*)sendaddr_ptr, sizeof(*sendaddr_ptr));
}

int query_recv_callback(void *data, unsigned char *recvbuf, int recvlen)
{
	// This callback is called to process each response we receive when doing a query or discovery command
	// See comment above by callback type definition for explanation of return values.
	int i;
	unsigned char temp;
	eth32cfg_data_t recvdata={0};
	query_replies_t **query_results_ptr = data;
	
	
	// Check for command of 2 
	if(recvbuf[0]==CMD_QUERY_REPLY)
	{
		if(recvlen<QR_LEN)
			return(0);
			
		// Convert the raw buffer into a more usable structure
		recvdata.product_id=recvbuf[QR_DEVID];
		memcpy(recvdata.mac, &(recvbuf[QR_MAC]), 6);
		recvdata.serialnum_batch = (recvbuf[QR_SER]<<8) + recvbuf[QR_SER+1];
		recvdata.serialnum_unit = (recvbuf[QR_SER+2]<<8) + recvbuf[QR_SER+3];
		memcpy(recvdata.config_ip.byte, &(recvbuf[QR_IP]), 4);
		memcpy(recvdata.config_gateway.byte, &(recvbuf[QR_GATE]), 4);
		
		temp=recvbuf[QR_NMB];
		if(temp>4)
			temp=4;
		memset(recvdata.config_netmask.byte, 0xff, temp);
		if(temp<4)
			recvdata.config_netmask.byte[temp]=recvbuf[QR_NMM];
	
		recvdata.firmware_major=recvbuf[QR_FIRMJ];
		recvdata.firmware_minor=recvbuf[QR_FIRMN];
		recvdata.config_enable=recvbuf[QR_CFGEN];
		
		// If we're configured to filter on MAC and it doesn't match, skip this.
		// If we're not filtering on MAC, then it doesn't matter.
		if( (((*query_results_ptr)->filter) & ETH32CFG_FILTER_MAC) && memcmp(recvdata.mac, (*query_results_ptr)->mac, 6) )
			return(0);
			
		// Same thing for filtering on serial number
		if( (((*query_results_ptr)->filter) & ETH32CFG_FILTER_SERIAL) && 
		    (recvdata.serialnum_batch!=(*query_results_ptr)->serialnum_batch || recvdata.serialnum_unit!=(*query_results_ptr)->serialnum_unit) 
		  )
			return(0);
		
		
		// Find this MAC in the list, or make new entry
		i=query_replies_find(query_results_ptr, recvdata.mac);
		if(i<0)
			return(i); // Exit with an error
		
		if((*query_results_ptr)->replies[i].query_response==0) // If the data from this reply hasn't been filled in, do it.
		{
			(*query_results_ptr)->replies[i].data.product_id=recvdata.product_id;
			memcpy((*query_results_ptr)->replies[i].data.mac, recvdata.mac, 6);
			(*query_results_ptr)->replies[i].data.serialnum_batch=recvdata.serialnum_batch;
			(*query_results_ptr)->replies[i].data.serialnum_unit=recvdata.serialnum_unit;
			(*query_results_ptr)->replies[i].data.config_ip=recvdata.config_ip;
			(*query_results_ptr)->replies[i].data.config_gateway=recvdata.config_gateway;
			(*query_results_ptr)->replies[i].data.config_netmask=recvdata.config_netmask;
			(*query_results_ptr)->replies[i].data.firmware_major=recvdata.firmware_major;
			(*query_results_ptr)->replies[i].data.firmware_minor=recvdata.firmware_minor;
			(*query_results_ptr)->replies[i].data.config_enable=recvdata.config_enable;
			
			// and mark it as filled in
			(*query_results_ptr)->replies[i].query_response=1;
		}
	}
	else if(recvbuf[0]==CMD_IPCONF_REPLY)
	{
		if(recvlen<IR_LEN)
			return(0);
		// interpret the raw buffer
		recvdata.dhcp=recvbuf[IR_DHCP];
		memcpy(recvdata.mac, &(recvbuf[IR_MAC]), 6);
		recvdata.product_id = recvbuf[IR_PROD];
		recvdata.serialnum_batch = (recvbuf[IR_SER]<<8) + recvbuf[IR_SER+1];
		recvdata.serialnum_unit = (recvbuf[IR_SER+2]<<8) + recvbuf[IR_SER+3];
		memcpy(recvdata.active_ip.byte, &(recvbuf[IR_IP]), 4);
		memcpy(recvdata.active_gateway.byte, &(recvbuf[IR_GATE]), 4);
		
		temp=recvbuf[IR_NMB];
		if(temp>4)
			temp=4;
		memset(recvdata.active_netmask.byte, 0xff, temp);
		if(temp<4)
			recvdata.active_netmask.byte[temp]=recvbuf[IR_NMM];

		// If we're configured to filter on MAC and it doesn't match, skip this.
		// If we're not filtering on MAC, then it doesn't matter.
		if( (((*query_results_ptr)->filter) & ETH32CFG_FILTER_MAC) && memcmp(recvdata.mac, (*query_results_ptr)->mac, 6) )
			return(0);
			
		// Same thing for filtering on serial number
		if( (((*query_results_ptr)->filter) & ETH32CFG_FILTER_SERIAL) && 
		    (recvdata.serialnum_batch!=(*query_results_ptr)->serialnum_batch || recvdata.serialnum_unit!=(*query_results_ptr)->serialnum_unit) 
		  )
			return(0);

		// Find this MAC in the list, or make new entry
		i=query_replies_find(query_results_ptr, recvdata.mac); 
		if(i<0)
			return(i); // Exit with an error

		if((*query_results_ptr)->replies[i].ipconfig_response==0) // If the data from this reply hasn't been filled in, do it.
		{
			(*query_results_ptr)->replies[i].data.dhcp=recvdata.dhcp;
			memcpy((*query_results_ptr)->replies[i].data.mac, recvdata.mac, 6);
			(*query_results_ptr)->replies[i].data.product_id=recvdata.product_id;
			(*query_results_ptr)->replies[i].data.serialnum_batch=recvdata.serialnum_batch;
			(*query_results_ptr)->replies[i].data.serialnum_unit=recvdata.serialnum_unit;
			(*query_results_ptr)->replies[i].data.active_ip=recvdata.active_ip;
			(*query_results_ptr)->replies[i].data.active_gateway=recvdata.active_gateway;
			(*query_results_ptr)->replies[i].data.active_netmask=recvdata.active_netmask;
			
			// and mark it as filled in
			(*query_results_ptr)->replies[i].ipconfig_response=1;
			
			// if a filter is set, and we just stored a response, then return 1 to indicate that the process 
			// can quit now.  Only one device should match, and we have found it.
			if( (*query_results_ptr)->filter )
				return(1);
		}

	}

	return(0);
}


eth32cfg CALLCONVENTION CALLEXTRA eth32cfg_query(eth32cfg_ip_t *bcastaddr, int *number, int *result)
{
	// Send a broadcast packet out to discover the presence of all ETH32 devices.
	// Listen for and assemble responses, and return a handle that can be used to access them.
	// Return value:
	//    Returns a "handle" to be used for accessing the responses.  Should be freed with eth32cfg_free
	//    Returns zero if error, and stores error code in *result.

	query_replies_t *query_results; /* Allocated memory */
	query_reply_data_t buf;
	int i,j;
	int ret;



	// Intialize result buffer.
	query_results=malloc(sizeof(query_replies_t)); // We're allocating more memory than necessary, but that doesn't hurt anything.
	query_results->count=0;
	query_results->filter=0; // No filtering -- return all results.
	
	// NOTE: We're passing a pointer to the pointer to our memory -- this is so that when we reallocate the 
	// memory, if it needs to move, we can update the pointer
	ret=eth32cfg_cmd_response(bcastaddr, QUERYCOUNT, QUERYDELAY, &query_send_callback, 0, 0, &query_recv_callback, &query_results);
	if(ret)
	{
		if(result)
			*result=ret;
		return(0);
	}
	

	// Now sort the list by MAC address (bubble sort)
	// i is the index of the last element that should be considered in the 
	// comparisons made by the inner loop.
	for(i=query_results->count-1; i>0; i--)
	{
		for(j=0; j<i; j++)
		{
			if(memcmp(&(query_results->replies[j].data.mac), &(query_results->replies[j+1].data.mac), 6)>0)
			{
				// Need to swap
				memcpy(&buf, &(query_results->replies[j]), sizeof(query_reply_data_t));
				memcpy(&(query_results->replies[j]), &(query_results->replies[j+1]), sizeof(query_reply_data_t));
				memcpy(&(query_results->replies[j+1]), &buf, sizeof(query_reply_data_t));
			}
		}
	}
	
	// Look through the list -- if there are any responses from devices with firmware <3.0 then
	// we will fill in the "active" settings from the "config" settings.  These devices don't 
	// support DHCP, so they are always the same.
	for(i=0; i<query_results->count; i++)
	{
		if(query_results->replies[i].data.firmware_major<3)
		{
			query_results->replies[i].data.dhcp=0;
			query_results->replies[i].data.active_ip=query_results->replies[i].data.config_ip;
			query_results->replies[i].data.active_netmask=query_results->replies[i].data.config_netmask;
			query_results->replies[i].data.active_gateway=query_results->replies[i].data.config_gateway;
		}
	}

	*number=query_results->count;
	if(result)
		*result=0;
	
	// Their "handle" is the address of the memory we have allocated
	return(query_results);
}

int CALLCONVENTION CALLEXTRA eth32cfg_get_config(eth32cfg handle, int index, eth32cfg_data_t *dataptr)
{
	// Get reponse data from the handle returned by eth32cfg_query
	
	query_replies_t *query_results=handle;
	
	if(handle==0)
		return(ETH_INVALID_HANDLE);
	
	if(index<0)
		return(ETH_INVALID_INDEX);
	
	if(index >= query_results->count)
		return(ETH_INVALID_INDEX);
	

	*dataptr=query_results->replies[index].data;
	
	return(0);
}


eth32cfg CALLCONVENTION CALLEXTRA eth32cfg_discover_ip(eth32cfg_ip_t *bcastaddr, unsigned int flags, unsigned char *mac, unsigned char product_id, unsigned short serialnum_batch, unsigned short serialnum_unit, int *number, int *result)
{
	// Send a packet out to discover the presence of ETH32 devices having a specified mac and/or serial number
	// Listen for and assemble responses, and return a handle that can be used to access them.
	// If the flag for filtering on MAC address is not specified, then the MAC address pointer can be NULL
	// Return value:
	//    Returns a "handle" to be used for accessing the responses.  Should be freed with eth32cfg_free
	//    Returns zero if error, and stores error code in *result.

	query_replies_t *query_results; /* Allocated memory */
	query_reply_data_t buf;
	unsigned char sendbuf[IQ_LEN]={CMD_IPCONF_QUERY, 0x44, 0xee, 0x44, 0x11};
	int i,j;
	int ret;


	

	// Intialize result buffer.
	query_results=malloc(sizeof(query_replies_t)); // We're allocating more memory than necessary, but that doesn't hurt anything.
	query_results->count=0;
	query_results->filter=flags;

	// Set the flags and filter information in the query packet we're sending.
	// We 
	sendbuf[IQ_FILTER]=(unsigned char)flags;
	
	if( (flags & ETH32CFG_FILTER_MAC) && mac )
	{
		memcpy(sendbuf+IQ_MAC, mac, 6);
		memcpy(query_results->mac, mac, 6);
	}
		
	if( flags & ETH32CFG_FILTER_SERIAL )
	{
		sendbuf[IQ_PROD]=product_id;
		sendbuf[IQ_SER]=(unsigned char)(serialnum_batch>>8);
		sendbuf[IQ_SER+1]=(unsigned char)(serialnum_batch);
		sendbuf[IQ_SER+2]=(unsigned char)(serialnum_unit>>8);
		sendbuf[IQ_SER+3]=(unsigned char)(serialnum_unit);
		
		query_results->serialnum_batch=serialnum_batch;
		query_results->serialnum_unit=serialnum_unit;
	}

	
	// NOTE: We're passing a pointer to the pointer to our memory -- this is so that when we reallocate the 
	// memory, if it needs to move, we can update the pointer
	ret=eth32cfg_cmd_response(bcastaddr, QUERYCOUNT, QUERYDELAY, 0, sendbuf, sizeof(sendbuf), &query_recv_callback, &query_results);
	if(ret)
	{
		if(result)
			*result=ret;
		return(0);
	}
	

	// Now sort the list by MAC address (bubble sort)
	// i is the index of the last element that should be considered in the 
	// comparisons made by the inner loop.
	for(i=query_results->count-1; i>0; i--)
	{
		for(j=0; j<i; j++)
		{
			if(memcmp(&(query_results->replies[j].data.mac), &(query_results->replies[j+1].data.mac), 6)>0)
			{
				// Need to swap
				memcpy(&buf, &(query_results->replies[j]), sizeof(query_reply_data_t));
				memcpy(&(query_results->replies[j]), &(query_results->replies[j+1]), sizeof(query_reply_data_t));
				memcpy(&(query_results->replies[j+1]), &buf, sizeof(query_reply_data_t));
			}
		}
	}

	*number=query_results->count;
	if(result)
		*result=0;
	
	// Their "handle" is the address of the memory we have allocated
	return(query_results);
}

int set_config_recv_callback(void *data, unsigned char *recvbuf, int recvlen)
{
	// This callback is called to process each response we receive when doing a Set Configuration command
	// See comment above by callback type definition for explanation of return values.

	int *ecodeptr=data;
	
	// Check for command of 2 
	if(recvbuf[0]==CMD_CONFIRM)
	{
		if(recvlen<CF_LEN)
			return(0);
		
		if(recvbuf[CF_STATUS]==0)
		{
			*ecodeptr=ETH_CFG_REJECT;
			return(1); // Stop processing with no error code returned by eth32cfg_cmd_response
		}
		else
		{
			*ecodeptr=0; // success
			return(1); // Stop processing with no error code returned by eth32cfg_cmd_response
		}
	}
		
	
	return(0);
}

int CALLCONVENTION CALLEXTRA eth32cfg_set_config(eth32cfg_ip_t *bcastaddr, eth32cfg_data_t *dataptr)
{
	// This function sends out a packet to change the configuration in a device, then listens 
	// for a response.
	unsigned short ck;
	int ecode;
	int ret;
	unsigned char nmbytes;
	unsigned char nmmask;
	unsigned char sendbuf[SC_LEN]={CMD_SET_CONFIG};
	
	memcpy(&(sendbuf[SC_MAC]), dataptr->mac, 6);
	sendbuf[SC_SER]=(unsigned char)((dataptr->serialnum_batch)>>8);
	sendbuf[SC_SER+1]=(unsigned char)(dataptr->serialnum_batch);
	sendbuf[SC_SER+2]=(unsigned char)((dataptr->serialnum_unit)>>8);
	sendbuf[SC_SER+3]=(unsigned char)(dataptr->serialnum_unit);
	memcpy(&(sendbuf[SC_IP]), dataptr->config_ip.byte, 4);
	memcpy(&(sendbuf[SC_GATE]), dataptr->config_gateway.byte, 4);
	
	ret=eth32cfg_netmask_breakup(&(dataptr->config_netmask), &nmbytes, &nmmask);
	if(ret)
		return(ret);
	sendbuf[SC_NMB]=nmbytes;
	sendbuf[SC_NMM]=nmmask;
	sendbuf[SC_DHCP]=dataptr->dhcp;
	
	ck= ~ (checksum((unsigned short *)sendbuf, SC_LEN-2));  // Checksum all but the last two bytes, and invert bits so it's ready to store
	   
	// At this point, the checksum could be in little-endian order or big-endian order, 
	// depending on the type of machine we're on.  But, as long as we store it back 
	// into the buffer as an unsigned short, it will cancel out the swap if we're 
	// on a little-endian machine.  See RFC 1071 for more information.
	*((unsigned short*)&(sendbuf[SC_CKSUM]))=ck;
	
	
	// Default to code of not receiving an acknowledgement.  If the callback receives a valid acknowledgement,
	// it will change this
	ecode=ETH_CFG_NOACK;
	
	// Send command and process responses.  Pass pointer to our response code.
	// Only send 1 command out, and wait (up to) 1000ms for a response
	ret=eth32cfg_cmd_response(bcastaddr, 1, 1000, 0, sendbuf, sizeof(sendbuf), &set_config_recv_callback, &ecode);
	if(ret)
	{
		return(ret);
	}
	
	return(ecode);
}


void CALLCONVENTION eth32cfg_free(eth32cfg handle)
{
	// This must be called after receiving a valid response
	// from eth32cfg_query.
	if(handle)
		free(handle);
}

int CALLCONVENTION CALLEXTRA eth32cfg_serialnum_string(unsigned char product_id, unsigned short batch, unsigned short unit, char *serialstring, int bufsize)
{
	// Return the serial number as a human-readable string 
	// as it is printed on the product case.
	// serial - points to a buffer into which the serial number will be written
	// bufsize - size of the buffer pointed to by serial.  No more than
	//           this number of bytes will be written to the buffer, including
	//           the NULL terminator.
	// Returns negative on error or zero on success



	int i;
	int temp;
	char bstr[SERLEN_BATCH + 1]={0};
	

	// Make sure the buffer is long enough for everything, including
	// a dash and a NULL.
	if(bufsize < (SERLEN_PRODID + 1 + SERLEN_BATCH + SERLEN_UNIT + 1))
	{
		return(ETH_BUFSIZE);
	}
	
	
	// Create the batch string, which is AA, AB, AC, ... AZ, BA
	for(i=0; i<SERLEN_BATCH; i++)
	{
		temp = batch % 26;
		bstr[SERLEN_BATCH - 1 - i]='A'+temp;
		
		batch = batch / 26;
	}
	
	// Finally, create the string
#ifdef _MSVC
	_snprintf_s(serialstring, bufsize, bufsize-1, "%0*d-%s%0*d", 
	                 SERLEN_PRODID, product_id,
	                 bstr,
	                 SERLEN_UNIT, unit);

#else
	snprintf(serialstring, bufsize, "%0*d-%s%0*d", 
	                 SERLEN_PRODID, product_id,
	                 bstr,
	                 SERLEN_UNIT, unit);
#endif

	return(0);
}



int CALLCONVENTION CALLEXTRA eth32cfg_plugin_load(int option)
{
	// Set/Load the currently-active sniffer type that should be used to LISTEN for ETH32 responses.
#ifdef WINDOWS
	int ret;
	
	// If unchanged, do nothing.
	if(option == eth32cfg_global.plugin_type)
		return(0);
	
	switch(option)
	{
		case ETH32CFG_PLUG_NONE:
			break;
		case ETH32CFG_PLUG_SYS:
			ret=eth32cfg_iphelper_load();
			if(ret)
				return(ret);
			break;
		case ETH32CFG_PLUG_PCAP:
			ret=eth32cfg_pcap_load();
			if(ret)
				return(ret);
			break;
		default:
			return(ETH_NOT_SUPPORTED);
	}
		
	// See if anything needs to be freed, etc, from the previously-selected plugin
	switch(eth32cfg_global.plugin_type)
	{
		case ETH32CFG_PLUG_SYS:
			eth32cfg_iphelper_unload();
			break;
		case ETH32CFG_PLUG_PCAP:
			if(eth32cfg_global.pcap_ifacename)
				free(eth32cfg_global.pcap_ifacename);
			eth32cfg_global.pcap_ifacename=0;
			eth32cfg_pcap_unload();
			break;
	}
	
	// Store the new plugin type
	eth32cfg_global.plugin_type=option;
	return(0);
#else
	return(ETH_NOT_SUPPORTED);
#endif

}

eth32cfgiflist CALLCONVENTION CALLEXTRA eth32cfg_plugin_interface_list(int *numd, int *result)
{
	// This function is called to initiate the process of retrieving a list of network interfaces
	// detected by the currently-selected plugin.
	
#ifdef WINDOWS	
	
	switch(eth32cfg_global.plugin_type)
	{
		case ETH32CFG_PLUG_SYS:
			return(eth32cfg_iphelper_interface_list(numd, result));
			break;
		case ETH32CFG_PLUG_PCAP:
			return(eth32cfg_pcap_interface_list(numd, result));
			break;
		default:
			if(result)
				*result=ETH_NOT_SUPPORTED;
			return(0);
			break;
	}
#else
	if(result)
		*result=ETH_NOT_SUPPORTED;
	return(0);
#endif
	
	
}


int CALLCONVENTION CALLEXTRA eth32cfg_plugin_interface_address(eth32cfgiflist handle, int index, eth32cfg_ip_t *ip, eth32cfg_ip_t *netmask)
{
	// This function retrieves the/a IP address and netmask for the specified network interface
#ifdef WINDOWS	
	
	switch(eth32cfg_global.plugin_type)
	{
		case ETH32CFG_PLUG_SYS:
			return(eth32cfg_iphelper_interface_address(handle, index, ip, netmask));
			break;
		case ETH32CFG_PLUG_PCAP:
			return(eth32cfg_pcap_interface_address(handle, index, ip, netmask));
			break;
		default:
			return(ETH_NOT_SUPPORTED);
	}
#else
	return(ETH_NOT_SUPPORTED);
#endif
}

int CALLCONVENTION CALLEXTRA eth32cfg_plugin_interface_type(eth32cfgiflist handle, int index, int *type)
{
	// This function retrieves the type of the specified network interface.
#ifdef WINDOWS	
	
	switch(eth32cfg_global.plugin_type)
	{
		case ETH32CFG_PLUG_SYS:
			return(eth32cfg_iphelper_interface_type(handle, index, type));
			break;
		case ETH32CFG_PLUG_PCAP:
			return(eth32cfg_pcap_interface_type(handle, index, type));
			break;
		default:
			return(ETH_NOT_SUPPORTED);
	}
#else
	return(ETH_NOT_SUPPORTED);
#endif
}

int CALLCONVENTION CALLEXTRA eth32cfg_plugin_interface_name(eth32cfgiflist handle, int index, int nametype, char *name, int *length)
{
	// Retrieves the specified type of name of the specified interface index.
	// The length of the name buffer should be pointed to by the length parameter.
	// If that buffer size is not adequate, the required size, including space for the null byte, will be written to *length 
	// and ETH_BUFSIZE will be returned.

#ifdef WINDOWS	
	
	switch(eth32cfg_global.plugin_type)
	{
		case ETH32CFG_PLUG_SYS:
			return(eth32cfg_iphelper_interface_name(handle, index, nametype, name, length));
			break;
		case ETH32CFG_PLUG_PCAP:
			return(eth32cfg_pcap_interface_name(handle, index, nametype, name, length));
			break;
		default:
			return(ETH_NOT_SUPPORTED);
	}
#else
	return(ETH_NOT_SUPPORTED);
#endif
}

int CALLCONVENTION CALLEXTRA eth32cfg_plugin_choose_interface(eth32cfgiflist handle, int index)
{
	// Defines a interface on which to listen for replies.
	// At the moment, this only applies to the pcap plugin.
#ifdef WINDOWS
	char *ifacename;
	int length;
	int ret;

	switch(eth32cfg_global.plugin_type)
	{
		case ETH32CFG_PLUG_PCAP:
			// Figure out what buffer size we need
			length=0;
			ret=eth32cfg_pcap_interface_name(handle, index, 0, 0, &length);
			if(ret != ETH_BUFSIZE)
				return(ret);
			ifacename=malloc(length);
			if(ifacename==0)
				return(ETH_MALLOC_ERROR);
			ret=eth32cfg_pcap_interface_name(handle, index, 0, ifacename, &length);
			if(ret)
			{
				free(ifacename);
				return(ret);
			}
			
			// If we're here, we've successfully allocated a buffer and stored the interface name into it.
			// Before we save a pointer to it, see if there is already a pointer saved and free it if so.
			if(eth32cfg_global.pcap_ifacename)
				free(eth32cfg_global.pcap_ifacename);
				
			eth32cfg_global.pcap_ifacename=ifacename;
			
			break;
		default:
			return(ETH_NOT_SUPPORTED);
	}
	return(0);
#else
	return(ETH_NOT_SUPPORTED);
#endif
	
}


void CALLCONVENTION CALLEXTRA eth32cfg_plugin_interface_list_free(eth32cfgiflist handle)
{
	// This function retrieves the type of the specified network interface.
#ifdef WINDOWS	
	
	switch(eth32cfg_global.plugin_type)
	{
		case ETH32CFG_PLUG_SYS:
			eth32cfg_iphelper_interface_list_free(handle);
			return;
			break;
		case ETH32CFG_PLUG_PCAP:
			eth32cfg_pcap_interface_list_free(handle);
			return;
			break;
	}

#endif
}

