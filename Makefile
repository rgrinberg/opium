default: all

build:
	ocaml setup.ml -build

all:
	ocaml setup.ml -all

test:
	ocaml setup.ml -test

doc:
	ocaml setup.ml -doc

clean:
	ocaml setup.ml -clean

install:
	ocaml setup.ml -install

uninstall:
	ocaml setup.ml -uninstall

reinstall:
	ocaml setup.ml -reinstall

.PHONY: build all build default install uninstall
