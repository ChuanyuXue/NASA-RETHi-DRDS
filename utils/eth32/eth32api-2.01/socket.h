/* Winford Engineering ETH32 API
 * Copyright 2005 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */

#ifndef socket_h
#define socket_h

#include "eth32_internal.h"

#ifdef LINUX
typedef int eth32_socket;
#endif
#ifdef WINDOWS
typedef SOCKET eth32_socket;
#endif


int eth32_socket_open(char *address, WORD port, eth32_socket *socket, unsigned int timeout);
void eth32_socket_nodelay(eth32_socket sock, int nodelay);
void eth32_socket_blocking(eth32_socket sock, int blocking);
int eth32_socket_buffered(eth32_socket sock);
int eth32_socket_shutdown(eth32_socket sock, int how);
void eth32_socket_close(eth32_socket sock);


#endif // socket_h
