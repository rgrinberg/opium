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

## Usage

1. Add opium as a dependency in your project.

    If using opam, depend on opium in your opam file:

    ```
    depends: [
      "opium"
    ]
    ```

    If using esy, add opium in the "dependencies" attribute of the package.json or esy.json file :

    ```javascript
    {
      "dependencies" {
        "@opam/opium": "0.17.1"
      }
    }
    ```

2. Add opium as a dependency into your dune file

    ```scheme
    (executable
      (name my_project)
      (libraries opium))
    ```

## Hello World

```ocaml
open Opium.Std

let () =
  App.empty
  |> get "/" (fun _ -> `String "Hello World" |> respond')
  |> App.run_command
```
Save this in a file `my_app.ml` and then compile with: `ocamlbuild -pkg opium my_app.native`
Run it by executing `./my_app.native`
You can access it at [http://localhost:3000](http://localhost:3000). This is a very simple example of how to start using Opium. For anything beyond this, we recommend using [dune](https://dune.build/) to build your project.
