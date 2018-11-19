CC=cc
CFLAGS=-std=c90 -Wall -Wextra -pedantic -O3

.PHONY: all clean

all: colortool bytesh

colortool: colortool.c colortool.h
	$(CC) colortool.c -o $@ $(CFLAGS) $$(pkg-config --cflags x11)  $$(pkg-config --libs x11)

bytesh: bytesh.c bytesh.h
	$(CC) bytesh.c -o $@ $(CFLAGS) -lreadline -fgnu89-inline -lcurses

clean:
	rm -f *.core *.o *.gch
	rm -f colortool
	rm -f bytesh
