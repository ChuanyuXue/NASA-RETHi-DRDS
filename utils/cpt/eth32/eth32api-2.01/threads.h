/* Winford Engineering ETH32 API
 * Copyright 2005 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */

 
#ifndef threads_h
#define threads_h


#ifdef WINDOWS
#include <windows.h>
typedef struct
{
	HANDLE mutex_pred; /* mutex locked by "prewait" which allows the user 
	                    * to inspect the predicate */
	HANDLE event_sig;  /* Manual-reset event providing the signal for the event.  
	                    * This stays signalled until the last waiting thread sees 
	                    * it.  That thread then resets it */
	HANDLE event_done; /* Manual-reset event signalling that all the waiting threads 
	                    * have "seen" the event's signal */
	int waiting; /* number of threads waiting on this event */
	HANDLE mutex_waiting; /* protects access to the waiting variable */

} wth_event;

typedef HANDLE wth_thread_handle;

typedef HANDLE wth_mutex;

/* LPTHREAD_START_ROUTINE has this format:
   DWORD WINAPI funcname(LPVOID);
 */
//typedef LPTHREAD_START_ROUTINE wth_thread; // use with CreateThread
typedef unsigned (__stdcall *wth_thread)(void *);

#endif

#ifdef LINUX
#include <pthread.h>
typedef struct 
{
	pthread_mutex_t mutex;
	pthread_cond_t cond;
} wth_event;
typedef void *(*wth_thread)(void *);

typedef struct
{
	pthread_mutex_t mutex;
	pthread_cond_t cond;
	int busy;
} wth_mutex;

typedef pthread_t wth_thread_handle;

#endif

#ifndef WINT64
#ifdef WINDOWS
typedef __int64 WINT64;
#else
typedef long long WINT64;
#endif
#endif

WINT64 wth_milliseconds();


/* Create a new thread */
// If handle is passed in as null, the handle to the thread will be closed
// rather than passed back to the caller
int wth_thread_create(wth_thread func, void* arg, wth_thread_handle *handle);

/* Return a handle to the current thread */
wth_thread_handle wth_thread_self();

/* Close a handle (not the thread) when it is no longer needed */
void wth_thread_handle_close(wth_thread_handle handle);

/* Forcibly terminate a thread when given the handle */
int wth_thread_terminate(wth_thread_handle handle);

/* Wait until a thread has been closed or terminated.
 * On Linux, either this or wth_thread_detach must be called in order to
 * free the memory resources for the thread.
 */
int wth_thread_wait(wth_thread_handle handle);

/* Detach the thread so that a wait() is not necessary to clean
 * up after it exits.
 */
int wth_thread_detach(wth_thread_handle handle);

int wth_event_init(wth_event* event);
int wth_event_prewait(wth_event* event);
/* Obtains the mutex so the predicate can be examined.
 * either the release or the wait function should be quickly
 * called. 
 */
int wth_event_wait(wth_event* event, unsigned int* timeout);
/* after wait returns, the thread has exclusive access to the
 * data being protected by the event.  The thread should
 * call the release function as soon as possible
 * 
 * timeout specifies the number of milliseconds to wait for the event
 * before timing out.  If a NULL pointer is passed, no timeout is used.
 * If the event is signalled before the timeout, the number of remaining
 * milliseconds before the scheduled timeout is written into timeout.
 * 
 * Return Values: 0 for success
 * 				  1 for timeout
 * 				  -1 for error
 */

int wth_event_broadcast(wth_event* event);
/* The event should be owned by the calling thread (either by prewait
 *  or after wait)
 * This function releases any threads waiting on the
 * event.  However, those threads cannot execute unless
 * the release function is called after this function
 * is called.
 */

int wth_event_release(wth_event* event);
/* This function releases the thread's hold on the predicate 
 * condition.  It does NOT signal the event.
 * the signal function should be called immediately before
 * this function if desired
 */

int wth_event_destroy(wth_event* event);

int wth_mutex_init(wth_mutex* mutex);
int wth_mutex_wait(wth_mutex* mutex, unsigned int* timeout);
/* timeout specifies the number of milliseconds to wait for the mutex
 * before timing out.  If a NULL pointer is passed, no timeout is used.
 * If the mutex is obtained before the timeout, the number of remaining
 * milliseconds before the scheduled timeout is written into timeout.
 * 
 * Return Values: 0 for success (got mutex)
 * 				  1 for timeout
 * 				  -1 for error
 */

int wth_mutex_release(wth_mutex* mutex);
int wth_mutex_destroy(wth_mutex* mutex);

#endif // threads_h
