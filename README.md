Opium
=====

## Executive Summary

Sinatra like web toolkit for OCaml based on [cohttp](https://github.com/avsm/ocaml-cohttp/), [core](https://github.com/janestreet/core), & [async](https://github.com/janestreet/async)

## Design Goals

* Opium should be very small and easily learnable. A programmer should
be instantly productive when starting out.

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
open Core.Std
open Async.Std
open Cow
open Opium.Std

module Person = struct
  (* this hack is needed because cow is relying on functions shadowed
     by core *)
  open Caml
  type t = {
    name: string;
    age: int; } with json
end

let print_param = put "/hello/:name" begin fun req ->
  `String ("Hello " ^ param req "name") |> respond'
end

let print_person = get "/person/:name/:age" begin fun req ->
  let person = {
    Person.name = param req "name";
    age = "age" |> param req |> Int.of_string;
  } in
  `Json (Person.json_of_t person) |> respond'
end

let _ =
  App.empty
  |> print_param
  |> print_person
  |> App.command
  |> Command.run
```

compile with:
```
$ corebuild -pkg opium,cow.syntax hello_world.native
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
open Core.Std
open Async.Std
open Opium.Std
(* don't open cohttp and opium since they both define
   request/response modules*)

let is_substring ~substring s =
  Option.is_some @@ String.substr_index s ~pattern:substring

let reject_ua ~f =
  let filter handler req =
    match Cohttp.Header.get (Request.headers req) "user-agent" with
    | Some ua when f ua ->
      Log.Global.info "Rejecting %s" ua;
      `String ("Please upgrade your browser") |> respond'
    | _ -> handler req in
  Rock.Middleware.create ~filter ~name:(Info.of_string "reject_ua")

let _ = App.empty
        |> get "/" (fun req -> `String ("Hello World") |> respond')
        |> middleware @@ reject_ua ~f:(is_substring ~substring:"MSIE")
        |> App.cmd_name "Reject UA"
        |> App.command
        |> Command.run

```

Compile with:

```
$ corebuild -pkg opium,pcre middleware_ua.native
```

Here we also use the ability of Opium to generate a core command to
run your app. Run your executable with the `-h` to see the options
that are available to you. For example:

```
# run in debug mode on port 9000
$ ./middleware_ua.native -p 9000 -d
```