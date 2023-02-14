/* Winford Engineering ETH32 API
 * Copyright 2005 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */


// Provides cross-platform thread creation/control and synchronization 
// methods.


/* NOTE:
 * To compile you MUST have either WINDOWS or LINUX #defined.
 */
#include "threads.h"

#ifdef LINUX
#include <sys/time.h>
#endif

WINT64 wth_milliseconds()
{
	/* This function returns some type of millisecond count.  Just
	 * what it is will vary by system, but whatever it is, it will
	 * be one more in a millisecond.
	 */
	WINT64 result;
	
#ifdef LINUX
	struct timeval tv;
	
	gettimeofday(&tv, NULL);
	
	result=tv.tv_sec;
	result *= 1000;
	result += (tv.tv_usec / 1000);
	

#endif
#ifdef WINDOWS
	FILETIME time1;
	LARGE_INTEGER lint1;

	// get number of 100 nanosecond intervals since 1601
	GetSystemTimeAsFileTime(&time1);
	lint1.LowPart=time1.dwLowDateTime;
	lint1.HighPart=time1.dwHighDateTime;

	// convert to milliseconds
	result = lint1.QuadPart / 10000;

#endif
	
	return(result);
}



#ifdef WINDOWS
#include <windows.h>
#include <process.h>

int wth_thread_create(wth_thread func, void* arg, wth_thread_handle *handle)
{
	/* creates a thread which executes func, and passes it arg
	 * return 0 on success, -1 on failure
	 */
	unsigned id;
	HANDLE hthread;

	// They say that _beginthreadex does some things to make
	// the C library thread safe.  I don't know, but it can't hurt.
	hthread = (HANDLE)_beginthreadex(NULL, 0, func, arg, 0, &id);
	//hthread = CreateThread(NULL, 0, func, arg, 0, &id);

	if(hthread == NULL) return(-1);
	
	// If the caller wants the handle, store it in their provided address,
	// otherwise, close the handle so the thread won't linger
	if(handle)
		*handle=hthread;
	else
		CloseHandle(hthread);
	
	return(0);
}

wth_thread_handle wth_thread_self()
{
	wth_thread_handle handle;
	
	if(DuplicateHandle(GetCurrentProcess(), /* source process */
	                GetCurrentThread(),  /* handle to duplicate */
	                GetCurrentProcess(), /* target process */
	                &handle, /* pointer to duplicate handle */
	                0, /* ignored because of SAME_ACCESS */
	                FALSE, /* not inheritable */
	                DUPLICATE_SAME_ACCESS) == 0)
	{
		/* If we failed to duplicate the handle, set the
		 * handle to invalid to indicate this.
		 */
		handle = INVALID_HANDLE_VALUE;
	}

	return(handle);
}

void wth_thread_handle_close(wth_thread_handle handle)
{
	CloseHandle(handle);
}

int wth_thread_terminate(wth_thread_handle handle)
{
	// Forcibly terminate the thread.  Return 0 on success
	// or nonzero on error
	
	if(TerminateThread(handle, 0))
		// Success
		return(0);
	else
		return(-1);
}

/* Wait until a thread has been closed or terminated.
 * On Linux, either this or wth_thread_detach must be called in order to
 * free the memory resources for the thread.
 */
int wth_thread_wait(wth_thread_handle handle)
{
	if(WaitForSingleObject(handle, INFINITE) != WAIT_FAILED)
		return(0);
	else
		return(-1);
}

/* Detach the thread so that a wait() is not necessary to clean
 * up after it exits.
 */
int wth_thread_detach(wth_thread_handle handle)
{
	// Don't need to do anything.
	return(0);
}


