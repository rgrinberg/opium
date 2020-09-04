open Opium.Std

let hello =
  get "/" (fun _ -> Lwt.return (Response.make ~body:(Body.of_string "Hello World") ()))
;;

let greet =
  get "/greet/:name" (fun req ->
      let name = Request.param "name" req |> Option.get in
      Lwt.return
        (Response.make ~body:(Body.of_string (Printf.sprintf "Hello, %s" name)) ()))
;;

let () = App.empty |> hello |> greet |> App.run_command |> ignore
