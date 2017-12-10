.DEFAULT_GOAL: all

JBUILDER ?= jbuilder

all:
	@$(JBUILDER) build --dev @install @DEFAULT

check:
	@$(JBUILDER) runtest --dev

test: check

README.md: README.cpp.md $(wildcard examples/*.ml)
	@cppo -n $< -o $@

clean:
	@$(JBUILDER) clean

.PHONY: all clean check test
