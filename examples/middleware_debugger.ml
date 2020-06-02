open Lwt.Infix
open Opium.Std

(* exceptions should be nicely formatted *)
let throws =
  get "/" (fun _ ->
      Logs.warn (fun f -> f "Crashing...");
      failwith "expected failure!")
;;

let app =
  App.empty |> throws |> middleware Middleware.logger |> middleware Middleware.debugger
;;

let () =
  let app = app |> App.run_command' in
  match app with
  | `Ok app ->
    let s =
      Logs.set_reporter (Logs_fmt.reporter ());
      Logs.set_level (Some Logs.Debug);
      app
    in
    Lwt.async (fun () -> s >>= fun _ -> Lwt.return_unit);
    Lwt_main.run (fst (Lwt.wait ()))
  | `Error -> exit 1
  | `Not_running -> exit 0
;;
