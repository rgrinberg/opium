.DEFAULT_GOAL := help

PREFIX_ARG := $(if $(PREFIX),--prefix $(PREFIX),)
LIBDIR_ARG := $(if $(LIBDIR),--libdir $(LIBDIR),)
DESTDIR_ARG := $(if $(DESTDIR),--destdir $(DESTDIR),)
INSTALL_ARGS := $(PREFIX_ARG) $(LIBDIR_ARG) $(DESTDIR_ARG)

define BROWSER_PYSCRIPT
import os, webbrowser, sys

from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

-include Makefile.dev

.PHONY: help
help: ## Print the help message
	@echo "Welcome to Opium!"
	@echo "================="
	@echo ""
	@echo "Here are the commands you can use:"
	@echo ""
	@echo "- build       to build the project, including non installable libraries and executables"
	@echo "- test        to run the unit tests"
	@echo "- doc         to generate odoc documentation"
	@echo "- servedoc    to open odoc documentation with default web browser"
	@echo "- release     to release the latest version"

.PHONY: all
all:
	opam exec -- dune build --root . @install

.PHONY: dev
dev: ## Install development dependencies
	opam update
	opam install -y dune-release merlin ocamlformat utop ocaml-lsp-server
	opam install --deps-only --with-test --with-doc -y --locked .

.PHONY: switch
switch: deps ## Create an opam switch and install development dependencies
	opam update
	# Ensuring that either a dev switch already exists or a new one is created
	[[ $(shell opam switch show) == $(shell pwd) ]] || \
		opam switch create -y . 4.11.0 --deps-only --with-test --with-doc
	opam install -y dune-release merlin ocamlformat utop ocaml-lsp-server

.PHONY: lock
lock: ## Generate a lock file
	opam lock -y .

.PHONY: build
build: ## Build the project, including non installable libraries and executables
	opam exec -- dune build --root .

.PHONY: install
install: all ## Install the packages on the system
	opam exec -- dune install --root . $(INSTALL_ARGS) opium

.PHONY: uninstall
uninstall: ## Uninstall the packages from the system
	opam exec -- dune uninstall --root . $(INSTALL_ARGS) opium

.PHONY: test
test: ## Run the unit tests
	opam exec -- dune runtest --root .

.PHONY: clean
clean: ## Clean build artifacts and other generated files
	opam exec -- dune clean --root .

.PHONY: doc
doc: ## Generate odoc documentation
	opam exec -- dune build --root . @doc

.PHONY: servedoc
servedoc: doc ## Open odoc documentation with default web browser
	$(BROWSER) _build/default/_doc/_html/index.html

.PHONY: fmt
fmt: ## Format the codebase with ocamlformat
	opam exec -- dune build --root . --auto-promote @fmt

.PHONY: watch
watch: ## Watch for the filesystem and rebuild on every change
	opam exec -- dune build --root . --watch

.PHONY: utop
utop: ## Run a REPL and link with the project's libraries
	opam exec -- dune utop --root . . -- -implicit-bindings

.PHONY: release
release: ## Release the latest version
	opam exec -- dune-release tag
	opam exec -- dune-release distrib -n opium
	opam exec -- dune-release publish distrib --verbose -n opium
	opam exec -- dune-release opam pkg -n opium
	opam exec -- dune-release opam submit -n opium
