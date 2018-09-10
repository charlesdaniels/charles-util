DATE=$(shell date +'%B %Y')
PROG=disavow
VERSION=$(shell ./$(PROG).py --version)

generate: $(BIN_DIR) $(MAN_DIR) $(PROG) $(PROG).1
	cp $(PROG) $(BIN_DIR)
	mkdir -p $(MAN_DIR)/man1
	cp $(PROG).1 $(MAN_DIR)/man1/

$(PROG).1: $(PROG).1.tr
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(VERSION)/g' > $@

clean:
	rm -rf $(PROG).1
