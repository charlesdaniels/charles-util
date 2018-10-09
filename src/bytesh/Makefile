PROG=$(shell basename $$(pwd))
DATE=$(shell date +'%B %Y')
VERSION=$(shell ./$(PROG) --version)

CC=gcc
CFLAGS=-Wall -Wextra -pedantic -std=c99 -O3 -lreadline -fgnu89-inline -lcurses

generate: $(BIN_DIR) $(MAN_DIR) $(PROG) $(PROG).1
	cp ./$(PROG) $(BIN_DIR)
	mkdir -p $(MAN_DIR)/man1
	cp $(PROG).1 $(MAN_DIR)/man1/

.PHONY: clean

$(PROG).1: $(PROG).1.tr $(PROG)
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(VERSION)/g' > $@

$(PROG): $(PROG).c $(PROG).h
	$(CC) $(CFLAGS) -o $@ $^


clean:
	rm -f *.o
	rm -f *.gch
	rm -f bytesh
