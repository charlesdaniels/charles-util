#include "colortool.h"

/* global flag that prevents the handler from causing an exit */
bool disable_colortool_handler = false;

static long strtol_safe (const char *str, int base) {
	/* either parse the string, or die trying */

	char *endptr;
	long val;

	/* reset errno */
	errno = 0;

	/* attempt to parse */
	val = strtol(str, &endptr, base);

	/* check if there was any error */
	if (endptr== str ||
	    *endptr != '\0' ||
	    ((val == LONG_MIN || val == LONG_MAX) && errno == ERANGE)) {

		fprintf(stderr,
			"FATAL: invalid long int '%s' with base %i\n",
			str,
			base
		);
		exit(1);
	}
	return val;
}
unsigned int rgbtou24(unsigned char r, unsigned char g, unsigned char b) {
	/* cast a set of separate u8 r g b values into one integer */

	unsigned int c;
	c = 0;
	c += r << 16;
	c += g << 8;
	c += b;
	return c;
}

void u24torgb(unsigned int c, unsigned char* r, unsigned char* g, unsigned char* b) {
	/* cast an unsigned int 24-bit color value to individual one-byte r g b
	 * values */
	*r = (c & 0x00FF0000) >> 16;
	*g = (c & 0x0000FF00) >> 8;
	*b = (c & 0x000000FF);
}


unsigned int parse_color(char* color_str) {
	/* Accept a string and parse it into a 24 bit color value. Acceptable
	 * formats are:
	 *
	 * * 0xrrggbb - standard hex notation
	 * * #rrggbb - standard hex color notation
	 * * rrr,ggg,bbb - standard tuple notation
	 *
	 * Unrecognized formats will be parsed as unsigned integers.
	 */

	if (strncmp("0x", color_str, 2) == 0) {
		return (unsigned int) strtol_safe(color_str, 16);

	} else if (strncmp("#", color_str, 1) == 0) {
		color_str[0] = ' ';
		return (unsigned int) strtol_safe(color_str, 16);
	} else if (strstr(color_str, ",") != NULL) {
		/* assume rrr,ggg,bbb format */
		unsigned int r, g, b;
		char* saveptr;
		char* r_str;
		char* g_str;
		char* b_str;
		char* orig_str;

		/* back up the color_str for error messages after we've
		 * started calling strtok. */
		orig_str = (char*) malloc((strlen(color_str) + 8) * sizeof(char));
		strcpy(orig_str, color_str);

		/* parse tokens from input string */
		saveptr = NULL;
		r_str = strtok_r(color_str, ",", &saveptr);
		g_str = strtok_r(NULL, ",", &saveptr);
		b_str = strtok_r(NULL, ",", &saveptr);

		/* make sure parsing the tokens worked */
		if (r_str == NULL || g_str == NULL || b_str == NULL) {
			fprintf(stderr, "FATAL: malformed R,G,B string: '%s'\n", orig_str);
			exit(1);
		}

		/* parse strings to integers in base 10 */
		r = strtol_safe(r_str, 10);
		g = strtol_safe(g_str, 10);
		b = strtol_safe(b_str, 10);

		/* cast to a single int and return */
		return rgbtou24(r, g, b);
	} else {
		return (unsigned int) strtol_safe(color_str, 10);
	}
}

static unsigned int apply_mask(unsigned int c, char* mask) {
	/* Takes a mask in as a hex string and binary OR it with the color.
	 * The string is hard-coded as base 16, and specifies the mask in
	 * the format 0x00RRGGBB. */

	return c | strtol_safe(mask, 16);
}

static unsigned int apply_filter(unsigned int c, char* filter) {
	/* Takes in a base-16 string specifying a filter, which is binary
	 * AND-ed with the color and returned. The channels are arranged as
	 * 0x00RRGGBB. */

	return c & strtol_safe(filter, 16);
}

