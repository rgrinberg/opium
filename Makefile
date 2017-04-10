.DEFAULT_GOAL: all

JBUILDER ?= jbuilder

all:
	$(JBUILDER) build

check:
	$(JBUILDER) runtest

test: check

clean:
	rm -rf _build
	find . -iname "*.merlin" -o -iname "*.install" -delete

.PHONY: all clean check test opam-opium opam-opium_kernel
