DATE=$(shell date +'%B %Y')

NIOS2_SEARCH_VERSION=$(shell ./nios2-search.py --version)
NIOS2_SH_VERSION=$(shell ./nios2-sh version)

define venv
	sh -c '. .virtualenv/bin/activate ; $(1)'
endef

.PHONY: clean

generate: $(BIN_DIR) $(MAN_DIR) dist/nios2-search nios2-sh nios2-search.1 nios2-sh.1
	cp dist/* $(BIN_DIR)
	cp nios2-sh $(BIN_DIR)
	mkdir -p $(MAN_DIR)/man1
	cp *.1 $(MAN_DIR)/man1/

dist/nios2-search: nios2-search.py pip3.log .virtualenv/bin/activate
	$(call venv,pyinstaller --strip --onefile $<)

nios2-search.1: nios2-search.1.tr
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(NIOS2_SEARCH_VERSION)/g' > $@

nios2-sh.1: nios2-sh.1.tr
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(NIOS2_SH_VERSION)/g' > $@

.virtualenv/bin/activate:
	virtualenv --python=python3 .virtualenv

# this is a bit of a hack to give make a decent way of determining if we need
# to install any dependancies
pip3.log: .virtualenv/bin/activate
	$(call venv,pip3 install appdirs pyinstaller 2>&1 | tee pip3.log)

clean:
	rm -rf __pycache__ build dist *.1 .virtualenv pip3.log
