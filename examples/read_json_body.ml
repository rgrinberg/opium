open Core.Std
open Async.Std
open Cow
module Co = Cohttp
open Opium.Std

let print_json req =
  App.json_of_body_exn req >>| fun json ->
    let response_body =
      sprintf "Your json right back at you:\n%s\n" (Json.to_string json)
    in
    respond (`String response_body)

let _ =
  App.app
  |> put "/" print_json
  |> post "/" print_json
  |> App.port 3000
  |> App.start

