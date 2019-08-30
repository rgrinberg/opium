---
layout: default
title: Middlewares
nav_order: 2
permalink: /middlewares
---
# Middlewares

The two fundamental building blocks of opium are:

* Handlers: `Rock.Request.t -> Rock.Response.t Lwt.t`
* Middleware: `Rock.Handler.t -> Rock.Handler.t`

Almost all of opium's functionality is assembled through various middleware. For example: debugging, routing, serving static files, etc. Creating middleware is usually the most natural way to extend an opium app.

## Writing middleware

Here's how you'd create a simple middleware turning away everyone's favourite browser.

```ocaml
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
```

## Using middleware

To use the `reject_ua` middleware you can use the `middleware` builder from the Opium.Std.App module.

```ocaml
let () =
  App.empty
  |> get "/" (fun _ -> `String ("Hello World") |> respond')
  |> middleware (reject_ua ~f:(is_substring ~substring:"MSIE"))
  |> App.cmd_name "Reject UA"
  |> App.run_command
```
