/* Winford Engineering ETH32 API
 * Copyright 2005 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */

// Support functionality for the ETH32 API.  These functions
// are not publicly defined or called by the end user.

#include "eth32_internal.h"

// Define the incoming command bytes that represent an event.
// These will be handled differently by the readthread
static const unsigned char event_commands[] = {EVT_DIGI, EVT_ANLG, EVT_HEART, EVT_COUNT};

#ifdef LINUX
void* eth32_readthread(void* arg)
#endif
#ifdef WINDOWS
//DWORD WINAPI eth32_readthread(void* arg)
unsigned __stdcall eth32_readthread(void *arg)
#endif
{
	eth32_data *data = (eth32_data*)arg;
	unsigned char buf[CMDLEN];
	int count; // Number of bytes we have in buf
	int retval;
	struct timeval tout;
	fd_set fs;
	fd_set testfs;
	eth32_socket max;
	int error=0;


#ifdef LINUX
	sigset_t mask;
	sigset_t oldmask;

	/* set signal handling mask to block all signals */
	sigfillset(&mask);
	pthread_sigmask(SIG_BLOCK, &mask, &oldmask);


	/* Set cancellation to be enabled */
	pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);
	// Asynchronous cancellation can cause trouble and many people
	// say to never, never use it.
	//pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, NULL);

#endif
	
	// Prepare our file descriptor sets for select()
	FD_ZERO(&fs);
	FD_SET(data->socket, &fs);
	max=data->socket+1;
	count=0;
	while( data->quitflag == 0 )/* master loop to keep everything going */
	{
		
		// Use select to wait for incoming data availability
		// with a timeout.  This way, we can periodically check
		// the quitflag to see if we're supposed to exit.
		// Set the FDset and timeout each time
		// Use a timeout of 1/10 second, which is nice and long in terms
		// of a computer, but not so long that most humans would notice
		// a slight delay in closing things down.
		testfs=fs;
		tout.tv_sec = 0;
		tout.tv_usec = 100000; // microseconds
		
		// NOTE: Windows ignores the first parameter and passing in max causes a warning on x64 platform,
		// so just pass in zero on Windows platforms.
#ifdef WINDOWS			
		if(select(0, &testfs, NULL, NULL, &tout)>0)
#else
		if(select(max, &testfs, NULL, NULL, &tout)>0)
#endif
		{
			// We have input waiting - read it.
			retval=recv(data->socket, (char *)buf+count, CMDLEN-count, 0);
			if(retval>0)
				count += retval;
			else if(retval==0) // Socket has been disconnected
			{
				error=ETH_NETWORK_ERROR;
				break;
			}
			else
			{
				// Negative return value - fetch the actual error
#ifdef LINUX
				if(errno==EINTR)
#endif
#ifdef WINDOWS
				if(WSAGetLastError()==WSAEINTR)
#endif
					continue; // if the call was just interrupted, don't exit the thread over that
				else
				{
					// Otherwise, quit the thread and indicate why.
					error=ETH_NETWORK_ERROR;
					break;
				}
			}
		}
		if(count==CMDLEN)
		{
			// We have a full packet.  Have it processed.
			eth32_process_incoming(data, buf);
			
			count=0; // Reset our buffer
		}
	}
	
	/* if we're here, then quitflag has been set or we're exiting on error */
	wth_event_prewait(&(data->doneflags_event));
	// Show why we're exiting
	if(error)
		data->readthread_done = error;
	else
		data->readthread_done = 1; /* show that we're exiting */
	wth_event_broadcast(&(data->doneflags_event));
	wth_event_release(&(data->doneflags_event));
	
	/* Also signal the evt_info_event since anybody waiting for event
	 * information should know that no more will be forthcoming.
	 */
	wth_event_prewait(&(data->evt_info_event));
	wth_event_broadcast(&(data->evt_info_event));
	wth_event_release(&(data->evt_info_event));
	
	/* Also signal anybody waiting for replies for queries */
	wth_event_prewait(&(data->replies_event));
	wth_event_broadcast(&(data->replies_event));
	wth_event_release(&(data->replies_event));
	
	return(0);
}


