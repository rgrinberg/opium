open Opium.Std

let print_json req =
  req |> App.json_of_body_exn
  |> fun _json ->
  Lwt.return
    (Response.make ~body:(Opium_kernel.Body.of_string "Received response") ())

let _ = App.empty |> post "/" print_json |> App.run_command
