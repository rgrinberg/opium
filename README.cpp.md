Opium
=====

## Executive Summary

Sinatra like web toolkit for OCaml based on [cohttp](https://github.com/mirage/ocaml-cohttp/) & [lwt](https://github.com/ocsigen/lwt)

## Design Goals

* Opium should be very small and easily learnable. A programmer should
be instantly productive when starting out.

* Opium should be extensible using independently developed plugins. This is a
_Rack_ inspired mechanism borrowed from Ruby. The middleware mechanism in
Opium is called `Rock`.

* It should maximize use of creature comforts people are used to in
other languages. Such as [sexplib](https://github.com/janestreet/sexplib), [fieldslib](https://github.com/janestreet/fieldslib), a decent
standard library.

## Installation

### Stable

The latest stable version is available on opam

```
$ opam install opium
```

### Master

```
$ opam pin add opium_core git+https://github.com/rgrinberg/opium.git
$ opam pin add opium git+https://github.com/rgrinberg/opium.git
```

## Documentation

- Read [the hosted documentation for the latest version][hosted-docs].
- Build and view the docs for version installed locally using [`odig`][odig]:
  `odig doc opium`.

[hosted-docs]: https://rgrinberg.github.io/opium/
[odig]: https://github.com/b0-system/odig

## Examples

All examples are built once the necessary dependencies are installed.
`$ dune build @examples` will compile all examples. The binaries are located in
`_build/default/examples/`

### Hello World

Here's a simple hello world example to get your feet wet:

`$ cat hello_world.ml`

``` ocaml
#include "examples/hello_world.ml"
```

compile with:
```
$ ocamlbuild -pkg opium hello_world.native
```

and then call

    ./hello_world.native &
    curl http://localhost:3000/person/john_doe/42

You should see a JSON message.

### Middleware

The two fundamental building blocks of opium are:

* Handlers: `Rock.Request.t -> Rock.Response.t Lwt.t`
* Middleware: `Rock.Handler.t -> Rock.Handler.t`

Almost every all of opium's functionality is assembled through various
middleware. For example: debugging, routing, serving static files,
etc. Creating middleware is usually the most natural way to extend an
opium app.

Here's how you'd create a simple middleware turning away everyone's
favourite browser.

``` ocaml
#include "examples/middleware_ua.ml"
```

Compile with:

```
$ ocamlbuild -pkg opium middleware_ua.native
```

Here we also use the ability of Opium to generate a cmdliner term to run your
app. Run your executable with the `-h` to see the options that are available to
you. For example:

```
# run in debug mode on port 9000
$ ./middleware_ua.native -p 9000 -d
```
