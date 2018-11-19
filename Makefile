PREFIX=/usr/local
MAN_DIR=$(PREFIX)/man/
BIN_DIR=$(PREFIX)/bin/

.PHONY: binaries compile clean install uninstall

binaries: bin/colortool bin/bytesh

compile:
	make -C src all

bin/colortool: compile
	cp src/colortool $@

bin/bytesh: compile
	cp src/bytesh $@

install:
	cp bin/* $(BIN_DIR)
	cp man/*.1 $(MAN_DIR)/man1/

uninstall:
	cd ./man ; for f in ./*.1 ; do rm -f "$(MAN_DIR)/man1/$$f" ; done
	cd ./bin ; for f in ./* ; do rm -f "$(BIN_DIR)/$$f" ; done

clean:
	make -C src clean
	rm -f bin/colortool
	rm -f bin/bytesh
