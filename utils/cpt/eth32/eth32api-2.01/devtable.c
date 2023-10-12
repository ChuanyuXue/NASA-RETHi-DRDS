/* Winford Engineering ETH32 API
 * Copyright 2005 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */

 /* This module allows us to keep a running list of the devices 
 * that we have open.  The main purpose for this is that if this
 * DLL is dynamically unloaded (as is the case during VB6 development)
 * then we can automatically close all of our devices and free resources.
 */

#include "eth32_internal.h"
#include "devtable.h"
#include "dbllist.h"


static dbll_base *eth32_devtable=NULL;

typedef struct
{
	dbll_header header;
	eth32_data *data;
} devtable_t;


void eth32_devtable_init()
{
	eth32_devtable = dbll_new();
}

void eth32_devtable_add(eth32_data *data)
{
	devtable_t *node;
	
	if(!eth32_devtable)
		return;

	node=dbll_append(eth32_devtable, sizeof(devtable_t));
	node->data=data;
}

void eth32_devtable_remove(eth32_data *data)
{
	devtable_t *node;

	if(!eth32_devtable)
		return;

	node=eth32_devtable->head;
	while(node)
	{
		if(node->data == data)
		{
			dbll_remove_node(eth32_devtable, node);
			break;
		}
		
		node=node->header.next;
	}
}


void eth32_devtable_cleanup(int mode)
{
	/* This function cycles through the device table and removes any
	 * device entries that are still present.
	 * 
	 * mode: 0 - normal mode.  Do a full device close operation
	 *       1 - free resources - free any allocated memory and close
	 *           the socket, but don't clean up any mutexes, etc.
	 *           This is useful for use in a child process of a fork()
	 */
	
	devtable_t *node;

	if(!eth32_devtable)
		return;

	while( (node=eth32_devtable->head) )
	{
		switch(mode)
		{
			case 0:
				// Force the device to close without waiting around
				if(eth32_close_int(node->data, 1))
				{
					// There was an error closing the board - We have to close
					// anyways, so just hope for the best and remove it from
					// our device table.
					dbll_remove_node(eth32_devtable, node);
				}
				
				// Otherwise, the close was successfull, and the
				// device table node HAS ALREADY BEEN REMOVED!!
				// An attempt to remove it again here would lead to 
				// serious memory corruption.
				break;
			case 1:
				// First close the socket
				eth32_socket_close(node->data->socket);

				
				// This removes it from the device table
				eth32_free_data(node->data);
				break;
		}
	}	
	
	dbll_destroy_list(eth32_devtable);
	eth32_devtable=NULL;
}