#ifdef LINUX
void* eth32_eventthread(void *arg)
#endif
#ifdef WINDOWS
//DWORD WINAPI eth32_eventthread(void *arg)
unsigned __stdcall eth32_eventthread(void *arg)
#endif
{
	eth32_data *handle = (eth32_data*)arg;
	evtqueuenode_t *node;
	eth32_event event;

#ifdef LINUX	
	sigset_t mask;
	sigset_t oldmask;

	/* set signal handling mask to block all signals */
	sigfillset(&mask);
	pthread_sigmask(SIG_BLOCK, &mask, &oldmask);

	/* Set cancellation to be enabled */
	pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL);
	// see above
	// pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, NULL);

#endif

	
	wth_event_prewait( &(handle->evt_info_event) );


	while(1) /* master loop to keep everything going */
	{
		if(handle->event_quitflag)
		{
			break;
		}
		else if(handle->evt_callback_queue->head)
		{
			// We currently have the predicate mutex for evt_info_event locked.
			node=handle->evt_callback_queue->head;
			event=node->event;
			
			// Now we have the information from the queue, so remove that node.
			dbll_remove_node(handle->evt_callback_queue, node);
			
			// Now we need to call the user's callback.  This might take
			// a while, so we need to release our predicate mutex and be
			// sure to grab it right back afterwards
			wth_event_release( &(handle->evt_info_event) );
			// Make the call.
			handle->event_handler.eventfn(handle, &event, handle->event_handler.extra);
			wth_event_prewait( &(handle->evt_info_event) );
		}
		else // Only wait if we've determined that we have nothing to do.
		{
			wth_event_wait(&(handle->evt_info_event), 0);
		}
	}

	wth_event_release( &(handle->evt_info_event) );


	/* if we're here, then quitflag has been set or we're exiting on error */
	wth_event_prewait(&(handle->doneflags_event));
	handle->eventthread_done = 1; /* show that we're exiting */
	wth_event_broadcast(&(handle->doneflags_event));
	wth_event_release(&(handle->doneflags_event));

	
	return(0);
}


int eth32_check(eth32_data *data, int skipreadthread)
{
	// This function is intended to be called near the top of any
	// API function that is called by the user.  It does some
	// basic sanity checks to see if everything is OK with the
	// device structure, etc.
	// If skipreadthread is nonzero, it doesn't check to make sure the reading
	// thread is still alive.  This is useful on functions that can be used
	// after a network error, etc, to help shut the object instance down
	// cleanly.
	// If all is OK, it returns 0.  Otherwise, it returns an
	// error code that should be passed back to the user.
	
	if(!data)
		return(ETH_INVALID_HANDLE);
	
	// If the reading thread has quit, it must be due to a network
	// error that disconnected the socket.  Report it as such here.
	if(skipreadthread==0 && data->readthread_done)
	{
		// If a specific error code (negative) was stored by the exiting
		// thread, return that.  Otherwise, return a network error.
		if(data->readthread_done<0)
			return(data->readthread_done);
		else
			return(ETH_NETWORK_ERROR);
	}
	
	if(data->closing)
		return(ETH_CLOSING);
		
	return(0);
}

int eth32_refcount(eth32_data *data, int change)
{
	// Call this function to add to or subtract from the internal 
	// reference count for this object instance.  The reference count
	// indicates how many functions are currently being called by users.
	// This function returns zero on success or nonzero on error.
	// When you're trying to increase the reference count (before executing 
	// a publicly accessible function), you MUST pay attention to the return
	// value.  If it returns nonzero, you must exit the function with an 
	// error immediately.
	int retval;
	
	wth_event_prewait(&(data->refcount_event));
	// Now that we have the event locked, make sure that closing isn't flagged.
	if(data->closing)
	{
		retval=ETH_CLOSING;
		goto release;
	}
	
	data->refcount += change;
	
	if(change<0)
	{
		wth_event_broadcast(&(data->refcount_event));
	}
	
	retval=0;
release:
	wth_event_release(&(data->refcount_event));
	return(retval);
}


