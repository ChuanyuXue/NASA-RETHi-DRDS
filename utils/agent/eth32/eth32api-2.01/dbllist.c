/* Winford Engineering ETH32 API
 * Copyright 2005 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */

// Double-linked list routines.  Used where the actual
// data to be stored should be included in the list structures
// and managed by the list management routines.

// Conditions to uphold:
// List base node:
//   * head points to first data item in list
//   * tail points to last data item in list
//   * If list is empty, head and tail are NULL
//   * count is accurate
// Front of list:
//   * First data node will have prev being NULL
// End of list:
//   * Last data node will have next being NULL


#include "eth32_internal.h"
#include "dbllist.h"
#include <malloc.h>


dbll_base *dbll_new()
{
	// Create a new double-linked list.
	// This will return a "node" with no data - only next
	// and prev pointers.  These will be updated to point
	// to the beginning and the end of the list, respectively.
	// Returns a pointer to the node on success, or NULL
	// on failure.
	
	dbll_base *retval;
	
	// Since there will be no data ever on this, just malloc
	// the actual needed size.

	retval=(dbll_base *)malloc(sizeof(dbll_base));

	if(retval)
	{
		retval->head = retval->tail = NULL;
		retval->count=0;
	}

	
	return(retval);
}

void *dbll_prepend(dbll_base *base, int size)
{
	// Prepend a new node on to the beginning of the list
	// size specifies the bytes needed for the ENTIRE
	// node structure, including both list pointers (dbll_node)
	// and any data you want to store.
	dbll_header *newnode;
	dbll_header *firstnode;

	if(!base)
		return(NULL);

	if(size<sizeof(dbll_header))
		return(NULL);
	
	newnode=(dbll_header *)malloc(size);
	
	if(!newnode)
		return(NULL);
	
	// Find node that used to be first.  Remember list may 
	// be empty.
	firstnode=base->head;
	
	newnode->prev=NULL; // we point back to nobody, since we're first
	newnode->next=firstnode; // we point forward to first (may be NULL)

	base->head=newnode;  // base points forward to us

	if(firstnode)  // list was NOT empty
		firstnode->prev=newnode; // first points back to us
	else           // list was empty
		base->tail=newnode; // head points back to us as the last item in list
	
	base->count++;
	
	return(newnode);	
}

void *dbll_append(dbll_base *base, int size)
{
	// Append a new node on to the beginning of the list
	// size specifies the bytes needed for the ENTIRE
	// node structure, including both list pointers (dbll_node)
	// and any data you want to store.

	dbll_header *newnode;
	dbll_header *lastnode;
	
	if(!base)
		return(NULL);
	
	if(size<sizeof(dbll_header))
		return(NULL);
	
	newnode=(dbll_header *)malloc(size);
	
	if(!newnode)
		return(NULL);

	// Find the node that used to be last.  Remember the
	// list may be empty.
	lastnode=base->tail;

	newnode->next=NULL; // We point forward to none
	newnode->prev=lastnode; // We point back to the last (may be NULL)

	base->tail=newnode; // Head points back to us
	
	if(lastnode) // list was NOT empty
		lastnode->next=newnode; // Last points forward to us
	else         // List was empty
		base->head=newnode;     // Head points forward to us
	
	base->count++;
	
	return(newnode);
}

int dbll_remove_node(dbll_base *base, void *vnode)
{
	// Remove a node from the list.
	// Returns 0 on success, or nonzero on error.
	

	// NOTE - If we ever want to sacrifice speed for safety 
	// (to protect against programmer's errors), we could 
	// do a check to ensure the specified node is truly
	// in the list before we haul off and blindly "remove" it.
	dbll_header *next;
	dbll_header *prev;
	dbll_header *node=vnode;

	
	if(!node || !base)
		return(1);
	
	next=node->next;
	prev=node->prev;
	
	if(next)
		next->prev=prev;
	else
	{ // We were the tail end node on the list
		// Update base to point back to whatever was before us.
		// If our prev is NULL, then we were also the first node
		// on the list, in other words, the ONLY node on the list.
		// In this case, we want our NULL prev assigned to head's
		// prev.  In any case, the assignment works out the same.
		base->tail=prev;
	}

	// Same thing for prev
	if(prev)
		prev->next=next;
	else
		base->head=next;
	
	base->count--;
		
	free(node);
	return(0);
}

int dbll_destroy_list(dbll_base *base)
{
	// Go through and free everything that is in the list.
	// After this call returns, the given head pointer
	// will not point to anything valid.
	// Returns 0 on success and nonzero on error.
	
	dbll_header *node;
	dbll_header *temp;
	
	if(!base)
		return(1);
	
	// Grab the head of the list, then free the base
	node=base->head;
	free(base);
	
	while(node)
	{
		temp=node->next;	
		free(node);
	
		node=temp;
	}
	
	
	return(0);
}


