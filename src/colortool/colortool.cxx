#include <FL/Fl.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_Button.H>
#include <FL/Enumerations.H>
#include <FL/fl_draw.H>
#include <FL/Fl_Text_Display.H>

#include <getopt.h>
#include <iostream>
#include <string.h>
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <climits>

// number of pixels for the colored box
#define COLOR_SIZE 150

// number of pixels high the text box should be
#define TEXT_BOX_HEIGHT 50

// current program version
#define VERSION_STRING "1.0.0"

using namespace std;

// global flag that prevents the handler from causing an exit
bool disable_colortool_handler = false;

static long strtol_safe (const char *str, int base) {
	/* either parse the string, or die trying */

	char *endptr;
	long val;

	// reset errno
	errno = 0;

	// attempt to parse
	val = strtol(str, &endptr, base);

	// check if there was any error
	if (endptr== str ||
	    *endptr != '\0' ||
	    ((val == LONG_MIN || val == LONG_MAX) && errno == ERANGE)) {

		fprintf(stderr,
			"FATAL: invalid long int '%s' with base %i\n",
			str,
			base,
			endptr
		);
		exit(1);
	}
	return val;
}

int colortool_handler (int event) {
	/* handler that causes the program to close, this is how colortool
	 * closes on any keyperess */
	
	if (disable_colortool_handler) {return 1;}

	if (event == FL_KEYDOWN ||
	    event == FL_SHORTCUT ||
	    event == FL_KEYUP ) {
		/* only exit on keypress events */
		exit(0);
	}
}

class Drawing : public Fl_Widget {
	/* Widget that draws a box of the specified RGB color */

	unsigned char r, g, b;

	public:
	Drawing(int X,int Y,int W,int H) : Fl_Widget(X,Y,W,H) {
		// register the event handler to close on keypress
		Fl::add_handler(colortool_handler);
	}
	void set_color(unsigned char r, unsigned char g, unsigned char b) {
		this->r = r;
		this->g = g;
		this->b = b;
	}
	private:
	void draw() {
		Fl_Color c = fl_rgb_color(r, g, b);
		fl_color(c);
		fl_rectf(0,0, COLOR_SIZE, COLOR_SIZE);
	}
};

inline unsigned int rgbtou24(unsigned char r, unsigned char g, unsigned char b) {
	/* cast a set of separate u8 r g b values into one integer */

	unsigned int c;
	c = 0;
	c += r << 16;
	c += g << 8;
	c += b;
	return c;
}

inline void u24torgb(unsigned int c, unsigned char* r, unsigned char* g, unsigned char* b) {
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

inline unsigned int apply_mask(unsigned int c, char* mask) {
	/* Takes a mask in as a hex string and binary OR it with the color.
	 * The string is hard-coded as base 16, and specifies the mask in
	 * the format 0x00RRGGBB. */

	return c | strtol_safe(mask, 16);
}

inline unsigned int apply_filter(unsigned int c, char* filter) {
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
\n\
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
\n\
--mask [mask] / -m [mask]\n\
	Apply a mask to the specified color before handling -d, -x, or -r. \n\
	The mask is specified in 0xRRGGBB format, and is binary OR-ed with \n\
	the color. Note that the mask specified with -m is applied before the\n\
	filter specified by -f. \n\
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

int display_color(unsigned int c) {
	/* Display a window using FLTK with a box showing the desired
	 * color. */

	// convert the color to r, g, b format for the drawing widget
	unsigned char r, g, b;
	u24torgb(c, &r, &g, &b);

	// setup the window
	Fl_Window *window = new Fl_Window(COLOR_SIZE,
	                                  COLOR_SIZE + TEXT_BOX_HEIGHT,
	                                  "colortool");


	// center the window on the display
	window->position((Fl::w() - window->w())/2, (Fl::h() - window->h())/2);

	// setup the drawing canvas
	Drawing canvas(0, 0, COLOR_SIZE, COLOR_SIZE);
	canvas.set_color(r, g, b);

	// generate a string showing the color in R,G,B and hex formats
	char* color_str;
	color_str = (char*) malloc(128 * sizeof(char));
	sprintf(color_str, "%i, %i, %i\n#%06x", r, g, b, c);

	// create the text display widget and insert color_str into the
	// buffer so it is shown on the screen
	Fl_Text_Buffer *buff = new Fl_Text_Buffer();
	Fl_Text_Display *disp = new Fl_Text_Display(0,
	                                            COLOR_SIZE,
	                                            COLOR_SIZE,
	                                            TEXT_BOX_HEIGHT,
	                                            "");
	disp->buffer(buff);
	buff->text(color_str);

	// Make the window visible and start processing events
	window->end();
	window->show();
	return Fl::run();
}

int main(int argc, char** argv) {

	int c;
	bool display_flag, hex_flag, rgb_flag;
	char* color;
	char* filter;
	char* mask;
	color = NULL;

	unsigned int color_i;

	// default mask and filter setup - if not overridden, these just do
	// nothing at all.
	filter = strdup("0xFFFFFFFF");
	mask   = strdup("0x00000000");

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
				color = strdup(optarg);
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

	// parse color
	color_i = parse_color(color);

	// apply filter and mask (the default values means nothing happens
	// if the user does not provide something different
	color_i = apply_mask(color_i, mask);
	color_i = apply_filter(color_i, filter);

	// display in hex format
	if (hex_flag) {
		printf("#%06x\n", color_i);
	}

	// display in r,g,b format
	if (rgb_flag) {
		unsigned char r, g, b;
		u24torgb(color_i, &r, &g, &b);
		printf("%i,%i,%i\n", r, g, b);
	}

	// display in GUI
	if (display_flag) {
		return display_color(color_i);
	} else {
		return 0;
	}
}

