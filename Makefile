.DEFAULT_GOAL: all

JBUILDER ?= dune

all:
	@$(JBUILDER) build @install @DEFAULT

check:
	@$(JBUILDER) runtest

test: check

README.md: README.cpp.md $(wildcard examples/*.ml)
	@cppo -n $< -o $@

clean:
	@$(JBUILDER) clean

.PHONY: all clean check test

all-supported-ocaml-versions:
	$(JBUILDER) runtest --workspace dune-workspace.dev
