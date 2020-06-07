open Opium.Std
open Lwt.Syntax

let uppercase =
  let filter handler req =
    let* { Response.body; _ } = handler req in
    let+ content = Body.to_string body in
    let content = String.uppercase_ascii content in
    Response.make ~body:(Body.of_string content) ()
  in
  Rock.Middleware.create ~name:"uppercaser" ~filter
;;

let _ =
  App.empty
  |> middleware uppercase
  |> get "/hello" (fun _ ->
         Lwt.return (Response.make ~body:(Body.of_string "Hello World\n") ()))
  |> App.cmd_name "Uppercaser"
  |> App.run_command
;;
