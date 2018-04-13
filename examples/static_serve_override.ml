(* example showcasing a bug (or conflict) caused by the router interacting
   with static middleware. Run this example and try:

   $ curl localhost:3000/examples/hello_world.ml

   The result will be the corresponding file in ./examples/ rather than the
   string "hello_world".
*)

open Opium.Std

let hello = get "/examples/hello_world.ml" (fun _ ->
  `String "Hello World" |> respond')

let () =
  let static =
    Middleware.static ~local_path:"./examples" ~uri_prefix:"/examples" () in
  App.empty
  |> hello
  |> middleware static
  |> App.run_command
  |> ignore
