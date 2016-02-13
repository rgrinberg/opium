.DEFAULT: build

build:
	@omake

all: build

check:
	@omake check

clean:
	rm -rf _build *.omc .omakedb .omakedb.lock

install:
	@omake install

uninstall:
	@omake uninstall

.PHONY: all build install uninstall clean check