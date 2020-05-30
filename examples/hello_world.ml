open Opium.Std
open Lwt.Infix

let streaming =
  post "/hello/stream" (fun req ->
      let { Opium_kernel.Body.length; _ } = req.Request.body in
      let content = Opium_kernel.Body.to_stream req.Request.body in
      let body = Lwt_stream.map String.uppercase_ascii content in
      Response.make ~body:(Opium_kernel.Body.of_stream ?length body) () |> Lwt.return)
;;

let print_param =
  put "/hello/:name" (fun ({ Request.body; _ } as req) ->
      Opium_kernel.Body.to_string body
      >|= fun content ->
      Logs.info (fun m -> m "Request body: %s" content);
      let body = Opium_kernel.Body.of_string ("Hello " ^ param req "name") in
      Response.make ~body ())
;;

let _ =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Debug);
  App.empty |> streaming |> print_param |> App.run_command
;;
