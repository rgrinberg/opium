open Core_kernel.Std
open Opium_misc

module Rock = Opium_rock
open Rock

type t = {
  prefix:     string;
  local_path: string;
} with fields, sexp

let legal_path {prefix;local_path} requested = 
  let open Option in
  String.chop_prefix requested ~prefix >>= fun p ->
  let requested_path = Filename.concat local_path p
  in Option.some_if
       (String.is_prefix requested_path ~prefix:local_path)
       requested_path

let public_serve t ~requested =
  match legal_path t requested with
  | None -> return `Not_found
  | Some legal_path ->
    let mime_type = Magic_mime.lookup legal_path in
    let headers = Cohttp.Header.init_with "content-type" mime_type in
    Cohttp_lwt_unix.Server.respond_file ~headers ~fname:legal_path () >>| fun resp ->
    if resp |> fst |> Cohttp.Response.status = `Not_found
    then `Not_found
    else `Ok (Response.of_response_body resp)

let m ~local_path ~uri_prefix =
  let filter handler req =
    if Request.meth req = `GET then
      let local_map = { prefix=uri_prefix; local_path } in
      let local_path = req  |> Request.uri |> Uri.path in
      if local_path |> String.is_prefix ~prefix:uri_prefix then
        public_serve local_map ~requested:local_path >>= function
        | `Not_found -> handler req
        | `Ok x -> return x
      else
        handler req
    else
      handler req
  in Rock.Middleware.create ~name:(Info.of_string "Static Pages") ~filter
