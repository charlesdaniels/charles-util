DATE=$(shell date +'%B %Y')
TAGDUMP_VERSION=$(shell ./tagdump.py --version)
TAGSEARCH_VERSION=$(shell ./tagsearch.py --version)

generate: $(BIN_DIR) $(MAN_DIR) tagdump.1 tagsearch.1 dist/tagdump dist/tagsearch
	cp dist/* $(BIN_DIR)
	mkdir -p $(MAN_DIR)/man1
	cp *.1 $(MAN_DIR)/man1/

dist/%: %.py
	pyinstaller --onefile $<

tagdump.1: tagdump.1.tr
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(TAGDUMP_VERSION)/g' > $@

tagsearch.1: tagsearch.1.tr
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(TAGSEARCH_VERSION)/g' > $@

clean:
	rm -rf __pycache__ build dist $(PROG).1
