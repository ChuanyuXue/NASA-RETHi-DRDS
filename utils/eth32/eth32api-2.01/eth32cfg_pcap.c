/* Winford Engineering ETH32 API
 * Copyright 2010 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */
// This code provides an interface to the items we need to use the winpcap library

// Include winsock2.h first, since eventually windows.h gets included through the below includes
// and that will include winsock.h if we haven't already included winsock2.h, and there will be conflicts
#include <winsock2.h>

#include "eth32cfg_pcap.h"
#include "eth32cfg.h"

#ifdef WINDOWS

HMODULE hpcap=0;

/* Function typedefs for pcap library */
/* Be sure to define these as using C calling convention so that it doesn't matter what the project properties
 * define as the default.  These MUST be called correctly or it will crash the program.
 */
typedef pcap_t *(__cdecl *pcap_open_t)(const char *source, int snaplen, int flags, int read_timeout, struct pcap_rmtauth *auth, char *errbuf);
typedef int	(__cdecl *pcap_datalink_t)(pcap_t *);
typedef int	(__cdecl *pcap_compile_t)(pcap_t *, struct bpf_program *, char *, int, bpf_u_int32);
typedef int	(__cdecl *pcap_setfilter_t)(pcap_t *, struct bpf_program *);
typedef void (__cdecl *pcap_close_t)(pcap_t *);
typedef int (__cdecl *pcap_next_ex_t)(pcap_t *, struct pcap_pkthdr **, const u_char **);
typedef int	(__cdecl *pcap_findalldevs_t)(pcap_if_t **, char *);
typedef void (__cdecl *pcap_freealldevs_t)(pcap_if_t *);

/* Function pointers for pcap library */
pcap_open_t _pcap_open;
pcap_datalink_t _pcap_datalink;
pcap_compile_t _pcap_compile;
pcap_setfilter_t _pcap_setfilter;
pcap_close_t _pcap_close;
pcap_next_ex_t _pcap_next_ex;
pcap_findalldevs_t _pcap_findalldevs;
pcap_freealldevs_t _pcap_freealldevs;

/* IPv4 header */
typedef struct ip_header{
    u_char  ver_ihl;        // Version (4 bits) + Internet header length (4 bits)
    u_char  tos;            // Type of service 
    u_short tlen;           // Total length 
    u_short identification; // Identification
    u_short flags_fo;       // Flags (3 bits) + Fragment offset (13 bits)
    u_char  ttl;            // Time to live
    u_char  proto;          // Protocol
    u_short crc;            // Header checksum
    eth32cfg_ip_t  saddr;      // Source address
    eth32cfg_ip_t  daddr;      // Destination address
    u_int   op_pad;         // Option + Padding
}ip_header;

/* UDP header*/
typedef struct udp_header{
    u_short sport;          // Source port
    u_short dport;          // Destination port
    u_short len;            // Datagram length
    u_short crc;            // Checksum
}udp_header;


int eth32cfg_pcap_load()
{
	hpcap=LoadLibraryEx("wpcap.dll", 0, 0);
	if( hpcap == 0 )
		return(ETH_LOADLIB);
	// Otherwise, start setting pointers.
	if( (_pcap_open=(pcap_open_t)GetProcAddress(hpcap, "pcap_open"))==0 )
		goto pcap_exit_unload;
	if( (_pcap_datalink=(pcap_datalink_t)GetProcAddress(hpcap, "pcap_datalink"))==0 )
		goto pcap_exit_unload;
	if( (_pcap_compile=(pcap_compile_t)GetProcAddress(hpcap, "pcap_compile"))==0 )
		goto pcap_exit_unload;
	if( (_pcap_setfilter=(pcap_setfilter_t)GetProcAddress(hpcap, "pcap_setfilter"))==0 )
		goto pcap_exit_unload;
	if( (_pcap_close=(pcap_close_t)GetProcAddress(hpcap, "pcap_close"))==0 )
		goto pcap_exit_unload;
	if( (_pcap_next_ex=(pcap_next_ex_t)GetProcAddress(hpcap, "pcap_next_ex"))==0 )
		goto pcap_exit_unload;
	if( (_pcap_findalldevs=(pcap_findalldevs_t)GetProcAddress(hpcap, "pcap_findalldevs"))==0 )
		goto pcap_exit_unload;
	if( (_pcap_freealldevs=(pcap_freealldevs_t)GetProcAddress(hpcap, "pcap_freealldevs"))==0 )
		goto pcap_exit_unload;
			
	// If we got here, loading the library went fine
	return(0);
pcap_exit_unload:
	// If we get here, we need to unload the library and return an error
	FreeLibrary(hpcap);
	hpcap=0;
	return(ETH_LOADLIB);
}

