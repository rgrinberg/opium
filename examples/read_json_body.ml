open Core.Std
open Async.Std
open Cow
module Co = Cohttp
open Opium.Std

let print_json req =
  App.json_of_body_exn req >>| fun json ->
  Log.Global.info "Received: %s" (Json.to_string json);
  respond (`String "Received response")

let _ =
  App.app
  |> post "/" print_json
  |> App.create
  |> App.command ~summary:"Read json body"
  |> Command.run

