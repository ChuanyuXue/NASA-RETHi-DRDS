#!/bin/sh
# This simple script installs the ETH32 library files (one shared, on static)
# and the ETH32 header file onto the user's system.
# It assumes that these files reside in the same directory as this script
# and it is distributed in that way on the ETH32 CD.
# Winford Engineering
# www.winford.com

USERID=$(id -u)
if [ $USERID -ne 0 ]
then
	echo "You must run this script with root privileges."
	exit 1
fi

echo "This script will install the ETH32 API library and header onto your "
echo "system.  If you would like to abort, hit Ctrl-C."
echo
echo "Hit Enter to continue..."
read JUNK

echo "Installing..."

# CD into the directory containing this script.  In most cases 
# this isn't necessary, but if somebody runs the install script 
# from outside this directory, it is.
cd $(dirname $0)

# Copy the library files into /usr/lib/
cp -a libeth32* /usr/lib/
# Set up symbolic links, etc.
ldconfig
# Make the symbolic link used during development and compiling apps
ln -s libeth32.so.1 /usr/lib/libeth32.so

# Copy the header file
cp -a eth32.h /usr/include/

echo "Installation finished."

