open Core.Std
open Async.Std
open Opium.Std
(* don't open cohttp and opium since they both define
   request/response modules*)
module Co = Cohttp

let is_substring ~substring s = Pcre.pmatch ~pat:(".*" ^ substring ^ ".*") s

let reject_ua ~f =
  let filter handler req =
    match Co.Header.get (Request.headers req) "user-agent" with
    | Some ua when f ua ->
      Log.Global.info "Rejecting %s" ua;
      `String ("Please upgrade your browser") |> respond'
    | _ -> handler req in
  Rock.Middleware.create ~filter ~name:(Info.of_string "reject_ua")

let app = App.app
          |> get "/.*" (fun req -> `String ("Hello World") |> respond')
          |> middleware @@ reject_ua ~f:(is_substring ~substring:"MSIE")

let _ =
  let app = App.create app in
  Command.run (App.command ~name:"Reject UA" app)
