DATE=$(shell date +'%B %Y')
TAGDUMP_VERSION=$(shell ./tagdump.py --version)
TAGSEARCH_VERSION=$(shell ./tagsearch.py --version)

.PHONY: clean

define venv
	sh -c '. .virtualenv/bin/activate ; $(1)'
endef

generate: $(BIN_DIR) $(MAN_DIR) tagdump.1 tagsearch.1 dist/tagdump dist/tagsearch
	cp dist/* $(BIN_DIR)
	mkdir -p $(MAN_DIR)/man1
	cp *.1 $(MAN_DIR)/man1/

dist/%: %.py pip3.log .virtualenv/bin/activate
	$(call venv,pyinstaller --strip --onefile $<)

tagdump.1: tagdump.1.tr
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(TAGDUMP_VERSION)/g' > $@

tagsearch.1: tagsearch.1.tr
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(TAGSEARCH_VERSION)/g' > $@

.virtualenv/bin/activate:
	python3 -m virtualenv --python=python3 .virtualenv

# this is a bit of a hack to give make a decent way of determining if we need
# to install any dependancies
pip3.log: .virtualenv/bin/activate
	$(call venv,pip3 install pyyaml pytaglib pyinstaller 2>&1 | tee pip3.log || rm -f pip3.log)

clean:
	rm -rf __pycache__ build dist $(PROG).1 .virtualenv pip3.log
