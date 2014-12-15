open Core.Std
open Opium_misc

module Rock = Opium_rock
open Rock

type t = {
  prefix: string;
  local_path: string;
} with fields, sexp

let error_body_default =
  "<html><body><h1>404 Not Found</h1></body></html>"

let legal_path {prefix;local_path} requested = 
  let open Option in
  String.chop_prefix requested ~prefix >>= fun p ->
  let requested_path = Filename.concat local_path p
  in Option.some_if
       (String.is_prefix requested_path ~prefix:local_path)
       requested_path

let public_serve t ~requested =
  match legal_path t requested with
  | None ->
    let body = Body.of_string error_body_default in
    return @@ Response.create ~body ~code:`Not_found ()
  | Some legal_path ->
    Server.respond_file ~fname:legal_path () >>| Response.of_response_body

let m ~local_path ~uri_prefix =
  let filter handler req =
    if Request.meth req = `GET then
      let local_map = { prefix=uri_prefix; local_path } in
      let local_path = req  |> Request.uri |> Uri.path in
      if local_path |> String.is_prefix ~prefix:uri_prefix then
        public_serve local_map ~requested:local_path
      else
        handler req
    else
      handler req
  in Rock.Middleware.create ~name:(Info.of_string "Static Pages") ~filter
