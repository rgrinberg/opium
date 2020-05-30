open Opium.Std
open Lwt.Infix

let uppercase =
  let filter handler req =
    handler req
    >>= fun {Response.body; _} ->
    Opium_kernel.Body.to_string body
    >|= fun content ->
    let content = String.uppercase_ascii content in
    Response.make ~body:(Opium_kernel.Body.of_string content) ()
  in
  Rock.Middleware.create ~name:"uppercaser" ~filter

let _ =
  App.empty |> middleware uppercase
  |> get "/hello" (fun _ ->
         Lwt.return
           (Response.make
              ~body:(Opium_kernel.Body.of_string "Hello World\n")
              ()))
  |> App.cmd_name "Uppercaser" |> App.run_command
