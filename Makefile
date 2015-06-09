default: all

oasis-setup:
	oasis setup

configure: oasis-setup
	ocaml setup.ml -configure --enable-tests

configure-all: oasis-setup
	ocaml setup.ml -configure --enable-tests --enable-examples

configure-no-tests:
	oasis setup
	ocaml setup.ml -configure

build:
	ocaml setup.ml -build

all: README.md
	ocaml setup.ml -all

test: build
	ocaml setup.ml -test

doc:
	ocaml setup.ml -doc

clean:
	ocaml setup.ml -clean

scrub: clean
	ocaml setup.ml -distclean
	rm -rf _tags
	rm -rf myocamlbuild.ml
	rm -rf META
	rm -rf setup.ml

install:
	ocaml setup.ml -install

uninstall:
	ocamlfind remove opium_rock_unix
	ocamlfind remove opium_rock
	ocamlfind remove opium_unix
	ocamlfind remove opium

reinstall:
	ocaml setup.ml -reinstall

README.md: README.cpp.md
	cppo -n -o README.md < README.cpp.md

.PHONY: build all build default install uninstall