void eth32_process_incoming(eth32_data *data, unsigned char *buf)
{
	/* Process an incoming packet from the ETH32.  At this point, we don't
	 * know if it's an event or a reply to a query of ours.
	 * The buf must be at least CMDLEN long.
	 */
	int i;
	queryreplynode_t *node;
	queryreplynode_t *backtrack;
	queryreplynode_t *temp;
	//time_t now;
	//time_t expire;
	int skipped;
	
	// See if this packet is an event
	for(i=0; i<sizeof(event_commands)/sizeof(*event_commands); i++)
	{
		if(buf[0]==event_commands[i])
		{
			eth32_process_event(data, buf);
			return;
		}
	}
	
	// Otherwise, if we're here, it's a regular reply that should be
	// queued up and we need to notify anybody waiting.
	
	// Lock the predicate mutex to gain access to the list
	wth_event_prewait(&(data->replies_event));
	
	
	// OK, now store this data 
	node=data->queries_replies->head;
	skipped=0;
	while(node)
	{
		// Find the first un-responded node.
		if((node->flags & QRFLAG_RECEIVED)==0)
		{
			if(memcmp(node->reply, buf, node->matchbytes)==0)
			{
				// We found our node
				if(skipped)
				{
					// If we skipped some nodes, then backtrack and take care of them.
					backtrack=node->header.prev;
					while(backtrack)
					{
						temp = backtrack->header.prev;
						
						// If this is an unreceived node and it has been abandoned, then we can purge it.
						if((backtrack->flags & QRFLAG_RECEIVED)==0 && (backtrack->flags & QRFLAG_ABANDONED) )
						{
							dbll_remove_node(data->queries_replies, backtrack);
						}
							
						backtrack=temp;
					}
				
				}
				break;
			}
			else
			{
				// Odd situation.  This is not the response we are expecting next.  For now, just make a note of it and move on.
				if(node->flags & QRFLAG_ABANDONED)
					skipped=1;
			}
		}

		node=node->header.next;
	}
	// node may be NULL if we hit the end of the list.

	if(node) // Found where to store it.
	{
		if(node->flags & QRFLAG_ABANDONED)
		{
			// Node has been abandoned.  Since we have the reply in now, we can go ahead and delete it.
			dbll_remove_node(data->queries_replies, node);
		
		}
		else
		{
			memcpy(node->reply, buf, CMDLEN); // Copy in the data we were given
			node->flags |= QRFLAG_RECEIVED;

			// Signal any waiters
			wth_event_broadcast(&(data->replies_event));
		}
	}
	// Otherwise, if we never found a node to store this, then it's unexpected data.  Don't delete any skipped nodes.
	
	// Always release the lock regardless
	wth_event_release(&(data->replies_event));
}

void eth32_process_event(eth32_data *handle, unsigned char *buf)
{
	/* Process an event packet that was received */
	/* The buf must be at least CMDLEN long. */
	int i;
	int index;
	unsigned char newval;
	unsigned char changed;
	eth32_event event={0};
	
	// Our actions depend on the type of event packet received
	switch(buf[0])
	{
		case EVT_DIGI:
			event.type=EVENT_DIGITAL;
			// Pick out the port this relates to
			event.port=buf[1];
			// If port is out of range, ignore it.
			if(event.port<0 || event.port>=NUM_DIGPORTS)
				return;
			newval=buf[2];
			changed=buf[3];
			
			// First, check if the user wants port events for this port
			if(handle->evt_ports[event.port].enabled)
			{
				event.id=handle->evt_ports[event.port].id;
				event.bit=-1; // indicates port event
				event.value=newval; // new value of the port
				// Previous value is the eXclusive OR (^) of the new value
				// and the bits that changed.
				event.prev_value=newval ^ changed;
				event.direction = (event.value > event.prev_value) ? 1 : -1;
				eth32_dispatch_event(handle, &event);
			}
			
			// Now check if any bit events are enabled for the changed bits.
			for(i=0; i<8; i++)
			{
				// If bit changed and user wants the event, then go ahead
				if( (changed & (1 << i)) && handle->evt_bit[event.port][i].enabled)
				{
					event.id=handle->evt_bit[event.port][i].id;
					event.bit=i;
					event.value=(newval & (1 << i)) ? 1 : 0;
					event.prev_value=(event.value) ? 0 : 1;
					event.direction=(event.value) ? 1 : -1;
					eth32_dispatch_event(handle, &event);
				}
			}
		
			break;
		case EVT_ANLG:
			// Pick out the bank and channel
			event.port=(buf[1] & 0x08) ? 1 : 0; // bank
			event.bit=buf[1] & 0x07; // channel
			
			if(event.port==0)
				index=EVT_INDEX_ANALOG_0;
			else
				index=EVT_INDEX_ANALOG_1;
			
			if(handle->evt_bit[index][event.bit].enabled)
			{
				event.id=handle->evt_bit[index][event.bit].id;
				event.type=EVENT_ANALOG;
				event.prev_value=(buf[2]<<2) | (buf[4] & 0x03);
				event.value=(buf[3]<<2) | (buf[4] >> 6);
				event.direction=(buf[1] & 0x80) ? 1 : -1;
				eth32_dispatch_event(handle, &event);
			}
			
			break;
			
		case EVT_HEART:
			if(handle->evt_heartbeat.enabled)
			{
				event.id=handle->evt_heartbeat.id;
				event.type=EVENT_HEARTBEAT;
				eth32_dispatch_event(handle, &event);
			}
			break;
			
		case EVT_COUNT:
			// Pull out which counter it is and store that in port
			event.port=buf[1];
			// If counter number is out of range, ignore it.
			if(event.port >= NUM_COUNTERS)
				return;
			
			// Figure out which type of event this is
			if(buf[2]==0)
			{
				event.type=EVENT_COUNTER_ROLLOVER;
				index=EVT_INDEX_COUNTER_ROLLOVER;
			}
			else if(buf[2]==1)
			{
				event.type=EVENT_COUNTER_THRESHOLD;
				index=EVT_INDEX_COUNTER_EVENT;
			}
			else
				return;
			
			if(handle->evt_bit[index][event.port].enabled)
			{
				event.id=handle->evt_bit[index][event.port].id;
				event.value=buf[3];
				eth32_dispatch_event(handle, &event);
			}
			break;
	}

}