eth32cfgiflist eth32cfg_pcap_interface_list(int *numd, int *result)
{
	char errbuf[PCAP_ERRBUF_SIZE];
	pcap_if_t *alldevs;
	pcap_if_t *d;
	int count;
	
	if(hpcap==0)
	{
		if(result)
			*result=ETH_PLUGIN;
		return(0);
	}

	if(_pcap_findalldevs(&alldevs, errbuf) == -1)
	{
		if(result)
			*result=ETH_PLUGIN;
		return(0);
	}

	// count them
	count=0;
	for(d=alldevs; d; d=d->next)
		count++;

	*numd=count;
	
	if(count==0)
	{
		_pcap_freealldevs(alldevs);
		alldevs=0;
	}
	
	if(result)
		*result=0;
		
	return(alldevs);
}

void eth32cfg_pcap_interface_list_free(eth32cfgiflist handle)
{
	if(hpcap==0)
		return;

	
	_pcap_freealldevs(handle);
}

int eth32cfg_pcap_interface_address(eth32cfgiflist handle, int index, eth32cfg_ip_t *ip, eth32cfg_ip_t *netmask)
{
	pcap_if_t *d;
	pcap_addr_t *addresses;
	
	int i;
	unsigned long addr;

	if(index < 0)
		return(ETH_INVALID_INDEX);
	
	for(d=handle,i=0; d && i<index; d=d->next, i++)
		;
	
	// If d is null, that means we ran off the end of the interface list, so the index they gave is out of range.
	if( ! d )
		return(ETH_INVALID_INDEX);
		
	// Otherwise, d is the interface we want.
	
	for(addresses=d->addresses; addresses; addresses=addresses->next)
	{
		if(addresses->addr->sa_family==AF_INET)
		{
			addr=((struct sockaddr_in *)(addresses->addr))->sin_addr.s_addr;
			addr=ntohl(addr);
			ip->byte[0]=(unsigned char)(addr>>24);
			ip->byte[1]=(unsigned char)(addr>>16);
			ip->byte[2]=(unsigned char)(addr>>8);
			ip->byte[3]=(unsigned char)(addr);
			
			addr=((struct sockaddr_in *)(addresses->netmask))->sin_addr.s_addr;
			addr=ntohl(addr);
			netmask->byte[0]=(unsigned char)(addr>>24);
			netmask->byte[1]=(unsigned char)(addr>>16);
			netmask->byte[2]=(unsigned char)(addr>>8);
			netmask->byte[3]=(unsigned char)(addr);
			
			// That's all we need -- return it
			return(0);
		}
	}
	
	// If we got here, we never found an AF_INET address entry.
	// Return ETH_NOT_SUPPORTED to indicate this interface does not support or is not configured for IPv4
	return(ETH_NOT_SUPPORTED);
}


int eth32cfg_pcap_interface_type(eth32cfgiflist handle, int index, int *type)
{
	// pcap library doesn't provide this information
	return(ETH_NOT_SUPPORTED); 
}

int eth32cfg_pcap_interface_name(eth32cfgiflist handle, int index, int nametype, char *name, int *length)
{
	// Retrieves the specified type of name of the specified interface index.
	// The length of the name buffer should be pointed to by the length parameter.
	// If that buffer size is not adequate, the required size will be written to *length.
	pcap_if_t *d;
	char *chosen;
	int len;
	int i;
	
	// pcap library doesn't provide friendly name
	if(nametype==ETH32CFG_IFACENAME_FRIENDLY)
		return(ETH_NOT_SUPPORTED);

	if(!handle)
		return(ETH_INVALID_HANDLE);

	if(index < 0)
		return(ETH_INVALID_INDEX);
	
	for(d=handle,i=0; d && i<index; d=d->next, i++)
		;
	
	// If d is null, that means we ran off the end of the interface list, so the index they gave is out of range.
	if( ! d )
		return(ETH_INVALID_INDEX);
		
	// Otherwise, d is the interface we want.
	switch(nametype)
	{
		case ETH32CFG_IFACENAME_STANDARD:
			chosen=d->name;
			break;
		case ETH32CFG_IFACENAME_DESCRIPTION:
			chosen=d->description;
			break;
		default:
			return(ETH_NOT_SUPPORTED);
	}
	
	len=(int)strlen(chosen);
	
	if(*length < (len+1) )
	{
		*length=len+1;
		return(ETH_BUFSIZE);
	}
	else
	{
		strcpy(name, chosen);
	}
	
	return(0);
	
}

