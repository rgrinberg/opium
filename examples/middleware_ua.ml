open Opium.Std

(* don't open cohttp and opium since they both define
   request/response modules*)

let is_substring ~substring =
  let re = Re.compile (Re.str substring) in
  Re.execp re

let reject_ua ~f =
  let filter handler req =
    match Cohttp.Header.get (Request.headers req) "user-agent" with
    | Some ua when f ua ->
      `String ("Please upgrade your browser") |> respond'
    | _ -> handler req in
  Rock.Middleware.create ~filter ~name:"reject_ua"

let _ =
  App.empty
  |> get "/" (fun _ -> `String ("Hello World") |> respond')
  |> middleware (reject_ua ~f:(is_substring ~substring:"MSIE"))
  |> App.cmd_name "Reject UA"
  |> App.run_command
