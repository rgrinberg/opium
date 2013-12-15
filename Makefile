NAME = opium
OCAMLBUILD = ocamlbuild -use-ocamlfind

INSTALL_TARGETS = opium.cma opium.cmxa opium.cmi opium.a

INSTALL = $(addprefix _build/lib/, $(INSTALL_TARGETS))

TARGETS = routes.native sample.native

default: all

build:
	$(OCAMLBUILD) $(INSTALL_TARGETS)
	$(OCAMLBUILD) $(TARGETS)

all: build test

test:
	./routes.native

doc:
	$(OCAMLBUILD) oopium.docdir/index.html

clean:
	$(OCAMLBUILD) -clean

install:
	ocamlfind install $(NAME) META $(INSTALL)

uninstall:
	ocamlfind remove $(NAME)

.PHONY: build all build default install uninstall tags
