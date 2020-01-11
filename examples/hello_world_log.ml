open Opium.Std
open Lwt.Infix

(* This is done to demonstrate a usecase where the log reporter is returned via
   a Lwt promise *)
let log_reporter () = Lwt.return (Logs_fmt.reporter ())

let logger =
  let filter handler req =
    let uri = Request.uri req |> Uri.path_and_query in
    handler req
    >|= fun response ->
    let code = response |> Response.code |> Httpaf.Status.to_code in
    Logs.info (fun m -> m "Responded to '%s' with %d" uri code) ;
    response
  in
  Rock.Middleware.create ~name:"Logger" ~filter

let say_hello =
  get "/hello/:name" (fun req ->
      `String ("Hello " ^ param req "name") |> respond')

let () =
  let app = App.empty |> say_hello |> middleware logger |> App.run_command' in
  match app with
  | `Ok app ->
      let s =
        log_reporter ()
        >>= fun r ->
        Logs.set_reporter r ;
        Logs.set_level (Some Logs.Info) ;
        app
      in
      Lwt.async (fun () -> s >>= fun _ -> Lwt.return_unit) ;
      Lwt_main.run (fst (Lwt.wait ()))
  | `Error -> exit 1
  | `Not_running -> exit 0
