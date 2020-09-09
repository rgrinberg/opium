open Opium.Std
open Lwt.Syntax

(* This is done to demonstrate a usecase where the log reporter is returned via a Lwt
   promise *)
let log_reporter () = Lwt.return (Logs_fmt.reporter ())

let say_hello =
  get "/hello/:name" (fun req ->
      Lwt.return (Response.make ~body:(Body.of_string ("Hello " ^ Router.param req "name")) ()))
;;

let () =
  let app = App.empty |> say_hello |> middleware Middleware.logger |> App.run_command' in
  match app with
  | `Ok app ->
    let s =
      let* r = log_reporter () in
      Logs.set_reporter r;
      Logs.set_level (Some Logs.Debug);
      app
    in
    Lwt.async (fun () ->
        let* _ = s in
        Lwt.return_unit);
    Lwt_main.run (fst (Lwt.wait ()))
  | `Error -> exit 1
  | `Not_running -> exit 0
;;
