default: all

configure:
	oasis setup
	ocaml setup.ml -configure --enable-tests

build:
	ocaml setup.ml -build

all:
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
	ocaml setup.ml -uninstall

reinstall:
	ocaml setup.ml -reinstall

.PHONY: build all build default install uninstall
