open Opium.Std

let error_403 = get "/403" (fun _req -> Lwt.return (Response.make ~status:`Forbidden ()))
let error_404 = get "/404" (fun _req -> Lwt.return (Response.make ~status:`Not_found ()))

let error_500 =
  get "/500" (fun _req -> Lwt.return (Response.make ~status:`Internal_server_error ()))
;;

let custom_handler = function
  | `Forbidden -> Some (Opium.Std.Response.of_string ~status:`Forbidden "Denied!")
  | _ -> None
;;

let _ =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Debug);
  App.empty
  |> middleware (Middleware.html_error_handler ~custom_handler ())
  |> error_403
  |> error_404
  |> error_500
  |> App.cmd_name "Error Handler"
  |> App.run_command
;;
