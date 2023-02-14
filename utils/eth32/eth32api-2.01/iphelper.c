/* Winford Engineering ETH32 API
 * Copyright 2010 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */
// This code provides an interface to the items we need from the Windows IP Helper API

// This is necessary to have data type definitions that we need from the IP Helper API
#define _WIN32_WINNT 0x0501

#include <winsock2.h>
#include <Iphlpapi.h>
#include "eth32.h"
#include <malloc.h>

#ifdef WINDOWS

HMODULE hiphelper=0;

typedef struct
{
	DWORD index; // used internally for matching up different sources of information about interfaces
	char name[MAX_ADAPTER_NAME_LENGTH + 1];
	char friendly[MAX_ADAPTER_NAME_LENGTH + 1];
	char description[MAX_ADAPTER_DESCRIPTION_LENGTH + 1];
	eth32cfg_ip_t ip;
	eth32cfg_ip_t netmask;
	unsigned int type;
}devinfo_t;

typedef struct
{
	unsigned int count;
	devinfo_t devlist[1];
} devlist_t;

// Function typedefs for Windows IP Helper API (these use stdcall)
typedef DWORD (WINAPI *GetAdaptersInfo_t)(PIP_ADAPTER_INFO pAdapterInfo, PULONG pOutBufLen);
//typedef DWORD (WINAPI *GetIpAddrTable_t)(PMIB_IPADDRTABLE pIpAddrTable, PULONG pdwSize, BOOL bOrder);
typedef ULONG (WINAPI *GetAdaptersAddresses_t)(ULONG Family, ULONG Flags, PVOID Reserved, PIP_ADAPTER_ADDRESSES AdapterAddresses, PULONG SizePointer);


// And the corresponding function pointers:
GetAdaptersInfo_t _GetAdaptersInfo;
//GetIpAddrTable_t _GetIpAddrTable;
GetAdaptersAddresses_t _GetAdaptersAddresses;


int eth32cfg_iphelper_load()
{
	OSVERSIONINFO osversion;

	osversion.dwOSVersionInfoSize=sizeof(osversion);
	if(GetVersionEx(&osversion)==0)
		return(ETH_PLUGIN);
	hiphelper=LoadLibraryEx("iphlpapi.dll", 0, 0);
	if( hiphelper == 0 )
		return(ETH_LOADLIB);
	// Otherwise, start setting pointers.
	// The functions in IP Helper are stdcall, but differ in return value from the
	// definition of FARPROC, the return type of GetProcAddress, so we need to cast to avoid warning
	if( (_GetAdaptersInfo=(GetAdaptersInfo_t)GetProcAddress(hiphelper, "GetAdaptersInfo"))==0 )
		goto iphlp_exit_unload;
	//if( (_GetIpAddrTable=(GetIpAddrTable_t)GetProcAddress(hiphelper, "GetIpAddrTable"))==0 )
	//	goto iphlp_exit_unload;
	
	// Load the _GetAdaptersAddresses function if we're on XP (5.1) or later
	if(osversion.dwMajorVersion>5 ||
	   (osversion.dwMajorVersion==5 && osversion.dwMinorVersion>=1))
	{
		if( (_GetAdaptersAddresses=(GetAdaptersAddresses_t)GetProcAddress(hiphelper, "GetAdaptersAddresses"))==0 )
			goto iphlp_exit_unload;
	}
	else
		_GetAdaptersAddresses=0; // Indicate to ourselves that we don't have this function available.

		
	// If we got here, loading the library went fine
	return(0);
iphlp_exit_unload:
	// If we get here, we need to unload the library and return an error
	FreeLibrary(hiphelper);
	hiphelper=0;
	return(ETH_LOADLIB);
}

