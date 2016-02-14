.DEFAULT: build

build:
	@omake -j4

all: build

check:
	@omake -j4 check

clean:
	rm -rf _build *.omc .omakedb .omakedb.lock

install:
	@omake install

uninstall:
	@omake uninstall

.PHONY: all build install uninstall clean check