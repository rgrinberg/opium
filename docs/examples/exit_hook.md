---
layout: default
title: Exit Hook
parent: Examples
nav_order: 2
permalink: /examples/exithook
---

# Exit hook

We can use Lwt's Exit_hooks to add a hook to run first at process exit. This can be used to perform any cleanup if needed before exiting an opium app.

```ocaml
open Opium.Std

let hello = get "/" (fun _ -> `String "Hello World" |> respond')

let () =
  let app = App.empty |> hello |> App.run_command' in
  match app with
  | `Ok app ->
      Lwt_main.at_exit (fun () -> Lwt.return (print_endline "Testing")) ;
      let s =
        Lwt.join [app; Lwt_unix.sleep 2.0 |> Lwt.map (fun _ -> Lwt.cancel app)]
      in
      ignore (Lwt_main.run s)
  | `Error -> exit 1
  | `Not_running -> exit 0
```
