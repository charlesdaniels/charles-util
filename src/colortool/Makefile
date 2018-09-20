PROG=$(shell basename $$(pwd))
DATE=$(shell date +'%B %Y')
VERSION=$(shell ./$(PROG) --version)

.PHONY: clean

generate: $(BIN_DIR) $(MAN_DIR) $(PROG) $(PROG).1
	cp ./$(PROG) $(BIN_DIR)
	mkdir -p $(MAN_DIR)/man1
	cp $(PROG).1 $(MAN_DIR)/man1/

colortool: colortool.cxx
	fltk-config --compile $^
	strip --strip-unneeded colortool

$(PROG).1: $(PROG).1.tr $(PROG)
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(VERSION)/g' > $@
clean:
	rm -rf $(PROG) $(PROG).1 *.gch *.o