eth32cfgiflist eth32cfg_iphelper_interface_list(int *numd, int *result)
{
	// Prepare a interface list and return a handle and how many interfaces there are.
	// It may return zero in the numd parameter if there are no network interfaces on the system,
	// in which case the handle will also be zero, but no error code will be returned.
	PIP_ADAPTER_INFO adpinfo;
	PIP_ADAPTER_INFO adpinfo_loop;
	PIP_ADAPTER_ADDRESSES adpaddresses=0; // Make sure to initialize to zero to indicate whether we have data or not
	PIP_ADAPTER_ADDRESSES adpaddresses_loop;
	ULONG buflen;
	DWORD ret;
	ULONG uret;
	int myerr=0;
	int count;
	int i;
	int len;
	devlist_t *devlist;
	
	if(hiphelper==0)
	{
		if(result)
			*result=ETH_PLUGIN;
		return(0);
	}
	
	// First find out how long the buffer needs to be
	buflen=0;
	ret=_GetAdaptersInfo(0, &buflen);
	if(ret == ERROR_NO_DATA)
	{
		*numd=0;
		*result=0;
		return(0);
	}
	else if(ret != ERROR_BUFFER_OVERFLOW)
	{
		if(result)
			*result=ETH_PLUGIN;
		return(0);
	}

	adpinfo=malloc(buflen);
	if(adpinfo==0)
	{
		if(result)
			*result=ETH_MALLOC_ERROR;
		return(0);
	}

	ret=_GetAdaptersInfo(adpinfo, &buflen);
	// Check again for no interfaces, since we don't want to assume for sure in which case the call
	// would return that code.
	if(ret == ERROR_NO_DATA)
	{
		*numd=0;
		myerr=0;
		goto plugsysdevlist_err1;
	}		
	else if(ret != ERROR_SUCCESS)
	{
		myerr=ETH_PLUGIN;
		goto plugsysdevlist_err1;
	}
	// Figure out how many adapter info entries we have:
	count=0;
	adpinfo_loop=adpinfo;
	while(adpinfo_loop)
	{
		count++;
		adpinfo_loop=adpinfo_loop->Next;
	}
	
	devlist=malloc(sizeof(devlist_t)+sizeof(devinfo_t)*(count-1));
	if(devlist==0)
	{
		myerr=ETH_MALLOC_ERROR;
		goto plugsysdevlist_err1;
	}
	
	// Store the number of interfaces in the "header" of what we just allocated
	devlist->count=count;
	
	i=0;
	adpinfo_loop=adpinfo;
	while(adpinfo_loop)
	{
		strncpy(devlist->devlist[i].name, adpinfo_loop->AdapterName, sizeof(devlist->devlist[0].name)-1);
		devlist->devlist[i].name[sizeof(devlist->devlist[0].name)-1]=0; // NULL terminate last byte, in case we maxed out the strncpy
		strncpy(devlist->devlist[i].description, adpinfo_loop->Description, sizeof(devlist->devlist[0].description)-1);
		devlist->devlist[i].description[sizeof(devlist->devlist[0].description)-1]=0; // NULL terminate in case we maxed out strncpy
		// For now, terminate Friendly in case we aren't able to get a friendly name.
		devlist->devlist[i].friendly[0]=0;
		if(eth32cfg_string_to_ip(adpinfo_loop->IpAddressList.IpAddress.String, &(devlist->devlist[i].ip)))
		{
			// If there's an error code from converting the string IP to binary, just zero it out and move on
			memset(&(devlist->devlist[i].ip), 0, sizeof(devlist->devlist[0].ip));
		}
		if(eth32cfg_string_to_ip(adpinfo_loop->IpAddressList.IpMask.String, &(devlist->devlist[i].netmask)))
		{
			// If there's an error code from converting the string IP to binary, just zero it out and move on
			memset(&(devlist->devlist[i].netmask), 0, sizeof(devlist->devlist[0].netmask));
		}
		
		devlist->devlist[i].type=adpinfo_loop->Type;
		devlist->devlist[i].index=adpinfo_loop->Index;
		
		
		i++;
		adpinfo_loop=adpinfo_loop->Next;
	}
	// If we're here, that means we have successfully gotten a list of interfaces,
	// but without friendly names.  If we have the GetAdaptersAddresses function available to us,
	// go ahead and try to get the friendly names, but if we fail along the way, still go ahead
	// and return what we have without indicating an error.
	// We no longer need the memory we allocated for the AdaptersInfo function call, so free that:
	free(adpinfo);
	
	// Go ahead and set the number of interfaces so we are ready to return at any time:
	*numd=count;

	
	if(_GetAdaptersAddresses)
	{
		// MS recommended way of allocating memory and calling this function:
		buflen=15*1024;
		adpaddresses=malloc(buflen);
		if(adpaddresses==0)
		{
			return(devlist);
		}
		uret=_GetAdaptersAddresses(AF_INET, GAA_FLAG_SKIP_DNS_SERVER | GAA_FLAG_SKIP_MULTICAST | GAA_FLAG_SKIP_UNICAST, NULL, adpaddresses, &buflen);
		if(uret==ERROR_BUFFER_OVERFLOW)
		{
			adpaddresses=realloc(adpaddresses, buflen);
			if(adpaddresses==0)
			{
				return(devlist);
			}
			uret=_GetAdaptersAddresses(AF_INET, GAA_FLAG_SKIP_DNS_SERVER | GAA_FLAG_SKIP_MULTICAST | GAA_FLAG_SKIP_UNICAST, NULL, adpaddresses, &buflen);
		}
		// If we're here, we just got done calling GetAdaptersAddresses, regardless of whether we first
		// had to reallocate our memory.  So now check the return result
		if(uret != ERROR_SUCCESS)
		{
			// No idea why it didn't succeed - just ignore and return
			free(adpaddresses);
			return(devlist);
		}
		
		// Otherwise, go ahead and try to get the friendly names of the adapters, matching up based on adapter index.
		for(i=0; i<count; i++)
		{
			adpaddresses_loop=adpaddresses;
			while(adpaddresses_loop)
			{
				if(adpaddresses_loop->IfIndex == devlist->devlist[i].index)
				{
					// Copy over the unicode string into our ansi string
					// First, get the required buffer size for the entire string (including terminating NULL)
					len=WideCharToMultiByte(CP_ACP, 0, adpaddresses_loop->FriendlyName, -1, 0, 0, 0, 0);
					if(len<=1)
					{
						devlist->devlist[i].friendly[0]=0; // Null terminate empty string and quit
						break;
					}
					else if(len>sizeof(devlist->devlist[0].friendly))
						len=sizeof(devlist->devlist[0].friendly)-1;
					else
						len--; // Don't count NULL byte for now
					WideCharToMultiByte(CP_ACP, 0, adpaddresses_loop->FriendlyName, len, devlist->devlist[i].friendly, len+1, 0, 0);
					devlist->devlist[i].friendly[len]=0; // NULL terminate
					
					break; // All done, move on.
				}
				 
				adpaddresses_loop=adpaddresses_loop->Next;
			}
		}
		
		// We're now done with the adpaddresses memory
		free(adpaddresses);
	}
	
	
	return(devlist);

plugsysdevlist_err1:
	free(adpinfo);
	if(result)
		*result=myerr;
	return(0);
}

