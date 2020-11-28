.PHONY: all
all:
	opam exec -- dune build @install

.PHONY: dev
dev:
	opam install -y dune-release merlin ocamlformat utop
	opam install --deps-only --with-test --with-doc -y .

.PHONY: build
build:
	opam exec -- dune build

.PHONY: example
example:
	opam exec -- dune build @example

.PHONY: install
install:
	opam exec -- dune install

.PHONY: test
test:
	opam exec -- dune runtest

.PHONY: clean
clean:
	opam exec -- dune clean

.PHONY: doc
doc:
	opam exec -- dune build @doc

.PHONY: doc-path
doc-path:
	@echo "_build/default/_doc/_html/index.html"

.PHONY: fmt
fmt:
	opam exec -- dune build @fmt --auto-promote

.PHONY: watch
watch:
	opam exec -- dune build --watch

.PHONY: utop
utop:
	opam exec -- dune utop . -- -implicit-bindings
