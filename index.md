---
layout: home
title: Home
nav_order: 1
permalink: /
---
Sinatra like web toolkit for OCaml based on cohttp & lwt.

## Design Goals

* Opium should be very small and easily learnable. A programmer should be instantly productive when starting out.

* Opium should be extensible using independently developed plugins. This is a Rack inspired mechanism borrowed from Ruby. The middleware mechanism in Opium is called Rock.

* It should maximize use of creature comforts people are used to in other languages. Such as sexplib, fieldslib, a decent standard library.

## Installation

### Stable

```bash
opam install opium
```

### Development version

```bash
opam pin add opium_kernel.dev git+https://github.com/rgrinberg/opium.git
opam pin add opium.dev git+https://github.com/rgrinberg/opium.git
```

## Hello World

Here's a simple hello world example to get your feet wet:

```ocaml
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
