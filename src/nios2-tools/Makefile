DATE=$(shell date +'%B %Y')

NIOS2_SEARCH_VERSION=$(shell ./nios2-search.py --version)
NIOS2_SH_VERSION=$(shell ./nios2-sh version)

generate: $(BIN_DIR) $(MAN_DIR) dist/nios2-search nios2-sh nios2-search.1 nios2-sh.1
	cp dist/* $(BIN_DIR)
	cp nios2-sh $(BIN_DIR)
	mkdir -p $(MAN_DIR)/man1
	cp *.1 $(MAN_DIR)/man1/

dist/nios2-search: nios2-search.py
	pyinstaller --strip --onefile $<

nios2-search.1: nios2-search.1.tr
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(NIOS2_SEARCH_VERSION)/g' > $@

nios2-sh.1: nios2-sh.1.tr
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(NIOS2_SH_VERSION)/g' > $@

clean:
	rm -rf __pycache__ build dist $(PROG).1
