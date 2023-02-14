/* Winford Engineering ETH32 API
 * Copyright 2005 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */

#ifndef devtable_h
#define devtable_h
/* This module allows us to keep a running list of the devices 
 * that we have open.  The main purpose for this is that if this
 * DLL is dynamically unloaded (as is the case during VB6 development)
 * then we can automatically close all of our devices and free resources.
 */
#include "eth32_internal.h"

void eth32_devtable_init();
void eth32_devtable_cleanup();
void eth32_devtable_add(eth32_data *data);
void eth32_devtable_remove(eth32_data *data);

#endif
