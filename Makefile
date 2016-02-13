.DEFAULT: build

build:
	omake

all: build

test:
	omake test

clean:
	rm -rf _build *.omc .omakedb .omakedb.lock

install:
	ocaml setup.ml -install

uninstall:
	ocamlfind remove opium_rock
	ocamlfind remove opium

reinstall:
	ocaml setup.ml -reinstall

.PHONY: all build install uninstall clean test