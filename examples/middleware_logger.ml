open Opium.Std
open Lwt.Infix

(* This is done to demonstrate a usecase where the log reporter is returned via a Lwt
   promise *)
let log_reporter () = Lwt.return (Logs_fmt.reporter ())

let say_hello =
  get "/hello/:name" (fun req ->
      Lwt.return
        (Response.make
           ~body:(Opium_kernel.Body.of_string ("Hello " ^ param req "name"))
           ()))
;;

let () =
  let app = App.empty |> say_hello |> middleware Middleware.logger |> App.run_command' in
  match app with
  | `Ok app ->
    let s =
      log_reporter ()
      >>= fun r ->
      Logs.set_reporter r;
      Logs.set_level (Some Logs.Debug);
      app
    in
    Lwt.async (fun () -> s >>= fun _ -> Lwt.return_unit);
    Lwt_main.run (fst (Lwt.wait ()))
  | `Error -> exit 1
  | `Not_running -> exit 0
;;
