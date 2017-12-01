
CC      = gcc
CXX     = g++
CFLAGS  = -Wall -O2 -D_GNU_SOURCE

SOURCE = \
		NextionDriver.c processCommands.c

all:		clean NextionDriver

NextionDriver:
		$(CC) $(SOURCE) $(CFLAGS) -o NextionDriver

clean:
		$(RM) NextionDriver *.o *.d *.bak *~