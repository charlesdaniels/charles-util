#include "bytesh.h"

void cmd_write(unsigned int argc, char** argv) {
	unsigned int i, j;
	uint8_t cursor;
	char* cluster;

	/* not necessary, but it makes gcc happy */
	cursor = 0;

	for (i = 0 ; i < argc ; i ++) {
		cluster = argv[i];

		/* cluster length must be a multiple of 2, since each character
		 * is one quartet, and we can only write in bytes */
		if (strlen(cluster) % 2 != 0) {
			printf("ERROR: cluster '%s' length not a multiple of 2.\n", cluster);
			return;
		}

		for (j = 0; j < strlen(cluster); j++) {
			BYTESH_HEX_SQUASH(cluster[j])
			if (j % 2 == 0) {
				/* upper byte */
				cursor = 0;
				cursor += BYTESH_CHAR2INT(cluster[j]) << 4;
			} else {
				/* lower byte */
				cursor += (BYTESH_CHAR2INT(cluster[j]) << 0);
				fputc(cursor, stderr);
			}
		}

	}
}

void eval_line(char* line) {
	char* token;
	char* command = NULL;
	char** argv;
	unsigned int argc;

	/* initialize argv */
	argv = (char**) malloc(sizeof(char*) * BYTESH_MAX_ARGS);
	argc = 0;
	
	/* read the first token */
	token = strtok(line, BYTESH_REPL_TOKEN);

	while (token != NULL) {

		if (command == NULL) {
			STRDUP(command, token);
		} else {
			argv[argc] = token;
			argc ++;
		}

		/* read the next token */
		token = strtok(NULL, BYTESH_REPL_TOKEN);
	}

	if (strcmp(command, "help") == 0) {
		print_help();
	} else if (strcmp(command, "exit") == 0 ||
		strcmp(command, "quit") == 0)  {
		exit(0);
	} else if (strcmp(command, "write") == 0 ||
		strcmp(command, "w") == 0) {
		cmd_write(argc, argv);
	} else {
		printf("Unrecognized command '%s'\n", command);
	}

	free(command);
}

void print_help() {
	printf("available commands:\n\n");
	printf("help . . . . display this message\n\n");
	printf("write/w  . . read HEX characters in space-delimited clusters\n");
	printf("             (length must be a multiple of 2), write the\n");
	printf("             corresponding bytes to standard error. Example:\n");
	printf("             'w ab cd ef 123456' would write the bytes 0xab,\n");
	printf("             0xcd, 0xef, 0x12, 0x34, 0x56 to standard error\n");
	printf("             in that order.\n\n");
	printf("exit/quit  . exit the program\n\n");
}

int main (int argc, char** argv){
	char* s;
	int c;

	while (1)
	{
		static struct option long_options[] =
		{
			{"version"    , no_argument       , 0 , 'v'} ,
			{0            , 0                 , 0 , 0}
		};
		/* getopt_long stores the option index here. */
		int option_index = 0;

		c = getopt_long (argc, argv, "v",
				long_options, &option_index);

		/* Detect the end of the options. */
		if (c == -1) {
			break;
		}

		switch (c) {
			case 'v':
				printf ("%s\n", BYTESH_VERSION);
				exit(0);
				break;

			default:
				fprintf(stderr, "FATAL: invalid parameters\n");
				exit(1);
				break;
		}
	}

	using_history();

	/* main REPL */
	while ((s = readline(BYTESH_PROMPT))) {
		add_history (s);
		eval_line(s);
		free (s);
	}

	return 0;
}