int wth_event_init(wth_event* event)
{
	if( ((event->mutex_pred)=CreateMutex(NULL, FALSE, NULL)) == NULL )
		goto error_1;
	if( ((event->event_sig)=CreateEvent(NULL, TRUE, FALSE, NULL)) == NULL )
		goto error_2;
	if( ((event->event_done)=CreateEvent(NULL, TRUE, TRUE, NULL)) == NULL ) /* start off with the event done.  This allows threads to begin waiting on this event */
		goto error_3;
		
	event->waiting = 0; //initially, nobody is waiting.

	if( ((event->mutex_waiting)=CreateMutex(NULL, FALSE, NULL)) == NULL )
		goto error_4;
	
	return(0);
	/************ end of normally executed function  *************/
error_4: //problem creating mutex_waiting
	CloseHandle(event->mutex_waiting);

error_3: //problem creating event_done
	CloseHandle(event->event_sig);

error_2: //problem creating event_sig
	CloseHandle(event->mutex_pred);

error_1: //problem creating mutex_pred
	return(-1);
}

int wth_event_prewait(wth_event* event)
{
	DWORD res;

	res = WaitForSingleObject(event->mutex_pred, INFINITE);

	if( res == WAIT_OBJECT_0 || res == WAIT_ABANDONED )
		return(0);
	else
		return(-1);
}

int wth_event_wait(wth_event* event, unsigned int* timeout)
{
	int fail=0;
	DWORD res;
	DWORD res2;
	WINT64 lint1;
	WINT64 lint2;
	WINT64 elapsed; /* amount of time elapsed between start and finish (in ms)*/

	/* Before we do anything, we'll quickly grab the system time for timeout
	 * purposes.  If we don't timeout, we end up writing the remainder of the
	 * timeout period back into *timeout, so we have to know where we started from.
	 */

	lint1 = wth_milliseconds();
	//GetSystemTimeAsFileTime(&time1);
	//lint1.LowPart=time1.dwLowDateTime;
	//lint1.HighPart=time1.dwHighDateTime;
	
	/* First, wait for "event_done" to become signalled.
	 * Very often, this will be signalled already.  The only time
	 * it won't be is when this wth_event has been signalled,
	 * and we are waiting for all of the threads to wake up
	 * and process the event.
	 * event_done will let us through when it's safe to wait on
	 * this wth_event.
	 * 
	 * This wait should only last for milliseconds max unless
	 * there is a bug with this or with Windows.
	 */
	res = WaitForSingleObject(event->event_done, INFINITE);
	if( !((res == WAIT_OBJECT_0) || (res == WAIT_ABANDONED)) )
		goto error_1;

	/* Now lock the mutex so we can increment the number of waiting
	 * threads.  This shouldn't take long at all either.
	 */
	res = WaitForSingleObject(event->mutex_waiting, INFINITE);
	if( !((res == WAIT_OBJECT_0) || (res == WAIT_ABANDONED)) )
		goto error_2;

	/* increment number of waiting threads */
	event->waiting++;

	if(ReleaseMutex(event->mutex_waiting) == 0) /* 0 means failure */
	{
		event->waiting--;
		goto error_3;
	}

	if(ReleaseMutex(event->mutex_pred) == 0) /* 0 means failure */
		goto error_4;

	if(timeout)
		res = WaitForSingleObject(event->event_sig, *timeout);
	else
		res = WaitForSingleObject(event->event_sig, INFINITE);
	/* NOTE NOTE: the return value (res) should be preserved until
	 * the if statement below that checks it
	 */

	res2 = WaitForSingleObject(event->mutex_waiting, INFINITE);
	if( !((res2 == WAIT_OBJECT_0) || (res2 == WAIT_ABANDONED)) )
		return(-1); /* This should never happen */

	event->waiting--;

	/* From here down, we'll just record whether or not events failed, and report
	 * accordingly, but we won't interrupt operation if something fails.
	 * Pretty much everything has to be done anyways from here down.
	 */
	 
	if( event->waiting == 0 ) /* We are the last thread waiting on this event */
	{
		fail |= !(ResetEvent(event->event_sig));
		fail |= !(SetEvent(event->event_done));
	}

	fail |= !(ReleaseMutex(event->mutex_waiting));

	fail |= (WaitForSingleObject(event->mutex_pred, INFINITE) == WAIT_FAILED);
	
	if(res == WAIT_OBJECT_0 && timeout)
	{ /* Only calculate times if we ended up successful and had a timeout specified */
		lint2 = wth_milliseconds();
		//GetSystemTimeAsFileTime(&time2);
		//lint2.LowPart=time2.dwLowDateTime;
		//lint2.HighPart=time2.dwHighDateTime;


		//elapsed = (lint2.QuadPart - lint1.QuadPart) / 10000;
		elapsed = lint2 - lint1;
		if(elapsed > *timeout)
			*timeout = 0;
		else
			*timeout -= (unsigned int)elapsed;
			
		return(0);
	}
	else if(res == WAIT_OBJECT_0)
	{ // success, but no timeout value specified
		return(0);
	}

	if(res == WAIT_TIMEOUT)
		return(1);

	//If we are here, the wait for the signal above failed.  Return the error.
	return(-1);

error_4: //problem releasing the predicate mutex.  I guess we still have it then.
	WaitForSingleObject(event->mutex_waiting, INFINITE); /* reobtain the mutex for the number of waiting threads */
	event->waiting--;
	ReleaseMutex(event->mutex_waiting);
error_3: //problem releasing mutex_waiting. We decremented the counter above
error_2: //problem waiting on mutex_waiting.  shouldn't happen.
error_1: //problem waiting on event_done.  shouldn't happen.
	return(-1);
}