void eth32cfg_iphelper_interface_list_free(eth32cfgiflist handle)
{
	if(handle)
		free(handle);
}

int eth32cfg_iphelper_interface_address(eth32cfgiflist handle, int index, eth32cfg_ip_t *ip, eth32cfg_ip_t *netmask)
{
	devlist_t *devlist;

	if(!handle)
		return(ETH_INVALID_HANDLE);
	
	devlist = handle;
	
	if(index < 0 || (unsigned int)index >= devlist->count)
		return(ETH_INVALID_INDEX);
	
	memcpy(ip, &(devlist->devlist[index].ip), sizeof(eth32cfg_ip_t));
	memcpy(netmask, &(devlist->devlist[index].netmask), sizeof(eth32cfg_ip_t));
	
	return(0);
}

int eth32cfg_iphelper_interface_type(eth32cfgiflist handle, int index, int *type)
{
	devlist_t *devlist;
	
	if(!handle)
		return(ETH_INVALID_HANDLE);
	
	devlist = handle;
	
	if((unsigned int)index >= (devlist->count))
		return(ETH_INVALID_INDEX);
	
	*type=devlist->devlist[index].type;
	
	return(0);
}

int eth32cfg_iphelper_interface_name(eth32cfgiflist handle, int index, int nametype, char *name, int *length)
{
	// Retrieves the specified type of name of the specified interface index.
	// The length of the name buffer should be pointed to by the length parameter.
	// If that buffer size is not adequate, the required size will be written to *length.
	devlist_t *devlist;
	char *chosen;
	int len;
	
	if(!handle)
		return(ETH_INVALID_HANDLE);
	
	devlist = handle;
	
	if((unsigned int)index >= devlist->count)
		return(ETH_INVALID_INDEX);
	
	switch(nametype)
	{
		case ETH32CFG_IFACENAME_STANDARD:
			chosen=devlist->devlist[index].name;
			break;
		case ETH32CFG_IFACENAME_FRIENDLY:
			chosen=devlist->devlist[index].friendly;
			break;
		case ETH32CFG_IFACENAME_DESCRIPTION:
			chosen=devlist->devlist[index].description;
			break;
		default:
			return(ETH_NOT_SUPPORTED);
	}
	
	len=(int)strlen(chosen);
	
	if(*length < len+1 )
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


void eth32cfg_iphelper_unload()
{
	// This is all we need to free, since any handles returned by eth32cfg_iphelper_interface_list need
	// to be freed by the user prior to unloading the library
	if(hiphelper)
		FreeLibrary(hiphelper);
	hiphelper=0;
	
}



#endif