void eth32_dispatch_event(eth32_data *handle, eth32_event *event)
{
	/* This function takes a structure with event firing information
	 * and sends it via the method the user has configured and/or
	 * stores it in the queue.
	 * This function should only be called when it has already been
	 * determined that the user actually does want the event information
	 * for this particular event.
	 */
	evtqueuenode_t *node;
	int added=0; // 1 if we added a node to either event queue

	// Obtain the predicate mutex to protect access to the event
	// queue and the event_handler information.
	wth_event_prewait(&(handle->evt_info_event));
	
	// First, add this event to the user's queue if it is enabled.  This way,
	// the message will be stored BEFORE we send out any message saying
	// that it's available.
	if(handle->evt_queue_size)
	{
		// If we're configured to discard old events when the queue is
		// full, then go ahead and do that if necessary.
		if(handle->evt_queue_fullqueue == QUEUE_DISCARD_OLD)
		{
			// Remove elements from the head of the list if it is necessary
			// to make sure the list size is NO MORE THAN one less than the
			// allowable size.
			while(handle->evt_queue->count >= handle->evt_queue_size)
			{
				dbll_remove_node(handle->evt_queue, handle->evt_queue->head);
			}
		}
		
		// As long as we have room in the queue, go ahead and add it.
		// Otherwise, if we are configured with QUEUE_DISCARD_NEW and
		// the queue is indeed full, then we simply don't queue this up
		// and it gets lost
		if(handle->evt_queue->count < handle->evt_queue_size)
		{
			node=dbll_append(handle->evt_queue, sizeof(evtqueuenode_t));
			node->event=*event;
			added=1;
		}
	}

	switch(handle->event_handler.type)
	{
		case HANDLER_CALLBACK:
			// Append the event data to the queue for the event thread.
			// We already have the predicate mutex from above.
			
			// If we're configured to discard old events when the queue is
			// full, then go ahead and do that if necessary.
			if(handle->event_handler.fullqueue == QUEUE_DISCARD_OLD)
			{
				// Remove elements from the head
				while(handle->evt_callback_queue->count >= handle->event_handler.maxqueue)
				{
					dbll_remove_node(handle->evt_callback_queue, handle->evt_callback_queue->head);
				}
			}

			// As long as we have room in the queue, go ahead and add it.
			// Otherwise, if we are configured with QUEUE_DISCARD_NEW and
			// the queue is indeed full, then we simply don't queue this up
			// and it gets lost
			if(handle->evt_callback_queue->count < handle->event_handler.maxqueue)
			{
				node=dbll_append(handle->evt_callback_queue, sizeof(evtqueuenode_t));
				node->event=*event;
				added=1;
			}
			break;
#ifdef WINDOWS
		case HANDLER_MESSAGE:
			PostMessage(handle->event_handler.window,
			            handle->event_handler.msgid,
			            handle->event_handler.wparam,
			            handle->event_handler.lparam);
			break;
#endif
	}
	
	// If we added a node to the event queue, then broadcast 
	// to all waiters on the event.
	if(added)
		wth_event_broadcast(&(handle->evt_info_event));

	wth_event_release(&(handle->evt_info_event));
}

