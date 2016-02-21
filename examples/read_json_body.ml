open Opium.Std

let print_json req =
  req |> App.json_of_body_exn |> Lwt.map (fun _json ->
    respond (`String "Received response"))

let _ =
  App.empty
  |> post "/" print_json
  |> App.run_command