int wth_event_broadcast(wth_event* event)
{
/* The event should be owned by the calling thread (either by prewait
 *  or after wait)
 * This function releases any threads waiting on the
 * event.  However, those threads cannot execute unless
 * the release function is called after this function
 * is called.
 */

	/* Predicate mutex of the event should be locked now from having called prewait
	 * (User must do this before calling this function)
	 */
	int l_wait; /* local copy of the waiting variable */

	if(ResetEvent(event->event_done) == 0) /* unsignal event_done, which will temporarily suspend any more waits on this event */
		return(-1);

	/* Now, check if there are any threads waiting.  If not, don't do anything,
	 * else we'd hang on the wait for event_done
	 */
	if(WaitForSingleObject(event->mutex_waiting, INFINITE) == WAIT_FAILED)
		goto error_1;

	l_wait = event->waiting;

	ReleaseMutex(event->mutex_waiting);

	if(l_wait > 0)
	{ /* there are threads waiting */
		if(SetEvent(event->event_sig) == 0) /* set signal on event */
		/* if problems, put event_done back to signalled and return error */
			goto error_1;

		if(WaitForSingleObject(event->event_done, INFINITE) == WAIT_FAILED)
			return(-1);


		/* And that's it... The last waiting thread at this point has
		 * already cleaned up by resetting event_sig and setting event_done
		 */
	}
	else
	{ /* If no threads were waiting, then we must re-enable this event by
	   * signalling event_done.  There are no waiting threads to do it for us
	   * this time.
	   */

	   SetEvent(event->event_done);
	}
	
	return(0);
	
error_1: /* we need to re-signal event_done and return an error. */

	SetEvent(event->event_done); 
	return(-1);
}

int wth_event_release(wth_event* event)
{
	/*this function assumes that the mutex is owned by the calling thread.
	 *This means that the thread has called the prewait function.
	 *Returns 0 for success or -1 for error.
	 */
	if(ReleaseMutex(event->mutex_pred) == 0)
		return(-1);
	else
		return(0);
}

int wth_event_destroy(wth_event* event)
{
	/* returns 0 for ok, -1 for error */
	int fail=0;
	
	fail |= !(CloseHandle(event->mutex_waiting));
	fail |= !(CloseHandle(event->event_done));
	fail |= !(CloseHandle(event->event_sig));
	fail |= !(CloseHandle(event->mutex_pred));

	if(fail)
		return(-1);
	else
		return(0);
}

