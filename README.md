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

If you'd like to live on the bleeding edge (which is sometimes more stable than
stable)

```
$ opam pin add opium --dev-repo
```

## Examples

All examples are built once the necessary dependencies are installed.
`$ dune build @examples` will compile all examples. The binaries are located in
`_build/default/examples/`

### Hello World

Here's a simple hello world example to get your feet wet:

`$ cat hello_world.ml`

``` ocaml
open Opium.Std

type person = {
  name: string;
  age: int;
}

let json_of_person { name ; age } =
  let open Ezjsonm in
  dict [ "name", (string name)
       ; "age", (int age) ]

let print_param = put "/hello/:name" begin fun req ->
  `String ("Hello " ^ param req "name") |> respond'
end

let print_person = get "/person/:name/:age" begin fun req ->
  let person = {
    name = param req "name";
    age = "age" |> param req |> int_of_string;
  } in
  `Json (person |> json_of_person) |> respond'
end

let _ =
  App.empty
  |> print_param
  |> print_person
  |> App.run_command
```

compile with:
```
$ ocamlbuild -pkg opium.unix hello_world.native
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
open Opium.Std

(* don't open cohttp and opium since they both define
   request/response modules*)

let is_substring ~substring =
  let re = Re.compile (Re.str substring) in
  Re.execp re

let reject_ua ~f =
  let filter handler req =
    match Cohttp.Header.get (Request.headers req) "user-agent" with
    | Some ua when f ua ->
      `String ("Please upgrade your browser") |> respond'
    | _ -> handler req in
  Rock.Middleware.create ~filter ~name:"reject_ua"

let _ =
  App.empty
  |> get "/" (fun _ -> `String ("Hello World") |> respond')
  |> middleware (reject_ua ~f:(is_substring ~substring:"MSIE"))
  |> App.cmd_name "Reject UA"
  |> App.run_command
```

Compile with:

```
$ ocamlbuild -pkg opium.unix middleware_ua.native
```

Here we also use the ability of Opium to generate a cmdliner term to run your
app. Run your executable with the `-h` to see the options that are available to
you. For example:

```
# run in debug mode on port 9000
$ ./middleware_ua.native -p 9000 -d
```
