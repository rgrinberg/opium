open Opium

let hello _req = Response.of_plain_text "Hello World" |> Lwt.return

let greet req =
  let name = Router.param req "name" in
  Printf.sprintf "Hello, %s" name |> Response.of_plain_text |> Lwt.return
;;

let () =
  let open App in
  App.empty
  |> App.get "/" hello
  |> App.get "/greet/:name" greet
  |> App.run_command
  |> ignore
;;
