DATE=$(shell date +'%B %Y')
TAGDUMP_VERSION=$(shell ./tagdump.py --version)
TAGSEARCH_VERSION=$(shell ./tagsearch.py --version)
USE_PYINSTALLER=0

.PHONY: clean

define venv
	sh -c '. .virtualenv/bin/activate ; $(1)'
endef

generate: $(BIN_DIR) $(MAN_DIR) tagdump.1 tagsearch.1 dist/tagdump dist/tagsearch
	cp dist/* $(BIN_DIR)
	mkdir -p $(MAN_DIR)/man1
	cp *.1 $(MAN_DIR)/man1/

dist/%: %.py pip3.log .virtualenv/bin/activate
	mkdir -p dist
	if [ $(USE_PYINSTALLER) -eq 0 ] ; then $(call venv,pyinstaller --strip --onefile %.py) ; else cp $< $@ ; fi

tagdump.1: tagdump.1.tr
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(TAGDUMP_VERSION)/g' > $@

tagsearch.1: tagsearch.1.tr
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(TAGSEARCH_VERSION)/g' > $@

.virtualenv/bin/activate:
	mkdir -p .virtualenv/bin
	if [ $(USE_PYINSTALLER) -eq 0 ] ; then python3 -m virtualenv --python=python3 .virtualenv ; else touch $@ ; fi

# this is a bit of a hack to give make a decent way of determining if we need
# to install any dependancies
pip3.log: .virtualenv/bin/activate
	if [ $(USE_PYINSTALLER) -eq 0 ] ; then $(call venv,pip3 install pyinstaller 2>&1 | tee pip3.log) ; else touch $@ ; fi

clean:
	rm -rf __pycache__ build dist $(PROG).1 .virtualenv pip3.log
