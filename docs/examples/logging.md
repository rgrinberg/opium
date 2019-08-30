---
layout: default
title: Logging
parent: Examples
nav_order: 1
permalink: /examples/logging
---

# Logging

Opium uses the [logs](https://github.com/dbuenzli/logs) library for its logging needs.
The application will need to configure what log level to specify for the log reporters.

For example, if we want to set the log level to info we can do so by setting the log level before we start the application.

```ocaml
open Opium.Std

let () =
  Logs.set_level (Some Logs.Info) ;
  App.empty
  |> get "/" (fun _ -> `String "Hello World" |> respond')
  |> App.run_command
```

When using a custom log reporter where the reporter is returned via an Lwt promise, we don't want to run the lwt event loop right away.
Opium allows running cmdliner from the App module without running the Lwt event loop. Instead of `App.run_command` we'll need to use `App.run_command'`.

```ocaml
open Opium.Std
open Lwt.Infix

(* This is done to demonstrate a usecase where the log reporter is returned via
   a Lwt promise *)
let log_reporter () = Lwt.return (Logs_fmt.reporter ())

let say_hello =
  get "/hello/:name" (fun req ->
      `String ("Hello " ^ param req "name") |> respond')

let () =
  let app = App.empty |> say_hello |> App.run_command' in
  match app with
  | `Ok app ->
      let s =
        log_reporter ()
        >>= fun r ->
        Logs.set_reporter r ;
        Logs.set_level (Some Logs.Info) ;
        app
      in
      ignore (Lwt_main.run s)
  | `Error -> exit 1
  | `Not_running -> exit 0
```
