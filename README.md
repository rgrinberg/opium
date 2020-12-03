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
open Opium

module Person = struct
  type t =
    { name : string
    ; age : int
    }

  let yojson_of_t t = `Assoc [ "name", `String t.name; "age", `Int t.age ]

  let t_of_yojson yojson =
    match yojson with
    | `Assoc [ ("name", `String name); ("age", `Int age) ] -> { name; age }
    | _ -> failwith "invalid person json"
  ;;
end

let print_person_handler req =
  let name = Router.param req "name" in
  let age = Router.param req "age" |> int_of_string in
  let person = { Person.name; age } |> Person.yojson_of_t in
  Lwt.return (Response.of_json person)
;;

let update_person_handler req =
  let open Lwt.Syntax in
  let+ json = Request.to_json_exn req in
  let person = Person.t_of_yojson json in
  Logs.info (fun m -> m "Received person: %s" person.Person.name);
  Response.of_json (`Assoc [ "message", `String "Person saved" ])
;;

let streaming_handler req =
  let length = Body.length req.Request.body in
  let content = Body.to_stream req.Request.body in
  let body = Lwt_stream.map String.uppercase_ascii content in
  Response.make ~body:(Body.of_stream ?length body) () |> Lwt.return
;;

let print_param_handler req =
  Printf.sprintf "Hello, %s\n" (Router.param req "name")
  |> Response.of_plain_text
  |> Lwt.return
;;

let _ =
  App.empty
  |> App.post "/hello/stream" streaming_handler
  |> App.get "/hello/:name" print_param_handler
  |> App.get "/person/:name/:age" print_person_handler
  |> App.patch "/person" update_person_handler
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

* Handlers: `Request.t -> Response.t Lwt.t`
* Middleware: `Rock.Handler.t -> Rock.Handler.t`

Almost all of opium's functionality is assembled through various
middleware. For example: debugging, routing, serving static files,
etc. Creating middleware is usually the most natural way to extend an
opium app.

Here's how you'd create a simple middleware turning away everyone's
favourite browser.

``` ocaml
open Opium

module Reject_user_agent = struct
  let is_ua_msie =
    let re = Re.compile (Re.str "MSIE") in
    Re.execp re
  ;;

  let m =
    let filter handler req =
      match Request.header "user-agent" req with
      | Some ua when is_ua_msie ua ->
        Response.of_plain_text ~status:`Bad_request "Please upgrade your browser"
        |> Lwt.return
      | _ -> handler req
    in
    Rock.Middleware.create ~filter ~name:"Reject User-Agent"
  ;;
end

let index_handler _request = Response.of_plain_text "Hello World!" |> Lwt.return

let _ =
  App.empty
  |> App.get "/" index_handler
  |> App.middleware Reject_user_agent.m
  |> App.cmd_name "Reject UA"
  |> App.run_command
;;
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