void eth32cfg_pcap_unload()
{
	// This is all we need to free
	if(hpcap)
		FreeLibrary(hpcap);
	hpcap=0;
	
}


// -----------------------------------------------------

int eth32cfg_pcap_open(pcap_t **handle, char *ifacename)
{
	/* Helper function to open/initialize the pcap capture.
	   Returns 0 on success, otherwise an error code.
	 */
	pcap_t *adhandle;
	/* I can't find docs in pcap stating whether the compiled filter needs to remain in valid memory after
	 * calling setfilter.  So to be safe, we'll declare it static. */
	static struct bpf_program fcode;

	char errbuf[PCAP_ERRBUF_SIZE];
	
	if(hpcap==0)
		return(ETH_PLUGIN);    


	if(ifacename==0 || strlen(ifacename)<=0)
		return(ETH_PLUGIN);
	adhandle=_pcap_open(ifacename, 65536, PCAP_OPENFLAG_PROMISCUOUS, 250, NULL, errbuf);
	if( ! adhandle )
		return(ETH_PLUGIN);

	if(_pcap_datalink(adhandle) != DLT_EN10MB)
    {
	    _pcap_close(adhandle);
		return(ETH_PLUGIN);
	}
	
	if(_pcap_compile(adhandle, &fcode, "ip and udp and src port 7151", 1, 0) < 0)
	{
		_pcap_close(adhandle);
		return(ETH_PLUGIN);
	}
	
	if (_pcap_setfilter(adhandle, &fcode)<0)
	{
		_pcap_close(adhandle);
		return(ETH_PLUGIN);
	}
	
	*handle=adhandle;
	return(0);
}

int eth32cfg_pcap_recv(pcap_t *handle, void *buf, int len)
{
	/* helper function to receive packets from pcap
	  Return values:
	 * Negative: error
	 * 0 = timeout
	 * positive = length of data
	 */
	int ret;
	struct pcap_pkthdr *header;
	const u_char *data;
    ip_header *ih;
    unsigned int ip_len;
    udp_header *uh;
    unsigned char *udpdata;
    int datalen;
    unsigned int sum;

	if(hpcap==0)
		return(ETH_PLUGIN);    
	
	while(1)
	{
		ret=_pcap_next_ex(handle, &header, &data);
		if(ret==0) // timeout
			return(0);
		
		/* make sure the packet is at least long enough for an ethernet header and the shortest IP header */
		if(header->caplen <= 14+20)
			continue;
			
		ih = (ip_header *)(data+14); // 14 is ethernet header length
		if(ih->proto != 17) // Make sure this is a UDP packet
			continue;
		ip_len = (ih->ver_ihl & 0xf) * 4;
		
		/* Make sure it's long enough for ethernet + actual ip header + udp header */
		if(header->caplen <= 14+ip_len+8)
			continue;
		
		uh = (udp_header *)((unsigned char*)ih + ip_len);
		udpdata = (unsigned char*)uh + 8;
		datalen = ntohs( uh->len )-8; // length in header indicates total length of header and data
		
		// Make sure it's long enough for the UDP data as well
		if(header->caplen < 14+ip_len+8+datalen)
			continue;


		// checksum the UDP packet
		// Checksum the UDP header and the data.  The checksum function flips the bits
		// at the end, so we flip them back so that we can accumulate the checksum of the 
		// data, source, and destination IP addresses, and the protocol code, then we'll flip
		// them back at the end.
		sum = checksum((unsigned short *)uh, datalen+8);
		sum += checksum((unsigned short *)(&(ih->saddr)), 4);
		sum += checksum((unsigned short *)(&(ih->daddr)), 4);
		sum += htons(17); // UDP protocol ID
		sum += htons(datalen+8); // total UDP length
		/*  Fold 32-bit sum to 16 bits */
		while (sum>>16)
			sum = (sum & 0xffff) + (sum >> 16);

		if(sum != 0xffff)
			continue; // checksum didn't verify
		
		// limit how much we copy to the available buffer size
		if(datalen > len)
			datalen=len;
		memcpy(buf, udpdata, datalen);
		return(datalen);
	}
	
}

void eth32cfg_pcap_close(pcap_t *handle)
{
	_pcap_close(handle);
}


#endif
