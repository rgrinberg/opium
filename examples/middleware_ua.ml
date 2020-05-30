open Opium.Std

(* don't open cohttp and opium since they both define request/response modules*)

let is_substring ~substring =
  let re = Re.compile (Re.str substring) in
  Re.execp re

let reject_ua ~f =
  let filter handler req =
    match Httpaf.Headers.get req.Request.headers "user-agent" with
    | Some ua when f ua ->
        Response.make ~status:`Bad_request
          ~body:(Opium_kernel.Body.of_string "Please upgrade your browser\n")
          ()
        |> Lwt.return
    | _ -> handler req
  in
  Rock.Middleware.create ~filter ~name:"reject_ua"

let _ =
  App.empty
  |> get "/" (fun _ ->
         Response.make ~body:(Opium_kernel.Body.of_string "Hello World\n") ()
         |> Lwt.return)
  |> middleware (reject_ua ~f:(is_substring ~substring:"MSIE"))
  |> App.cmd_name "Reject UA" |> App.run_command
