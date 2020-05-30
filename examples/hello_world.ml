open Opium.Std

let streaming =
  post "/hello/stream" (fun req ->
      let { Opium_kernel.Body.length; _ } = req.Request.body in
      let content = Opium_kernel.Body.to_stream req.Request.body in
      let body = Lwt_stream.map String.uppercase_ascii content in
      Response.make ~body:(Opium_kernel.Body.of_stream ?length body) () |> Lwt.return)
;;

let print_param =
  get "/hello/:name" (fun req ->
      let body =
        Printf.sprintf "Hello, %s\n" (param req "name") |> Opium_kernel.Body.of_string
      in
      Response.make ~body () |> Lwt.return)
;;

let _ =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Debug);
  App.empty |> streaming |> print_param |> App.run_command
;;
