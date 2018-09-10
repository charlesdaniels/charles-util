PREFIX=$(shell echo $$HOME)/.local
BIN_INSTALL_DIR=$(PREFIX)/bin
MAN_INSTALL_DIR=$(PREFIX)/man
BIN_DIR=$(shell pwd)/bin
MAN_DIR=$(shell pwd)/man

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

.PHONY: install generate clean

install: $(BIN_DIR) $(MAN_DIR) $(BIN_INSTALL_DIR) $(MAN_INSTALL_DIR) generate
	cp "$(BIN_DIR)"/* "$(BIN_INSTALL_DIR)/"
	cp -r "$(MAN_DIR)"/* "$(MAN_INSTALL_DIR)/"

generate: $(BIN_DIR) $(MAN_DIR) $(BIN_INSTALL_DIR) $(MAN_INSTALL_DIR)
	for prog in src/* ; do make BIN_DIR="$(BIN_DIR)" MAN_DIR="$(MAN_DIR)" -C "$$prog" generate ; done

clean:
	for prog in src/* ; do make BIN_DIR="$(BIN_DIR)" MAN_DIR="$(MAN_DIR)" -C "$$prog" clean ; done
	rm -rf "$(BIN_DIR)" "$(MAN_DIR)"
