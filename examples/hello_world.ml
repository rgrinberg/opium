open Opium.Std
open Lwt.Infix

type person = {name: string; age: int}

let print_param =
  put "/hello/:name" (fun ({Request.body; _} as req) ->
      Opium_kernel.Body.to_string body
      >|= fun content ->
      Logs.info (fun m -> m "Request body: %s" content) ;
      let body = Opium_kernel.Body.of_string ("Hello " ^ param req "name") in
      Response.make ~body ())

let _ =
  Logs.set_reporter (Logs_fmt.reporter ()) ;
  Logs.set_level (Some Logs.Debug) ;
  App.empty |> print_param |> App.run_command
