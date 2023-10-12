/* Winford Engineering ETH32 API
 * Copyright 2005 Winford Engineering
 * www.winford.com
 *
 * Please see the LICENSE.txt file for information regarding how
 * the ETH32 API source code may be used.
 */


#ifndef commands_h
#define commands_h

// Length of EVERY incoming command
#define CMDLEN     5

#define CMD_PING   1
#define CMD_OPORT  2
#define CMD_IPORT  3
#define CMD_RBOUT  4
#define CMD_GPDIR  5
#define CMD_SPDIR  6
#define CMD_GASTA  7
#define CMD_SASTA  8
#define CMD_IANLG  9
#define CMD_EEVT  10
#define CMD_DEVT  11
#define CMD_GAEVT 12
// 13 is telnet test
#define CMD_SAEVT 14
#define CMD_SBIT  15
#define CMD_CBIT  16
#define CMD_GREF  17
#define CMD_SREF  18
#define CMD_GCHAS 19
#define CMD_SCHAS 20
#define CMD_SNBAT 21
#define CMD_SNUNT 22
#define CMD_PRID  23
#define CMD_FREL  24
#define CMD_RST   26
#define CMD_SRD   27
#define CMD_PULSE 28
#define CMD_GCSTA 29
#define CMD_SCSTA 30
#define CMD_CNTRD 31
#define CMD_CNTWR 32
#define CMD_GCEVT 33
#define CMD_SCEVT 34
#define CMD_GCROL 35
#define CMD_SCROL 36
#define CMD_GPCLK 37
#define CMD_SPCLK 38
#define CMD_GPBAS 39
#define CMD_SPBAS 40
#define CMD_GPCST 41
#define CMD_SPCST 42
#define CMD_GPCDC 43
#define CMD_SPCDC 44
#define CMD_CFLAG 45
#define CMD_GEE2  46
#define CMD_SEE1  47
#define CMD_SEE3  48

#define EVT_DIGI  10
#define EVT_ANLG  14
#define EVT_HEART 25
#define EVT_COUNT 34

#endif

