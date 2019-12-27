Examples
========

Assuming the necessary dependencies are installed, `$ dune build @examples` will
compile all the examples in this directory. The binaries will be located in
`_build/default/examples/`.

To build and run an example, execute

``` sh
dune exec examples/<example_name>.exe
```

This directory includes the following examples:

- [auth_middleware.ml](auth_middleware.ml): Example of adding middleware to
  implement a simple simple auth system.
- [exit_hook_example.ml](exit_hook_example.ml): Example showing how to clean up
  and cleanly exit on program termination.
- [hello_world_basic.ml](hello_world_basic.ml): An echo server that parses path
  params and emits JSON.
- [hello_world_html.ml](hello_world_html.ml): (TODO) Example of serving HTML.
- [hello_world_log.ml](hello_world_log.ml): Demonstrates configuration of a log
  reporter and middleware to log HTTP responses.
- [hello_world.ml](hello_world.ml): The most basic "Hello, World" echo server.
- [middleware_ua.ml](middleware_ua.ml): Middlware that checks the browser and
  rejects requests from Microsoft Internet Explorer.
- [read_json_body.ml](read_json_body.ml): Example of parsing the JSON body of a
  request.
- [sample.ml](sample.ml): A larger example including fetching and setting
  cookies, splatting routes, and serving static resources.
- [static_serve_override.ml](static_serve_override.ml): Example of serving a
  static directory, and the fact that routes do not currently override static
  resources.
- [uppercase_middleware.ml](uppercase_middleware.ml): A simple middleware that
  uppercases responses.