int wth_mutex_init(wth_mutex* mutex)
{
	HANDLE hmutex;
	
	if( (hmutex=CreateMutex(NULL, FALSE, NULL)) == NULL )
		return(-1);

	*mutex = hmutex;
	return(0);
}


int wth_mutex_wait(wth_mutex* mutex, unsigned int* timeout)
{
/* timeout specifies the number of milliseconds to wait for the mutex
 * before timing out.  If a NULL pointer is passed, no timeout is used.
 * If the mutex is obtained before the timeout, the number of remaining
 * milliseconds before the scheduled timeout is written into timeout.
 * 
 * Return Values: 0 for success (got mutex)
 * 				  1 for timeout
 * 				  -1 for error
 */
	DWORD res;
	WINT64 lint1;
	WINT64 lint2;
	WINT64 elapsed; /* amount of time elapsed between start and finish (in ms)*/


	if(timeout)
	{
		/* Before we do anything, we'll quickly grab the system time for timeout
		 * purposes.  If we don't timeout, we end up writing the remainder of the
		 * timeout period back into *timeout, so we have to know where we started from.
		 */
		lint1 = wth_milliseconds();
		//GetSystemTimeAsFileTime(&time1);
		//lint1.LowPart=time1.dwLowDateTime;
		//lint1.HighPart=time1.dwHighDateTime;

		res = WaitForSingleObject(*mutex, *timeout);

		if(res == WAIT_OBJECT_0 || res == WAIT_ABANDONED)
		{ /* we have obtained the mutex. figure out remaining time. */

			lint2=wth_milliseconds();
			//GetSystemTimeAsFileTime(&time2);
			//lint2.LowPart=time2.dwLowDateTime;
			//lint2.HighPart=time2.dwHighDateTime;


			//elapsed = (lint2.QuadPart - lint1.QuadPart) / 10000;
			elapsed = lint2 - lint1;
			if(elapsed > *timeout)
				*timeout = 0;
			else
				*timeout -= (unsigned int)elapsed;
			return(0);
		}
		else if(res == WAIT_TIMEOUT)
			return(1);
	}
	else
	{ /* a NULL was passed for timeout, so don't ever timeout */
		if(WaitForSingleObject(*mutex, INFINITE) != WAIT_FAILED)
			return(0);
	}

	/* If we're here, an error occured either in the timeout wait, or in the
	 * non-timeout wait.  Return an error.
	 */

	return(-1);
}

int wth_mutex_release(wth_mutex* mutex)
{
	if(ReleaseMutex(*mutex)) /* nonzero is success, zero is fail */
		return(0);
	else
		return(-1);
	
}

int wth_mutex_destroy(wth_mutex* mutex)
{
	if(CloseHandle(*mutex)) /* nonzero is success */
		return(0);
	else
		return(-1);
}

#endif //WINDOWS

/* ----------------------------- End of Windows section / Begin Linux   ---------- */

#ifdef LINUX
#include <errno.h>
#include <time.h>
#include <sys/time.h>
#include <unistd.h>
#include <stdio.h>

int wth_thread_create(wth_thread func, void* arg, wth_thread_handle *handle)
{
	/* creates a thread which executes func, and passes it arg
	 * return 0 on success, -1 on failure
	 */
	pthread_attr_t attr;
	pthread_t tid;
	
	if(pthread_attr_init(&attr))
		return(-1);

	// We definitely do NOT want to put it into detached mode any more.
	// We now have a separate function that can do that as well as 
	// a function to wait for the thread to terminate.
	//if(pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED))
	//	return(-1);
	
	if(pthread_create(&tid, &attr, func, arg))
		return(-1);
	
	// If the caller wants the handle, store it
	if(handle)
		*handle=tid;
	
	return(0);
}

/* Return a handle to the current thread */
wth_thread_handle wth_thread_self()
{
	return(pthread_self());
}

