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

.PHONY: install
install:
	opam exec -- dune install

.PHONY: test
test:
	opam exec -- dune build @lib_test/runtest -f

.PHONY: clean
clean:
	opam exec -- dune clean

.PHONY: doc
doc:
	opam exec -- dune build @doc

.PHONY: doc-path
doc-path:
	@echo "_build/default/_doc/_html/index.html"

.PHONY: format
format:
	opam exec -- dune build @fmt --auto-promote

.PHONY: watch
watch:
	opam exec -- dune build --watch

.PHONY: utop
utop:
	opam exec -- dune utop lib -- -implicit-bindings

README.md: README.cpp.md $(wildcard examples/*.ml)
	@cppo -n $< -o $@
