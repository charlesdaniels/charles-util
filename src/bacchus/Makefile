DATE=$(shell date +'%B %Y')
PROG=bacchus
VERSION=$(shell ./$(PROG).py --version)

generate: $(BIN_DIR) $(MAN_DIR) dist/$(PROG) $(PROG).1
	cp dist/$(PROG) $(BIN_DIR)
	mkdir -p $(MAN_DIR)/man1
	cp $(PROG).1 $(MAN_DIR)/man1/

dist/$(PROG): $(PROG).py
	pyinstaller --strip --onefile $(PROG).py

$(PROG).1: $(PROG).1.tr
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(VERSION)/g' > $@

clean:
	rm -rf __pycache__ build dist $(PROG).1
