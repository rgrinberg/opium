.PHONY: default build clean test examples

default: build

build:
	dune build @check

clean:
	dune clean

test:
	dune runtest -f

README.md: README.cpp.md $(wildcard examples/*.ml)
	@cppo -n $< -o $@
