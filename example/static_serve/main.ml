(* example showcasing a bug (or conflict) caused by the router interacting with static
   middleware. Run this example and try:

   $ curl localhost:3000/examples/hello_world.ml

   The result will be the corresponding file in ./examples/ rather than the string
   "hello_world". *)

open Opium

let () =
  let static =
    Middleware.static_unix ~local_path:"./example/static_serve/asset/" ~uri_prefix:"/" ()
  in
  App.empty |> App.middleware static |> App.run_command
;;
