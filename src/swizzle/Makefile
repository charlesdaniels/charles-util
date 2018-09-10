DATE=$(shell date +'%B %Y')
VERSION=$(shell ./swizzle.py --version)

generate: $(BIN_DIR) $(MAN_DIR) dist/swizzle swizzle.1
	cp dist/swizzle $(BIN_DIR)
	mkdir -p $(MAN_DIR)/man1
	cp swizzle.1 $(MAN_DIR)/man1/

dist/swizzle: swizzle.py
	pyinstaller --onefile swizzle.py

swizzle.1: swizzle.1.tr
	sed 's/##DATE##/$(DATE)/g' < $< | sed 's/##VERSION##/$(VERSION)/g' > $@

clean:
	rm -rf __pycache__ build dist swizzle.1