int eth32_create_eventthread(eth32_data *handle)
{
	/* This function creates the event handler thread for use in callback
	 * event notification.  This function assumes that no event thread
	 * has already been created.
	 * 
	 * This function returns 0 on success or a negative error code
	 * on failure.
	 */

	// Since we can assume that there is currently no event thread running,
	// we can safely clear out the queue without locking the event.
	while(handle->evt_callback_queue->head)
		dbll_remove_node(handle->evt_callback_queue, handle->evt_callback_queue->head);

	/* Just before creating the thread, make sure that the quitflag
	 * and doneflag for the thread are not set.
	 */
	handle->eventthread_done=0;
	handle->event_quitflag=0;


	if( wth_thread_create(eth32_eventthread, handle, &(handle->eventthread_handle)) )
	{
		return(ETH_ETHREAD_ERROR);
	}

	return(0);
}

void eth32_close_eventthread(eth32_data *handle, int force)
{
	/* This function closes the event thread for the API
	 * 
	 * This function should only be called when the event thread is actually
	 * present, otherwise it will hang waiting for a response back.
	 * 
	 * The exception is that if mode is nonzero, no waiting will be done
	 * for the thread.  This function will only attempt to close it, but
	 * will not wait for confirmation.
	 * 
	 * This function attempts to close the event thread regardless of
	 * conditions, so it does not return a value.
	 */


	// See what method to use to shut down the thread
	if( force == 0 )
	{
		/* Signal and Wait for the thread to exit - this is the normal behavior */
		wth_event_prewait( &(handle->evt_info_event) );
	
		handle->event_quitflag=1; // set the quit flag for the event thread.  

		wth_event_broadcast( &(handle->evt_info_event) );
		wth_event_release( &(handle->evt_info_event) );
	
		wth_event_prewait(&(handle->doneflags_event));
		while( handle->eventthread_done == 0 ) /* wait until the event thread has quit */
		{
			wth_event_wait(&(handle->doneflags_event), 0);
		}
		wth_event_release(&(handle->doneflags_event));
	}
	else
	{
		// Only do this if it looks like the thread hasn't already exited
		if(handle->eventthread_done == 0)
		{

			wth_thread_terminate(handle->eventthread_handle);

			// Indicate that the thread is now gone
			handle->eventthread_done=1;
		}
	}
	// In any case, wait for the thread to terminate and close the handle
	wth_thread_wait(handle->eventthread_handle);
	wth_thread_handle_close(handle->eventthread_handle);
	
}

