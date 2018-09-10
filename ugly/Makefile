BIN_DIR=./bin
PREFIX=$(shell echo $$HOME)
TARGET_SCRIPTS=$(shell ls $(BIN_DIR) | while read -r f ; do echo "$(PREFIX)/bin/$$f" ; done)

info:
	@echo "PREFIX: $(PREFIX)"
	@echo "TARGET_SCRIPTS: $(TARGET_SCRIPTS)"
	@echo ""
	@echo "To install, run 'make PREFIX=/some/prefix install'. Omit"
	@echo "PREFIX to use ~ as the prefix (scripts install to ~/bin)."
	@echo ""
	@echo "To uninstall, run make PREFIX=/some/prefix uninstall"

install: $(TARGET_SCRIPTS)

uninstall:
	rm -f $(TARGET_SCRIPTS)

$(PREFIX)/bin/%: $(BIN_DIR)/% $(PREFIX)/bin
	cp "$<" "$@"
	chmod +x "$@"

$(PREFIX)/bin:
	mkdir -p "$@"
