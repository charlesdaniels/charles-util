MODULES=-M POSIX -M Config -M Config::Tiny -M Time::HiRes -M Net -M Filesys::Df -M Number::Bytes::Human -M Sys::MemInfo -M File::Path::Expand -M Carp
PROG=$(shell basename $$(pwd))
DATE=$(shell date +'%B %Y')
VERSION=$(shell ./$(PROG) --version)

.PHONY: all main clean

generate: $(BIN_DIR) $(MAN_DIR) $(PROG) $(PROG).1
	cp ./$(PROG) $(BIN_DIR)
	mkdir -p $(MAN_DIR)/man1
	cp $(PROG).1 $(MAN_DIR)/man1/

%: %.pl
	pp -x --xargs=--version -o $@ $^

$(PROG).1: $(PROG).1.tr $(PROG)
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(VERSION)/g' > $@

clean:
	rm -f picobar picobar.1
