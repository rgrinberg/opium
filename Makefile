.DEFAULT_GOAL: all

JBUILDER ?= jbuilder

all:
	$(JBUILDER) build

check:
	$(JBUILDER) runtest

test: check

README.md: README.cpp.md $(wildcard examples/*.ml)
		cppo -n $< -o $@

clean:
	rm -rf _build
	find . -iname "*.merlin" -o -iname "*.install" -delete

.PHONY: all clean check test opam-opium opam-opium_kernel