void display_help() {

	printf(" \
colortool [-c [color]|-v|-h] [-dxrn] [-m mask] [-f filter] \n\
\n\
--color [color] / -c [color]\n\
	Specify the color to operate on. The formats that are allowed are \n\
	R,G,B, #RRGGBB, and 0xRRGGBB. Always required except \n\
	with -v or -h. \n\
\n\
--display / -d \n\
	If asserted, display the specified color in a graphical window. \n\
	Note that this application is safe to use headlessly as long as \n\
	this flag is not asserted. \n\
\n");

	printf("\
--output_hex / -x \n\
	Display the specified color on standard out in #RRGGBB format. \n\
	If both -x and -r are specified, the hex format is printed before the\n\
	R,G,B format.\n\
\n\
--output_rgb / -r\n\
	Display the specified color on standard out in R,G,B format.\n\
	If both -x and -r are specified, the hex format is printed before the\n\
	R,G,B format.\n\
\n\
--noclose / -n\n\
	Do not close the window produced by -d on any keystroke (the default\n\
	behavior). The window can still be closed by WM close events.\n\
");
	printf("\
\n\
--mask [mask] / -m [mask]\n\
	Apply a mask to the specified color before handling -d, -x, or -r. \n\
	The mask is specified in 0xRRGGBB format, and is binary OR-ed with \n\
	the color. Note that the mask specified with -m is applied before the\n\
	filter specified by -f. \n");

	printf("\
\n\
--filter [filter] / -f [filter]\n\
	Apply a filter to the specified color before handling -d, -x, or -r. \n\
	The filter is specified in 0xRRGGBB format, and is binary AND-ed with\n\
	the color. Note that the mask specified with -m is applied before the\n\
	filter specified by -f. \n\
\n\
--version / -v \n\
	Display version string and exit. \n\
\n\
--help / -h \n\
	Display this help message and exit \n\
");

	exit(0);
}

void display_color(unsigned int c) {
	/* Display a window using FLTK with a box showing the desired
	 * color. */

	unsigned char r, g, b;
	Display* display;
	XColor user_color;
	int white_color, black_color;
	bool first_loop;
	Colormap cmap;
	Window window;
	GC gc;
	XEvent xev;
	char* msg;

	/* allocate the color */
	u24torgb(c, &r, &g, &b);
	user_color.red   = r << 8; /* note that in Xlib, colors are stored */
	user_color.blue  = b << 8; /* at 48 bits per pixel, hence the left */
	user_color.green = g << 8; /* shifts */

	/* open the display */
	display = XOpenDisplay(NULL);
	if (display == NULL) {
		fprintf(stderr, "FATAL: could not open display\n");
		exit(1);
	}

	/* fetch the default colormap for the display */
	cmap = DefaultColormap(display, DefaultScreen(display));

	/* setup colors we want to use */
	black_color = BlackPixel(display, DefaultScreen(display));
	white_color = WhitePixel(display, DefaultScreen(display));
	if (XAllocColor(display, cmap, &user_color) == 0){
		fprintf(stderr, "FATAL: failed to allocate color %in", c);
		exit(1);
	}

	/* create the window */
	window = XCreateSimpleWindow(display,
					DefaultRootWindow(display),
					0,
					0,
					COLOR_SIZE,
					COLOR_SIZE + TEXT_BOX_HEIGHT,
					0,
					black_color,
					black_color);

	/* declare the window to be modal (transient) */
	XSetTransientForHint(display, window, window);

	/* set the window title */
	XStoreName(display, window, COLORTOOL_TITLE);

	/* register to receive events */
	XSelectInput(display, window,
		KeyReleaseMask | StructureNotifyMask | VisibilityChangeMask);

	/* place the window on the display */
	XMapWindow(display, window);

	/* create the graphics context to draw on */
	gc = XCreateGC(display, window, 0, NULL);

	/* wait for the window to become ready */
	while (xev.type != MapNotify) { XNextEvent(display, &xev); }

	/* close the window on the first key release event... */
	first_loop = true;
	while (true) {
		XNextEvent(display, &xev);

		if ((xev.type == VisibilityNotify) &&
			(xev.xvisibility.state == VisibilityUnobscured)) {
			/* draw the window contents every time the window
			 * becomes un-obscured */

			/* display the text at the bottom of the window */
			XSetForeground(display, gc, white_color);

			msg = (char*) malloc(MESSAGE_SIZE * sizeof(char));

			snprintf(msg, MESSAGE_SIZE, "%i, %i, %i / #%06x",
				r, g, b, c);

			XDrawString(display, window, gc,
				0, COLOR_SIZE + (TEXT_BOX_HEIGHT * 0.75),
				msg, strlen(msg));

			/* draw the color box */
			XSetForeground(display, gc, user_color.pixel);
			XFillRectangle(display, window, gc,
				0, 0, COLOR_SIZE, COLOR_SIZE);

			/* send commands to the display server */
			XFlush(display);
		}

		if (((! disable_colortool_handler) &&
			(xev.type == KeyRelease)) ||
			(disable_colortool_handler &&
			(xev.type == KeyRelease) &&
			(xev.xkey.keycode == 0x09)))
		{
			if (first_loop && (!disable_colortool_handler)) {
				/* avoid closing instantly on the first
				 * KeyRelease event. We check
				 * disable_colortool_handler so that the first
				 * press of the esc key even when
				 * -n is asserted closes the window */
				first_loop = false;
				continue;
			}
			XCloseDisplay(display);
			exit(0);
		}
	}
}

