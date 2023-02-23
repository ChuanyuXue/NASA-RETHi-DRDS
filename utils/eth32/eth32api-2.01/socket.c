/* Winford Engineering ETH32 API
 * Copyright 2005 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */


/* Network socket support functions */

#include "eth32_internal.h"


int eth32_socket_open(char *address, WORD port, eth32_socket *socketptr, unsigned int timeout)
{
	/* Open a socket to the ETH32 device (or anything else)
	 *
	 * If successful, this function stores the socket descriptor into the given
	 * socket pointer.
	 *
	 * timeout specifies a timeout for the connect() call, in milliseconds.
	 * A timeout of 0 uses the system-default timeout.
	 * 
	 * Returns 0 on success.  Negative error code on error.
	 */
	 
	eth32_socket sock;
	struct sockaddr_in addr;
	struct hostent* hostinfo;
	int ecode;
	int sockerror;
	struct timeval tout;
	int ret;
	fd_set writefs;
	fd_set exceptfs;
	eth32_socket max;

#ifdef WINDOWS
	WSADATA wsaData;
	int optlen;
#else
	socklen_t optlen;
#endif

	if( !socketptr )
		return(ETH_INVALID_POINTER);

#ifdef WINDOWS
	// On windows, do a WSAStartup.  You can do as many WSAStartups as you want 
	// as long as you do the same number of WSACleanups.  Only the last call to 
	// WSACleanup will have any effect.
	
	if( WSAStartup(MAKEWORD(1, 1), &wsaData) != 0 )
		return(ETH_WINSOCK_ERROR);
#endif

	hostinfo = gethostbyname(address);

	if(hostinfo == 0)
	{
		ecode=ETH_NETWORK_ERROR;
		goto error_1;
	}

	addr.sin_family = AF_INET;
	addr.sin_port = htons(port);
	addr.sin_addr = *(struct in_addr*)*hostinfo->h_addr_list;


#ifdef WINDOWS
	if( (sock = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET )
#else
	if( (sock = socket(AF_INET, SOCK_STREAM, 0)) < 0 )
#endif
	{
		ecode=ETH_NETWORK_ERROR;
		goto error_1;
	}


	if(timeout)
		eth32_socket_blocking(sock, 0);

	
	if( connect(sock, (struct sockaddr*)&addr, sizeof(struct sockaddr_in)) )
	{
#ifdef WINDOWS
		sockerror=WSAGetLastError();
		if(sockerror==WSAEINPROGRESS || sockerror==WSAEWOULDBLOCK)
#else
		sockerror=errno;
		if(sockerror==EINPROGRESS)
#endif
		{
			if(timeout==0)
			{
				// This should never happen, but if we're going with the 
				// system-default timeout and end up here, fail immediately.
				ecode=ETH_NETWORK_ERROR;
				goto error_2;
			}
			
			// Prepare our file descriptor sets for select()
			FD_ZERO(&writefs);
			FD_SET(sock, &writefs);
			exceptfs=writefs;
			max=sock+1;

			tout.tv_sec=timeout/1000;
			tout.tv_usec=(timeout-tout.tv_sec*1000)*1000; // microseconds

			// NOTE: Windows ignores the first parameter and passing in max causes a warning on x64 platform,
			// so just pass in zero on Windows platforms.
#ifdef WINDOWS			
			ret=select(0, NULL, &writefs, &exceptfs, &tout);
#else
			ret=select(max, NULL, &writefs, &exceptfs, &tout);
#endif
			if(ret<0)
			{
				// Error in select
				ecode=ETH_NETWORK_ERROR;
				goto error_2;
			}
			else if(ret==0)
			{
				// Operation timed out
				ecode=ETH_TIMEOUT;
				goto error_2;
			}
			else
			{
				// Select indicated that the operation completed.
				// Now we need to figure out whether we have a connection
				// or an error.
				optlen=sizeof(sockerror);
				if(getsockopt(sock, SOL_SOCKET, SO_ERROR, (void*)&sockerror, &optlen))
				{
					// getsockopt itself failed
					ecode=ETH_NETWORK_ERROR;
					goto error_2;
				}
				
				if(sockerror)
				{
					// We didn't connect
					ecode=ETH_NETWORK_ERROR;
					goto error_2;
				}
				
				// If there was an error, we shouldn't get to here.  But just
				// to be double-sure, make sure that the socket isn't set in
				// the exceptfs set.
				if(FD_ISSET(sock, &exceptfs))
				{
					// There must be some kind of problem
					ecode=ETH_NETWORK_ERROR;
					goto error_2;
				}

			}
		}
		else
		{
			// Otherwise an error other than a non-block notice was returned
			ecode=ETH_NETWORK_ERROR;
			goto error_2;
		}
	}
	// Otherwise the connection succeeded immediately
	
	// Put the socket back to blocking mode if we had put it into nonblocking
	if(timeout)
		eth32_socket_blocking(sock, 1);
	

			
	*socketptr=sock;
	return(0);
error_2:
	// An error occurred after the socket was created, so we need to close it
	eth32_socket_close(sock);

	// The eth32_socket_close does the WSACleanup, so don't fall through:
	return(ecode);
	
error_1:
#ifdef WINDOWS
	// We did a WSAStartup, but we're not returning a socket, so we need to go ahead
	// and do the WSACleanup now.
	WSACleanup();
#endif

	return(ecode);
}

void eth32_socket_nodelay(eth32_socket sock, int nodelay)
{
	/* Control whether the Nagle algorithm is used on the 
	 * given socket.  Passing nodelay of nonzero disables 
	 * any unnecessary delays and causes data to be sent as
	 * soon as possible.
	 */
	int ret;
	
	ret=setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, (const char *)&nodelay, sizeof(int));
}

void eth32_socket_blocking(eth32_socket sock, int blocking)
{
	/* Set the blocking property of the given socket.
	 * blocking:
	 *   0 - Socket will be nonblocking
	 *   nonzero - Socket will be blocking (default)
	 */

#ifdef LINUX
	int flags;
	flags=fcntl(sock, F_GETFL, 0);
	
	if(blocking==0)
		fcntl(sock, F_SETFL, flags | O_NONBLOCK);
	else
		fcntl(sock, F_SETFL, flags & (~O_NONBLOCK));
#endif
#ifdef WINDOWS
	unsigned long arg;
	if(blocking==0)
		// nonblocking
		arg=1;
	else
		arg=0;
	
	ioctlsocket(sock, FIONBIO, &arg);
#endif

}

int eth32_socket_buffered(eth32_socket sock)
{
	// Return how many bytes are buffered and waiting to be read
#ifdef WINDOWS
	unsigned long count;
	
	ioctlsocket(sock, FIONREAD, &count);
#endif
#ifdef LINUX
	int count;
	ioctl(sock, FIONREAD, &count);
#endif
	return(count);
}

int eth32_socket_shutdown(eth32_socket sock, int how)
{
	return(shutdown(sock, how));
}

void eth32_socket_close(eth32_socket sock)
{

#ifdef LINUX
	close(sock);
#endif

#ifdef WINDOWS
	closesocket(sock);
	WSACleanup();
#endif
	
}

