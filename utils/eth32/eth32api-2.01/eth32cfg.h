/* Winford Engineering ETH32 API
 * Copyright 2010 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */
 
#ifndef eth32cfg_h
#define eth32cfg_h


// Lengths of different parts of the serial number string
#define SERLEN_PRODID   3
#define SERLEN_BATCH    2
#define SERLEN_UNIT     3


unsigned short checksum(unsigned short *addr, unsigned int count);

int CALLCONVENTION CALLEXTRA eth32cfg_serialnum_string(unsigned char product_id, unsigned short batch, unsigned short unit, char *serialstring, int bufsize);

 
 
#endif