int eth32_set_event_handler_int(eth32_data *handle, eth32_handler *handler, int force)
{
	/* Set the event handler mechanism.
	 * As a convenience, if handler is passed in as NULL, it will be treated
	 * as setting the handler type to HANDLER_NONE.
	 * force:
	 *  0 - Normal behavior
	 *  1 - Don't wait for any threads during cleanup, etc.
	 */
	int retval=0;
	eth32_handler nohandler={0};
	
	if(!handler)
	{
		handler=&nohandler;
	}

	// Do some validation.
	if(handler->type < HANDLER_NONE || handler->type > HANDLER_MESSAGE)
		return(ETH_INVALID_OTHER);
	if(handler->type==HANDLER_CALLBACK)
	{
		if(!handler->eventfn)
			return(ETH_INVALID_POINTER);
		if(handler->maxqueue<CALLBACK_MIN)
			return(ETH_INVALID_OTHER);
		if(handler->fullqueue<QUEUE_DISCARD_NEW || handler->fullqueue>QUEUE_DISCARD_OLD)
			return(ETH_INVALID_OTHER);
	}
	if(handler->type==HANDLER_MESSAGE && !handler->window)
		return(ETH_INVALID_OTHER);



	// Protect against simultaneous calls to this function
	wth_mutex_wait(&(handle->event_handler_change_mutex), 0);


	// If the handler type specified is the same as before, there's
	// no significant work to be done.  Simply let the code below copy 
	// over the information given so if there are new message ID's, extra 
	// values, etc, they will be copied
	if(handler->type==handle->event_handler.type)
		retval=0;
	else
	{
		// Otherwise, we have a change.  First clean up whatever we had before.
		switch(handle->event_handler.type)
		{
			case HANDLER_CALLBACK:
				// Need to shut down event thread
				eth32_close_eventthread(handle, force);

				break;
			// None of the other types need any cleanup.
		}
		
		// Now, put the new method into effect.
		switch(handler->type)
		{
			case HANDLER_CALLBACK:
				retval=eth32_create_eventthread(handle);
				break;
			// None of the other types require any action besides
			// copying the new information, which is handled below.
		}
	}

	// If we're in force mode, don't bother with locks, etc, since
	// we have no idea what state we're in and we might deadlock
	if(force==0)
		wth_event_prewait(&(handle->evt_info_event));

	if(retval==0)
	{
		// Evidently no errors encountered.
		// copy over the information specified.
		handle->event_handler=*handler;
	}
	else
	{
		// We assume that the shutdown operations worked, so we're
		// left with no event handler.  Update our data to reflect that.
		handle->event_handler.type=HANDLER_NONE;
	}
	
	if(force==0)
		wth_event_release(&(handle->evt_info_event));



	wth_mutex_release(&(handle->event_handler_change_mutex));

	return(retval);
}

int eth32_write_data(eth32_data *data, unsigned char *buf, int len, unsigned int *timeout)
{
	/* Send out a command block over the network to the device.
	 * If timeout is not NULL, it specifies a timeout in milliseconds.
	 * When the function returns, it writes back the amount of time 
	 * remaining in the timeout.
	 * Return value:
	 *   If greater than 0, the number of bytes that were written
	 *   Otherwise, a negative error code.
	 */
	
	int retval=ETH_GENERAL_ERROR;
	int res, res2;
	int timeleft;
	struct timeval tout;
	struct timeval *ptout;
	fd_set fs;
	eth32_socket max;
	int ttemp;
	int err;
	WINT64 start=0;
	
	// Since we're getting ready to do a network write, do a status check.
	// We may eventually remove this as long as we do a check on each and
	// every public API function, but it doesn't hurt to check twice.
	if( (err=eth32_check(data, 0)) )
		return(err);
	
	// Set ptout to be NULL if timeout is NULL, otherwise point to tout
	if(timeout)
	{
		start=wth_milliseconds();
		ttemp=*timeout;
		tout.tv_sec = ttemp/1000;
		tout.tv_usec = (ttemp%1000)*1000;
		
		ptout=&tout;
	}
	else
		ptout=NULL;

	// Prepare our file descriptor sets for select()
	FD_ZERO(&fs);
	FD_SET(data->socket, &fs);
	max=data->socket+1;

	// NOTE: Windows ignores the first parameter and passing in max causes a warning on x64 platform,
	// so just pass in zero on Windows platforms.
#ifdef WINDOWS			
	res=select(0, NULL, &fs, NULL, ptout);
#else
	res=select(max, NULL, &fs, NULL, ptout);
#endif
	if(res>0)
	{
		res2=send(data->socket, (char *)buf, len, 0);
		// Check for errors on writing...
		if(res2>0)
			retval=res2;
		else
		{
#ifdef LINUX
			if(errno==EINTR)
#endif
#ifdef WINDOWS
			if(WSAGetLastError()==WSAEINTR)
#endif
				retval=ETH_NETWORK_INTR;
			else
				retval=ETH_NETWORK_ERROR;
		}
	}
	else if(res==0)
	{
		*timeout=0;
		return(ETH_TIMEOUT);
	}
	else
		retval=ETH_NETWORK_ERROR;		
	
	// If timeout was specified, calculate how much time is remaining
	// and write it back to the given variable.
	if(timeout)
	{
		timeleft=*timeout-(int)(wth_milliseconds()-start);
		if(timeleft<0)
			timeleft=0;
		*timeout=timeleft;
	}
	
	return(retval);
}

