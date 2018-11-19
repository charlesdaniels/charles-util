#ifndef BYTESH_H
#define BYTESH_H

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <string.h>
#include <stdint.h>
#include <getopt.h>

#define BYTESH_PROMPT "bytesh> "
#define BYTESH_REPL_TOKEN " "
#define BYTESH_MAX_ARGS 128

/* strdup is a GNU extension, not part of the ANSI spec */
#define STRDUP(dst, src) dst = (char*) malloc (sizeof(char) * strlen(src)); strcpy(dst, src)

/* cleanup mixed-case hex to all uppercase */
#define BYTESH_HEX_SQUASH(c) if (c >= 97 && c <= 102) {c -= 32;}

/* true if c is an ASCII decimal digit */
#define BYTESH_IS_DEC_DIGIT(c) ((c >= 48) && (c <= 57))

/* if the char is a decimal digit, we just subtract 48, otherwise it must be
 * a hex digit in the A..F range, so we subtract 65 (A=0), and add 10 (A=10) */
#define BYTESH_CHAR2INT(c) ((BYTESH_IS_DEC_DIGIT(c)) ? c - 48 : (c - 65) + 10)

#define BYTESH_VERSION "0.0.1"

void cmd_write(unsigned int argc, char** argv);
void eval_line(char* line);
void print_help();

#endif
