DATE=$(shell date +'%B %Y')
VERSION=$(shell ./$(PROG).py --version)

PDFUTIL_BINARIES=pdfutil-combine pdfutil-from-office pdfutil-scrub pdfutil-optimize
PDFUTIL_MAN=pdfutil-combine.1 pdfutil-from-office.1 pdfutil-scrub.1 pdfutil-optimize.1

generate: $(BIN_DIR) $(MAN_DIR) $(PDFUTIL_BINARIES) $(PDFUTIL_MAN)
	cp $(PDFUTIL_BINARIES) "$(BIN_DIR)/"
	mkdir -p $(MAN_DIR)/man1
	cp $(PDFUTIL_MAN) $(MAN_DIR)/man1/

%.1: %
	./extract_doc.sh "$<" | pandoc -s -t man -f rst /dev/stdin -o $@

clean:
	rm -rf *.1
