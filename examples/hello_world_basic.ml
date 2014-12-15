open Core.Std
open Opium.Std

let hello =
  get "/"
    (fun req -> `String "Hello World" |> respond')

let () =
  App.empty
  |> hello
  |> App.command
  |> Command.run
