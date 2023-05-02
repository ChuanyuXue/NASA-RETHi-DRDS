/* Winford Engineering ETH32 API
 * Copyright 2010 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */
// This code provides an interface to the items we need to use the winpcap library

#ifndef eth32cfg_pcap_h
#define eth32cfg_pcap_h

#ifdef WINDOWS
#include <winsock2.h>
#endif

#include "eth32.h"

// NOTE -- when compiling with Visual C++, you'll need to comment out the 
// #define #define vsnprintf _vsnprintf at the end of pcap-stdinc.h
#define HAVE_REMOTE
#include "pcap.h"

int eth32cfg_pcap_load();
eth32cfgiflist eth32cfg_pcap_interface_list(int *numd, int *result);
void eth32cfg_pcap_interface_list_free(void *handle);
int eth32cfg_pcap_interface_address(void *handle, int index, eth32cfg_ip_t *ip, eth32cfg_ip_t *netmask);
int eth32cfg_pcap_interface_type(void *handle, int index, int *type);
int eth32cfg_pcap_interface_name(void *handle, int index, int nametype, char *name, int *length);
void eth32cfg_pcap_unload();


int eth32cfg_pcap_open(pcap_t **handle, char *devname);
int eth32cfg_pcap_recv(pcap_t *handle, void *buf, int len);
void eth32cfg_pcap_close(pcap_t *handle);



#endif
