DATE=$(shell date +'%B %Y')
VERSION=$(shell ./$(PROG).py --version)

PDFUTIL_BINARIES=$(shell ls pdfutil* | grep -v '\.1$$')
PDFUTIL_MAN=$(shell ls pdfutil* | grep -v '\.1$$' | while read -r ln ; do echo "$$ln.1" ; done)

generate: $(BIN_DIR) $(MAN_DIR) $(PDFUTIL_BINARIES) $(PDFUTIL_MAN)
	cp $(PDFUTIL_BINARIES) "$(BIN_DIR)/"
	mkdir -p $(MAN_DIR)/man1
	cp $(PDFUTIL_MAN) $(MAN_DIR)/man1/

%.1: %
	./extract_doc.sh "$<" | pandoc -s -t man -f rst /dev/stdin -o $@

clean:
	rm -rf *.1