int eth32_query_reply(eth32_data *data, unsigned char *qbuf, unsigned char *rbuf, unsigned int extracompare, unsigned int *timeout)
{
	/* Handle the standard query & reply process.  
	 * Sends the query in qbuf out and places the response in rbuf.
	 * This function assumes:
	 *   * qbuf points to buffer of at least CMDLEN long
	 *   * rbuf points to buffer of at least CMDLEN long
	 *   * qbuf[1] should contain a sequence number that THIS function should fill in.
	 *   * the device will reply to the given command, with the 
	 *     first two bytes the same as whatever we send, plus extracompare
	 *     bytes also being the same.
	 *
	 * If a timeout is given and the function does NOT time out, the remaining
	 * time before timeout would have occurred is stored back into *timeout.
	 * Returns 0 on success, negative error code on error.
	 */
	int res;
	int check;
	int retval=0;
	queryreplynode_t *node=NULL;
	
	
	// Acquire the mutex and assign a sequence number.
	if(wth_mutex_wait(&(data->sequence_mutex), timeout)>0)
	{
		// Timeout
		return(ETH_TIMEOUT);
	}
	// Otherwise we have the mutex
	qbuf[1]=data->sequence++;
	
	// While we still have the mutex, write out the data and add our node to the list.  Doing this all within the mutex
	// ensures that the order on the list matches what we wrote out on the socket.  This is the only location in code
	// where we use the sequence_mutex and we always aquire it and the replies_event in the same order, so there is no 
	// deadlock concern.

	// Send the query
	if( (res=eth32_write_data(data, qbuf, CMDLEN, timeout))<0 )
	{
		// Error - data not written.  Be sure to still release the mutex.
		wth_mutex_release(&(data->sequence_mutex));
		return(res);
	}

	// Now add our node to the list.  Acquire the lock in order to do that.
	wth_event_prewait(&(data->replies_event));
	// Now that we've locked the list, we know we'll get the node in the right place.  So go ahead and release the sequence mutex.
	wth_mutex_release(&(data->sequence_mutex));
	
	node=dbll_append(data->queries_replies, sizeof(queryreplynode_t));
	node->flags=0;
	node->matchbytes=2+extracompare;
	memcpy(node->reply, qbuf, node->matchbytes);
	
	// Now wait for arrival of our data.  The wth_event_wait call in the loop below
	// releases the lock on the list while waiting.
		
	// Keep waiting while we DON'T have a response and while the
	// reading thread is still operating.
	// It is possible that the wth_event_wait call could exit with a timeout, but by the time 
	// we have the lock on the predicate, the node has been updated with a response.  
	check=0;
	for(;;)
	{
		// Wait for signal that some data has arrived (may not be ours)
		res=wth_event_wait(&(data->replies_event), timeout);
		
		// TODO - Remove:
		//printf("List count: %d\n", data->queries_replies->count);
		
		if(res == -1)
			break; // If there was a waiting error, we might not even have our predicate mutex, so just go ahead and exit.
		
		if((node->flags) & QRFLAG_RECEIVED)
		{
			// Our reply has arrived.
			res=0; // Even if we timed out above, force a successful response because we have our data.
			check=0;
			break;
		}

		if(res) // timeout during wait
			break;
		
		// If the read thread has exited, there's no sense for us to wait any more.
		if( (check=eth32_check(data, 0)) )
			break;
	}
	

	/* handle any error */
	if(res || check)
	{
		if(res)
		{
			if(res == 1)
				retval=ETH_TIMEOUT;
			else
				retval=ETH_THREAD_ERROR;
		}
		else // nonzero check.  Looks like readthread has quit
		{
			retval=check;
		}
		// Mark our node as abandoned.
		node->flags |= QRFLAG_ABANDONED;
		//goto exit_label;	
	}
	else
	{
		// If we're here, then we must have a valid reply
		// Copy the data out and remove it from the list.
		memcpy(rbuf, node->reply, CMDLEN);
		dbll_remove_node(data->queries_replies, node);
		retval=0;
	}
	
//exit_label:
	wth_event_release(&(data->replies_event));
	return(retval);
}

