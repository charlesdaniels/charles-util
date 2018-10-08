#ifndef COLORTOOL_H
#define COLORTOOL_H

/* allow strtok_r */
#define _POSIX_C_SOURCE 200112L

#include <getopt.h>
#include <string.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <stdint.h>
#include <limits.h>
#include <unistd.h>

#include <X11/Xlib.h>
#include <X11/Xutil.h>

/* number of pixels for the colored box */
#define COLOR_SIZE 150

/* number of pixels high the text box should be */
#define TEXT_BOX_HEIGHT 25

/* message buffer length for the string displayed in the window */
#define MESSAGE_SIZE 128

/* current program version */
#define VERSION_STRING "1.0.1"

/* window title */
#define COLORTOOL_TITLE "colortool"

/* number of events to flush before beginning in the event waiting loop */

/* define bool, for convenience */
#define bool unsigned short int
#define false 0
#define true 1

/* strdup is a GNU extension, not part of the ANSI spec */
#define STRDUP(dst, src) dst = (char*) malloc (sizeof(char) * strlen(src)); strcpy(dst, src)

/* function prototypes */
static long strtol_safe (const char *str, int base);
unsigned int rgbtou24(unsigned char r, unsigned char g, unsigned char b);
void u24torgb(unsigned int c, unsigned char* r, unsigned char* g, unsigned char* b);
unsigned int parse_color(char* color_str);
static unsigned int apply_mask(unsigned int c, char* mask);
static unsigned int apply_filter(unsigned int c, char* filter);
void display_help();
void display_color(unsigned int c);
int main(int argc, char** argv);


#endif
