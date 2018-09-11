PREFIX=$(shell echo $$HOME)/.local
BIN_INSTALL_DIR=$(PREFIX)/bin
MAN_INSTALL_DIR=$(PREFIX)/man
BIN_DIR=$(shell pwd)/bin
MAN_DIR=$(shell pwd)/man
RELEASE_STR=charles-util_R$(shell cat RELEASE)_$(shell uname -m)
RELEASE_TAR=$(RELEASE_STR).tar.xz

info:
	@echo "PREFIX . . . . . . . . $(PREFIX)"
	@echo "BIN_INSTALL_DIR  . . . $(BIN_INSTALL_DIR)"
	@echo "MAN_INSTALL_DIR  . . . $(MAN_INSTALL_DIR)"
	@echo "To install, use make install"

$(BIN_DIR):
	mkdir -p "$(BIN_DIR)"

$(MAN_DIR):
	mkdir -p "$(MAN_DIR)"

$(BIN_INSTALL_DIR):
	mkdir -p "$(BIN_INSTALL_DIR)"

$(MAN_INSTALL_DIR):
	mkdir -p "$(MAN_INSTALL_DIR)"

.PHONY: install generate clean release

install: $(BIN_DIR) $(MAN_DIR) $(BIN_INSTALL_DIR) $(MAN_INSTALL_DIR) generate
	cp "$(BIN_DIR)"/* "$(BIN_INSTALL_DIR)/"
	cp -r "$(MAN_DIR)"/* "$(MAN_INSTALL_DIR)/"

generate: $(BIN_DIR) $(MAN_DIR) $(BIN_INSTALL_DIR) $(MAN_INSTALL_DIR)
	for prog in src/* ; do make BIN_DIR="$(BIN_DIR)" MAN_DIR="$(MAN_DIR)" -C "$$prog" generate ; if [ $$? -ne 0 ] ; then break ; fi  ; done

release: $(RELEASE_TAR)

$(RELEASE_TAR): generate manual.pdf
	rm -f $(RELEASE_TAR)
	tar cfJ "$@" ./bin/ ./man/ ./src/ manual.pdf README.md LICENSE INSTALL RELEASE Makefile

manual.pdf: generate
	bookman -p -t 'charles-util Reference Manual' man/*/* > $@

clean:
	for prog in src/* ; do make BIN_DIR="$(BIN_DIR)" MAN_DIR="$(MAN_DIR)" -C "$$prog" clean ; done
	rm -rf "$(BIN_DIR)" "$(MAN_DIR)" *.tar.xz manual.pdf