void eth32_free_data(eth32_data *handle)
{
	/* This function frees any allocated data for the device, 
	 * INCLUDING the device structure itself, so when this
	 * function returns, handle should no longer be used.
	 * This does nothing but free memory.
	 */

	dbll_destroy_list(handle->queries_replies);
	dbll_destroy_list(handle->evt_queue);
	dbll_destroy_list(handle->evt_callback_queue);

	eth32_devtable_remove(handle);

	free(handle);

}

int eth32_close_int(eth32_data *handle, int force)
{
	/* This function is the real guts of any close operation.  It does all the 
	 * necessary cleanup and thread termination, etc.
	 * It has two different modes:
	 *  If force is zero, it operates normally, attempting to close and clean up
	    as gracefully as possible.
	 *  If force is nonzero, it expedites the process, forcibly terminating
	    any threads, etc.
	 * The force mode is necessary for DLL unloading, since during DLL
	 * unload, the other threads seem to be in a disabled state, at least on Windows,
	 * so normal mode would hang around indefinitely waiting for response from the 
	 * other threads, and never get it.
	 */
	unsigned char junk[100];
	
	if(!handle)
		return(ETH_INVALID_HANDLE);


	// Just plow through everything without looking back at this point.
	// Right now, there isn't a great deal that could go wrong and if something
	// does, it's likely to be something where it would hang indefinitely or
	// something that would fail again if tried again.
	
	// Indicate we're shutting down
	handle->closing=1;
	
	// Shut down any event handler that exists.  This closes the event thread if it was running
	eth32_set_event_handler_int(handle, NULL, force);

	// Set the event queue length to zero - this will cause any users who are waiting
	// on an event_dequeue to exit with an error.
	eth32_set_event_queue_config(handle, 0, 0);

	// Now, before we really start tearing things down, make sure there are no 
	// users with calls into this object.
	wth_event_prewait(&(handle->refcount_event));
	while(handle->refcount>0)
		wth_event_wait(&(handle->refcount_event), NULL);
	wth_event_release(&(handle->refcount_event));

	// Shut down the reading thread.
	if(force==0) // normal behavior
	{
		wth_event_prewait(&(handle->doneflags_event));
		handle->quitflag=1; // tell thread it should quit
		
		while(handle->readthread_done==0)
			wth_event_wait(&(handle->doneflags_event), 0);
		
		wth_event_release(&(handle->doneflags_event));
	}
	else
	{

		// Force a shutdown unless it looks like the thread is already gone
		if(handle->readthread_done==0)
		{
			wth_thread_terminate(handle->readthread_handle);
			// Indicate thread is now gone.
			handle->readthread_done=1;
		}
	}

	// In any case, wait until the thread is completely exited
	wth_thread_wait(handle->readthread_handle);

	// In any case, close our handle to the thread
	wth_thread_handle_close(handle->readthread_handle);
	
	
	// OK, the reading thread is now gone.  Now we need to clean up
	// everything else.
	
	//// First close down our socket
	// Don't do this any more because Windows won't allow you to drain
	// the receive buffer after you do a shutdown of receives.
	//eth32_socket_shutdown(handle->socket, 2);
	
	
	// Drain anything in the receive buffer - this helps some implementations
	// close down more cleanly
	while(eth32_socket_buffered(handle->socket))
	{
		recv(handle->socket, (char *)junk, sizeof(junk), 0);
	}
	
	// Finally, do the actual close
	eth32_socket_close(handle->socket);


	// From here, just take 'em down the line in the order they're defined
	// in the structure
	// NOTE that all the dbll lists are freed in the call to eth32_free_data below.
	wth_event_destroy(&(handle->refcount_event));
	wth_event_destroy(&(handle->doneflags_event));
	wth_event_destroy(&(handle->replies_event));
	wth_mutex_destroy(&(handle->timeout_mutex));
	wth_event_destroy(&(handle->evt_info_event));
	wth_mutex_destroy(&(handle->event_handler_change_mutex));
	wth_mutex_destroy(&(handle->sequence_mutex));
	
	
	// Finally, free memory that is allocated for the device, 
	// remove it from the device table, AND
	// free the device structure itself.
	eth32_free_data(handle);
	
	return(0);
}

