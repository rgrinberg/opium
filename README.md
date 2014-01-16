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

Make sure you have OPAM. Then clone this repo:

```
$ ./deps
$ oasis setup
$ make
$ make install
```

## Example

Here's a simple hello world example to get your feet wet:

`$ cat hello_world.ml`

```
open Core.Std
open Async.Std
open Opium.Std

let print_param = get "/hello/:name" begin fun req ->
  `String ("Hello " ^ Request.param "name") |> respond'
end

let _ = start ~port:3000 [print_param]
```

compile with:
```
$ corebuild -pkg opium hello_world.native
```