open Core.Std
open Opium.Std

let print_json req =
  App.json_of_body_exn req >>| fun json ->
  respond (`String "Received response")

let _ =
  App.empty
  |> post "/" print_json
  |> App.command
  |> Command.run

