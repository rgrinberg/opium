.DEFAULT: build

build:
	@omake -j4 -s --no--print-status --output-only-errors

opam:
	@omake

all: build

check:
	@omake -j4 check --no--print-status --output-only-errors

test: check

clean:
	@omake clean
	@rm -rf *.omc .omakedb .omakedb.lock

install:
	@omake install

uninstall:
	@omake uninstall

.PHONY: all build install uninstall clean check test