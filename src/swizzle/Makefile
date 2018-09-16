PROG=swizzle
DATE=$(shell date +'%B %Y')
VERSION=$(shell ./$(PROG).py --version)

.PHONY: clean

define venv
	sh -c '. .virtualenv/bin/activate ; $(1)'
endef

generate: $(BIN_DIR) $(MAN_DIR) dist/$(PROG) $(PROG).1
	cp dist/$(PROG) $(BIN_DIR)
	mkdir -p $(MAN_DIR)/man1
	cp $(PROG).1 $(MAN_DIR)/man1/

dist/$(PROG): $(PROG).py pip3.log .virtualenv/bin/activate
	$(call venv,pyinstaller --strip --onefile $(PROG).py)

$(PROG).1: $(PROG).1.tr
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(VERSION)/g' > $@

.virtualenv/bin/activate:
	virtualenv --python=python3 .virtualenv

# this is a bit of a hack to give make a decent way of determining if we need
# to install any dependancies
pip3.log: .virtualenv/bin/activate
	$(call venv,pip3 install pyinstaller 2>&1 | tee pip3.log)

clean:
	rm -rf __pycache__ build dist $(PROG).1 .virtualenv pip3.log
