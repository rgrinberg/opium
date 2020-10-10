open Opium

let print_json req =
  req
  |> Request.to_json_exn
  |> fun _json -> Lwt.return (Response.make ~body:(Body.of_string "Received response") ())
;;

let _ = App.empty |> App.post "/" print_json |> App.run_command