/* Close a handle (not the thread) when it is no longer needed */
void wth_thread_handle_close(wth_thread_handle handle)
{
	// Nothing necessary on Linux threads
	return;
}

/* Forcibly terminate a thread when given the handle */
int wth_thread_terminate(wth_thread_handle handle)
{
	return(pthread_cancel(handle));
}


/* Wait until a thread has been closed or terminated.
 * On Linux, either this or wth_thread_detach must be called in order to
 * free the memory resources for the thread.
 */
int wth_thread_wait(wth_thread_handle handle)
{
	if(pthread_join(handle, NULL)) // 0 return means success
		return(-1); 
	else
		return(0);
}

/* Detach the thread so that a wait() is not necessary to clean
 * up after it exits.
 */
int wth_thread_detach(wth_thread_handle handle)
{
	if(pthread_detach(handle)) // 0 return means success
		return(-1);
	else
		return(0);

}



int wth_event_init(wth_event* event)
{
	if(pthread_mutex_init(&(event->mutex), NULL))
		return(-1);
	if(pthread_cond_init(&(event->cond), NULL))
	{
		pthread_mutex_destroy(&(event->mutex));
		return(-1);
	}
	return(0);
}

int wth_event_prewait(wth_event* event)
{
	/* returns 0 if there were no problems, -1 if there were problems.
	 * Obtains the mutex so the predicate can be examined.
	 * either the release or the wait function should be quickly
	 * called. 
	 */
	
	if(pthread_mutex_lock(&(event->mutex)))
		return(-1);
	return(0);
}

int wth_event_wait(wth_event* event, unsigned int* timeout)
{ /* prewait MUST have been called before this function
	 was called.
		waits for the event, timing out after 
	 timeout milliseconds. If the event occurs before timeout,
	 the remaining time till timeout is written into timeout.
	 If timeout is NULL, there will be no timeout.
	 Return Value:
	 	 0  - received event signal.
	 	 1  - timed out
		-1  - error

		Regardless of return, the release function should be quickly
		called (after retrieving or setting data of course) after this
		function returns.
	*/

	struct timeval curtime; 
	struct timespec timeout_l;
	int retval;
	unsigned int timeleft; //amount of time till timeout (in milliseconds)
	
	if(timeout)
	{
		gettimeofday(&curtime, NULL);
		timeout_l.tv_nsec = (curtime.tv_usec * 1000) + ((*timeout % 1000) * 1000000);
		timeout_l.tv_sec = curtime.tv_sec + (*timeout / 1000) + timeout_l.tv_nsec / 1000000000; /* tv_nsec / 1000000000 to add any whole seconds to this part */
		timeout_l.tv_nsec %= 1000000000; /* trim off any whole seconds */
	
		retval = pthread_cond_timedwait(&(event->cond), &(event->mutex), &timeout_l);
	}
	else
	{
		retval = pthread_cond_wait(&(event->cond), &(event->mutex));
	}

	if(retval == 0)
	{
		if(timeout)
		{
			gettimeofday(&curtime, NULL);
			timeleft = ((timeout_l.tv_sec - curtime.tv_sec) * 1000) + 
				(timeout_l.tv_nsec / 1000000) - (curtime.tv_usec / 1000);
			*timeout = timeleft;
		}
		return(0); /* OK, got signal */
	}
	else if(retval == ETIMEDOUT)
		return(1); /* timed out */
	else
		return(-1); /* error */
}

int wth_event_broadcast(wth_event* event)
{
/* The event should be owned by the calling thread (either by prewait
 *  or after wait)
 * This function releases any threads waiting on the
 * event.  However, those threads cannot execute unless
 * the release function is called after this function
 * is called.
 */
	if(pthread_cond_broadcast(&(event->cond)))
		return(-1);
	else
		return(0);
}

int wth_event_release(wth_event* event)
{
	/*this function assumes that the mutex is owned by the calling thread.
	 *This means that the thread has called the prewait function.
	 *Returns 0 for success or -1 for error.
	 */
	if(pthread_mutex_unlock(&(event->mutex)))
		return(-1);
	else
		return(0);
}

