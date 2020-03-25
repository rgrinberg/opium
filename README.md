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
$ opam pin add opium_kernel --dev-repo
$ opam pin add opium --dev-repo
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

Assuming the necessary dependencies are installed, `$ dune build @examples` will
compile all examples. The binaries are located in `_build/default/examples/`.

You can execute these binaries directly, though in the examples below we use
`dune exec` to run them.

### Hello World

Here's a simple hello world example to get your feet wet:

`$ cat hello_world.ml`

``` ocaml
open Opium.Std

type person = {name: string; age: int}

let json_of_person {name; age} =
  let open Ezjsonm in
  dict [("name", string name); ("age", int age)]

let print_param =
  put "/hello/:name" (fun req ->
      `String ("Hello " ^ param req "name") |> respond')

let streaming =
  let open Lwt.Infix in
  get "/hello/stream" (fun _req ->
      (* [create_stream] returns a push function that can be used to
         push new content onto the stream. [f] is function that
         expects to receive a promise that gets resolved when the user
         decides that they have pushed all their content onto the stream.
         When the promise forwarded to [f] gets resolved, the stream will be
         closed. *)
      let f, push = App.create_stream () in
      let timers =
        List.map
          (fun t ->
            Lwt_unix.sleep t
            >|= fun () -> push (Printf.sprintf "Hello after %f seconds\n" t))
          [1.; 2.; 3.]
      in
      f (Lwt.join timers))

let default =
  not_found (fun _req ->
      `Json Ezjsonm.(dict [("message", string "Route not found")]) |> respond')

let print_person =
  get "/person/:name/:age" (fun req ->
      let person =
        {name= param req "name"; age= "age" |> param req |> int_of_string}
      in
      `Json (person |> json_of_person) |> respond')

let _ =
  App.empty |> print_param |> print_person |> streaming |> default
  |> App.run_command
```

compile and run with:

```sh
$ dune exec examples/hello_world.exe &
```

then call

```sh
curl http://localhost:3000/person/john_doe/42
```

You should see the JSON message

```json
{"name":"john_doe","age":42}
```

### Middleware

The two fundamental building blocks of opium are:

* Handlers: `Rock.Request.t -> Rock.Response.t Lwt.t`
* Middleware: `Rock.Handler.t -> Rock.Handler.t`

Almost all of opium's functionality is assembled through various
middleware. For example: debugging, routing, serving static files,
etc. Creating middleware is usually the most natural way to extend an
opium app.

Here's how you'd create a simple middleware turning away everyone's
favourite browser.

``` ocaml
open Opium.Std

(* don't open cohttp and opium since they both define request/response modules*)

let is_substring ~substring =
  let re = Re.compile (Re.str substring) in
  Re.execp re

let reject_ua ~f =
  let filter handler req =
    match Cohttp.Header.get (Request.headers req) "user-agent" with
    | Some ua when f ua -> `String "Please upgrade your browser" |> respond'
    | _ -> handler req
  in
  Rock.Middleware.create ~filter ~name:"reject_ua"

let _ =
  App.empty
  |> get "/" (fun _ -> `String "Hello World" |> respond')
  |> middleware (reject_ua ~f:(is_substring ~substring:"MSIE"))
  |> App.cmd_name "Reject UA" |> App.run_command
```

Compile with:

```sh
$ dune build examples/middleware_ua.ml
```

Here we also use the ability of Opium to generate a cmdliner term to run your
app. Run your executable with `-h` to see the options that are available to you.
For example:

```
# run in debug mode on port 9000
$ dune exec examples/middleware_ua.exe -- -p 9000 -d
```
