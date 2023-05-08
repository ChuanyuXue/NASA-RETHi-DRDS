/* Winford Engineering ETH32 API
 * Copyright 2005 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */

 // Double-linked list routines

#ifndef dbllist_h
#define dbllist_h

// Basic idea of usage: An application needing a linked
// list defines its own structure to hold the data for
// each list item (node), BEING SURE to begin the structure
// with the list header pointers as defined by the structure
// dbll_node.  The application then uses that custom structure
// type for all list operations, from making a new list to
// adding new items, to traversing the list.
// 
// Void pointers are used throughout these definitions for pointing
// to list elements, since using the dbll_node type would just result
// in a million compiler warnings unless each use was casted.
//
// Example of a good way to define and use an application-specific
// list item structure:
//  typedef struct
//  {
//      dbll_node header;
//      int mystuff1;
//      char myname[255];
//      int etc;
//  } customlist;
//  customlist *list;
//  list=dbll_new();
//  ...


// List node structures MUST BEGIN with this block
typedef struct
{
	void *prev;
	void *next;
} dbll_header;

// Base information for a list
typedef struct
{
	void *head; // Pointer to head node or NULL if empty
	void *tail; // Pointer to tail node or NULL if empty
	int count;  // Number of nodes in the list
} dbll_base;

dbll_base *dbll_new();
void *dbll_prepend(dbll_base *base, int datasize);
void *dbll_append(dbll_base *base, int datasize);
int dbll_remove_node(dbll_base *base, void *node);
int dbll_destroy_list(dbll_base *base);


#endif
