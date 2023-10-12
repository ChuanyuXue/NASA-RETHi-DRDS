# Makefile for ETH32 API

# Location of API source files
DIR=../

# Versioning info:
# Library base name
BASENAME=eth32
# Library interface number - increment this any time binary incompatible version
# is introduced
INTERFACE=1
# API version number.  Defined in the VERSION file
include $(DIR)VERSION

STATIC=lib$(BASENAME).a
SHARED=lib$(BASENAME).so
SONAME=$(SHARED).$(INTERFACE)
REALNAME=$(SONAME).$(VERSION)

CC=gcc
CFLAGS=-pthread -D_REENTRANT -D_GNU_SOURCE -DLINUX -Wall -fPIC -O2 -fomit-frame-pointer


SRC=$(addprefix $(DIR), eth32.c eth32cfg.c threads.c eth32_internal.c dbllist.c devtable.c socket.c)

OBJ = $(notdir $(SRC:.c=.o))

OUTPUT=$(STATIC) $(REALNAME) eth32.h

# Default way to compile .c into .o
%.o: $(DIR)%.c
	$(CC) $(CFLAGS) -c $^


all: $(OUTPUT)

$(STATIC): $(OBJ)
	ar rcs $@ $(OBJ)

$(REALNAME): $(OBJ)
	@# Note that although including the -lpthread here would make the 
	@# resulting library indicate a dependancy on libpthread, we don't
	@# want to do it this way, because it would then allow somebody to
	@# successfully link their application without specifying -pthread.
	@# Why is that a problem?  Because libpthread provides a replacement
	@# for fork() that apparently does not get used if the program itself isn't
	@# linked against pthreads.
	gcc -pthread -shared -Wl,-soname,$(SONAME) -o $@ $(OBJ) -lm -lc
	strip $@

eth32.h: $(DIR)eth32.h
	echo "/* This file is the Linux version of the eth32.h header */" > $@
	echo "#ifndef LINUX" >> $@
	echo "#define LINUX" >> $@
	echo "#endif" >> $@
	echo >> $@
	echo >> $@
	cat $^ >> $@

clean:
	rm -f $(OUTPUT) $(OBJ)

install: all
	./install.sh