int main(int argc, char** argv) {

	int c;
	bool display_flag, hex_flag, rgb_flag;
	char* color;
	char* filter;
	char* mask;
	unsigned int color_i;

	color = NULL;

	/* default mask and filter setup - if not overridden, these just do */
	/* nothing at all. */
	STRDUP(filter, "0xFFFFFFFF");
	STRDUP(mask, "0x00000000");

	display_flag = false;
	hex_flag     = false;
	rgb_flag     = false;

	while (1)
	{
		static struct option long_options[] =
		{
			{"version"    , no_argument       , 0 , 'v'} ,
			{"color"      , required_argument , 0 , 'c'} ,
			{"display"    , no_argument       , 0 , 'd'} ,
			{"output_hex" , no_argument       , 0 , 'x'} ,
			{"output_rgb" , no_argument       , 0 , 'r'} ,
			{"noclose"    , no_argument       , 0 , 'n'} ,
			{"mask"       , required_argument , 0 , 'm'} ,
			{"filter"     , required_argument , 0 , 'f'} ,
			{"help"       , no_argument       , 0 , 'h'} ,
			{0            , 0                 , 0 , 0}
		};
		/* getopt_long stores the option index here. */
		int option_index = 0;

		c = getopt_long (argc, argv, "vdc:rxnm:f:",
				long_options, &option_index);

		/* Detect the end of the options. */
		if (c == -1) {
			break;
		}

		switch (c) {
			case 'd':
				display_flag = true;
				break;

			case 'c':
				STRDUP(color, optarg);
				break;

			case 'v':
				printf ("%s\n", VERSION_STRING);
				exit(0);
				break;

			case 'x':
				hex_flag = true;
				break;

			case 'r':
				rgb_flag = true;
				break;

			case 'n':
				disable_colortool_handler = true;
				break;

			case 'm':
				printf("assert m\n");
				strcpy(mask, optarg);
				break;

			case 'f':
				printf("assert f\n");
				strcpy(filter, optarg);
				break;

			case 'h':
				display_help();
				break;

			case '?':
				/* getopt_long already printed an error message. */
				break;

			default:
				fprintf(stderr, "FATAL: invalid parameters\n");
				exit(1);
				break;
		}
	}

	/* parse color */
	color_i = parse_color(color);

	/* apply filter and mask (the default values means nothing happens */
	/* if the user does not provide something different */
	color_i = apply_mask(color_i, mask);
	color_i = apply_filter(color_i, filter);

	/* display in hex format */
	if (hex_flag) {
		printf("#%06x\n", color_i);
	}

	/* display in r,g,b format */
	if (rgb_flag) {
		unsigned char r, g, b;
		u24torgb(color_i, &r, &g, &b);
		printf("%i,%i,%i\n", r, g, b);
	}

	/* display in GUI */
	if (display_flag) {
		display_color(color_i);
		return 0;
	} else {
		return 0;
	}
}

