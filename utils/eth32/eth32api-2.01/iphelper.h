/* Winford Engineering ETH32 API
 * Copyright 2010 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */
// This code provides an interface to the items we need from the Windows IP Helper API

#ifndef iphelper_h
#define iphelper_h


int eth32cfg_iphelper_load();
eth32cfgiflist eth32cfg_iphelper_interface_list(int *numd, int *result);
void eth32cfg_iphelper_interface_list_free(void *handle);
int eth32cfg_iphelper_interface_address(void *handle, int index, eth32cfg_ip_t *ip, eth32cfg_ip_t *netmask);
int eth32cfg_iphelper_interface_type(void *handle, int index, int *type);
int eth32cfg_iphelper_interface_name(void *handle, int index, int nametype, char *name, int *length);

void eth32cfg_iphelper_unload();






#endif
