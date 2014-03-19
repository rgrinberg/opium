Opium
=====

## Executive Summary

Sinatra like web toolkit for OCaml based on [cohttp](https://github.com/avsm/ocaml-cohttp/), [core](https://github.com/janestreet/core), & [async](https://github.com/janestreet/async)

## Design Goals

* Opium should be very small easily learnable. A programmer should be
instantly productive when starting out.

* Opium should be extendable using indepedently developed
plugins. This is a _Rack_ inspired mechanism borrowed from Ruby. The
middleware mechanism in Opium is called `Rock`.

* It should maximize use of creature comforts people are used to in
other languages. Such as [sexplib](https://github.com/janestreet/sexplib), [fieldslib](https://github.com/janestreet/fieldslib), [cow](https://github.com/mirage/ocaml-cow), a decent
standard library.

## Installation

__NOTE__: At this point there's a good chance this library will only
work against cohttp master. Once cohttp 1.0 is released then this
library will always be developed against OPAM version.

Make sure you have OPAM. Then clone this repo:

```
$ ./deps
$ oasis setup
$ make
$ make install
```

## Examples

### Hello World

Here's a simple hello world example to get your feet wet:

`$ cat hello_world.ml`

```
#include "examples/hello_world.ml"
```

compile with:
```
$ corebuild -pkg opium hello_world.native
```

### Middleware

The two fundamental building blocks of opium are:

* Handlers: `Rock.Request.t -> Rock.Response.t Deferred.t`
* Middleware: `Rock.Handler.t -> Rock.Handler.t`

Almost every all of opium's functionality is assembled through various
middleware. For example: debugging, routing, serving static files,
etc. Creating middleware is usually the most natural way to extend an
opium app.

Here's how you'd create a simple middleware turning away everyone's
favourite browser.

```
#include "examples/middleware_ua.ml"
```

Here we also use the ability of Opium to generate a core command to
run your app. Run your executable with the `-h` to see the options
that are available to you. For example:

```
# run in debug mode on port 9000
$ ./middleware_ua.native -p 9000 -d
```