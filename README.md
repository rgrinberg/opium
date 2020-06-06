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
open Lwt.Syntax

module Person = struct
  type t =
    { name : string
    ; age : int
    }
  [@@deriving yojson]
end

let print_person =
  get "/person/:name/:age" (fun req ->
      let person =
        { Person.name = param req "name"; age = "age" |> param req |> int_of_string }
        |> Person.yojson_of_t
      in
      Lwt.return (Response.of_json person))
;;

let update_person =
  patch "/person" (fun req ->
      let+ json = App.json_of_body_exn req in
      let person = Person.t_of_yojson json in
      Logs.info (fun m -> m "Received person: %s" person.Person.name);
      Response.of_json (`Assoc [ "message", `String "Person saved" ]))
;;

let streaming =
  post "/hello/stream" (fun req ->
      let { Opium_kernel.Body.length; _ } = req.Request.body in
      let content = Opium_kernel.Body.to_stream req.Request.body in
      let body = Lwt_stream.map String.uppercase_ascii content in
      Response.make ~body:(Opium_kernel.Body.of_stream ?length body) () |> Lwt.return)
;;

let print_param =
  get "/hello/:name" (fun req ->
      Lwt.return (Response.of_string @@ Printf.sprintf "Hello, %s\n" (param req "name")))
;;

let _ =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Debug);
  App.empty
  |> streaming
  |> print_param
  |> print_person
  |> update_person
  |> App.run_command
;;
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

let is_substring ~substring =
  let re = Re.compile (Re.str substring) in
  Re.execp re
;;

let reject_ua ~f =
  let filter handler req =
    match Httpaf.Headers.get req.Request.headers "user-agent" with
    | Some ua when f ua ->
      Response.make
        ~status:`Bad_request
        ~body:(Opium_kernel.Body.of_string "Please upgrade your browser\n")
        ()
      |> Lwt.return
    | _ -> handler req
  in
  Rock.Middleware.create ~filter ~name:"reject_ua"
;;

let _ =
  App.empty
  |> get "/" (fun _ ->
         Response.make ~body:(Opium_kernel.Body.of_string "Hello World\n") ()
         |> Lwt.return)
  |> middleware (reject_ua ~f:(is_substring ~substring:"MSIE"))
  |> App.cmd_name "Reject UA"
  |> App.run_command
;;
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