int wth_event_destroy(wth_event* event)
{
	/* returns 0 for ok, -1 for error */
	int fail=0;
	fail = fail || pthread_cond_destroy(&(event->cond));
	fail = fail || pthread_mutex_destroy(&(event->mutex));

	if(fail)
		return(-1);
	else
		return(0);
}

int wth_mutex_init(wth_mutex* mutex)
{
	if(pthread_mutex_init(&(mutex->mutex), NULL))
		return(-1);
	if(pthread_cond_init(&(mutex->cond), NULL))
	{
		pthread_mutex_destroy(&(mutex->mutex));
		return(-1);
	}
	mutex->busy = 0;/* start out being available */
	return(0);
}

int wth_mutex_wait(wth_mutex* mutex, unsigned int* timeout)
{
	/*returns 0 for success, -1 for error, 1 for timeout
	 * timeout pointer of NULL means no timeout
	 */
	struct timeval curtime; 
	struct timespec timeout_l;
	int retval=0;
	long int timeleft; //amount of time until timeout (in milliseconds)

	if(timeout)
	{
		gettimeofday(&curtime, NULL);
		timeout_l.tv_nsec = (curtime.tv_usec * 1000) + ((*timeout % 1000) * 1000000);
		timeout_l.tv_sec = curtime.tv_sec + (*timeout / 1000) + timeout_l.tv_nsec / 1000000000; /* tv_nsec / 1000000000 to add any whole seconds to this part */
		timeout_l.tv_nsec %= 1000000000; /* trim off any whole seconds */
	}
	
	if(pthread_mutex_lock(&(mutex->mutex))) /* lock mutex so we can examine the busy variable */
		return(-1);
	while(mutex->busy)/* note that we may never wait, so retval defaults to 0 */
	{	/* waiting releases mutex so others can wait too */
		if(timeout)
			retval = pthread_cond_timedwait(&(mutex->cond), &(mutex->mutex), &timeout_l);
		else
			retval = pthread_cond_wait(&(mutex->cond), &(mutex->mutex));
		if(retval) /* either error or timeout */
			break;
	}
	
	if(retval == 0)
	{/* everything ok, set busy, unlock my mutex and calculate remaining time for user's information */
		mutex->busy = 1;

		if(timeout)
		{
			gettimeofday(&curtime, NULL);
			timeleft = ((timeout_l.tv_sec - curtime.tv_sec) * 1000) + 
				(timeout_l.tv_nsec / 1000000) - (curtime.tv_usec / 1000);
			if(timeleft<0)
				*timeout=0;
			else
				*timeout = (unsigned int)timeleft;
		}
	}
	else if(retval == ETIMEDOUT)
		retval = 1;
	else
		retval = -1;

	/* unlock mutex before returning */
	if(pthread_mutex_unlock(&(mutex->mutex)))
	{ /* if failed, not quite sure what to do, but we'll free our mutex, return an error */
		mutex->busy=0;
		retval = -1;
	}
		
	return(retval);
}

int wth_mutex_release(wth_mutex* mutex)
{
	int retval;
	
	if(pthread_mutex_lock(&(mutex->mutex)))
	{
		return(-1);
	}
	mutex->busy=0;
	//retval = pthread_cond_signal(&(mutex->cond));
	retval = pthread_cond_broadcast(&(mutex->cond));
	retval = pthread_mutex_unlock(&(mutex->mutex)) || retval;
	if(retval)
		return(-1);
	else
		return(0);
}

int wth_mutex_destroy(wth_mutex* mutex)
{
	int retval;
	retval = pthread_mutex_destroy(&(mutex->mutex));
	retval = retval || pthread_cond_destroy(&(mutex->cond));
	if(retval)
		return(-1);
	else
		return(0);
}


#endif //LINUX

