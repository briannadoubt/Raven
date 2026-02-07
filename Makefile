PREFIX ?= /usr/local
BINARY = .build/release/raven

build:
	swift build -c release --product raven

install: $(BINARY)
	install -d $(PREFIX)/bin
	install $(BINARY) $(PREFIX)/bin/raven

$(BINARY):
	swift build -c release --product raven

uninstall:
	rm -f $(PREFIX)/bin/raven

clean:
	swift package clean

.PHONY: build install uninstall clean
