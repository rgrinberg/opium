Opium
=====

The current master branch is a WIP port to httpaf. If you are looking for the last version published to opam (that was using Cohttp), please take a look at https://github.com/rgrinberg/opium/tree/0.18.0

## Executive Summary

Sinatra like web toolkit for OCaml based on [httpaf](https://github.com/inhabitedtype/httpaf/) & [lwt](https://github.com/ocsigen/lwt)

## Design Goals

* Opium should be very small and easily learnable. A programmer should
be instantly productive when starting out.

* Opium should be extensible using independently developed plugins. This is a
_Rack_ inspired mechanism borrowed from Ruby. The middleware mechanism in
Opium is called `Rock`.

## Installation

### Stable

The latest stable version is available on opam

```
$ opam install opium
```

### Master

```
$ opam pin add rock.~dev https://github.com/rgrinberg/opium.git
$ opam pin add opium.~dev https://github.com/rgrinberg/opium.git
```

## Documentation

For the **API documentation**:

- Read [the hosted documentation for the latest version][hosted-docs].
- Build and view the docs for version installed locally using [`odig`][odig]:
  `odig doc opium`.

The following **tutorials** walk through various usecases of Opium:

- [A Lightweight OCaml Webapp Tutorial](https://shonfeder.gitlab.io/ocaml_webapp/) 
  covers a simple webapp generating dynamic HTML on the backend and 
  interfacing with PostgreSQL.

For **examples** of idiomatic usage, see the [./examples directory](./examples)
and the simple examples below.

[hosted-docs]: https://rgrinberg.github.io/opium/
[odig]: https://github.com/b0-system/odig

## Examples

Assuming the necessary dependencies are installed, `$ dune build @example` will
compile all examples. The binaries are located in `_build/default/example/`.

You can execute these binaries directly, though in the examples below we use
`dune exec` to run them.

### Hello World

Here's a simple hello world example to get your feet wet:

`$ cat hello_world.ml`

``` ocaml
#include "example/hello_world/main.ml"
```

compile and run with:

```sh
$ dune exec examples/hello_world.exe &
```

then call

```sh
curl http://localhost:3000/person/john_doe/42 
```

You should see the greeting

```json
{"name":"john_doe","age":42}
```

### Middleware

The two fundamental building blocks of opium are:

* Handlers: `Request.t -> Response.t Lwt.t`
* Middleware: `Rock.Handler.t -> Rock.Handler.t`

Almost all of opium's functionality is assembled through various
middleware. For example: debugging, routing, serving static files,
etc. Creating middleware is usually the most natural way to extend an
opium app.

Here's how you'd create a simple middleware turning away everyone's
favourite browser.

``` ocaml
#include "example/simple_middleware/main.ml"
```

Compile with:

```sh
$ dune build example/simple_middleware/main.ml
```

Here we also use the ability of Opium to generate a cmdliner term to run your
app. Run your executable with `-h` to see the options that are available to you.
For example:

```
# run in debug mode on port 9000
$ dune exec dune build example/simple_middleware/main.exe -- -p 9000 -d
```
