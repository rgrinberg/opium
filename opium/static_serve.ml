open Opium_kernel__Misc
open Sexplib.Std

module Server = Cohttp_lwt_unix.Server
open Opium_kernel.Rock

type t = {
  prefix:     string;
  local_path: string;
} [@@deriving fields, sexp]

let legal_path {prefix;local_path} requested =
  let open Option in
  let p = String.chop_prefix requested ~prefix in
  let requested_path = Filename.concat local_path p in
  if String.is_prefix requested_path ~prefix:local_path
  then Some requested_path else None

let public_serve t ~requested =
  match legal_path t requested with
  | None -> return `Not_found
  | Some legal_path ->
    let mime_type = Magic_mime.lookup legal_path in
    let headers = Cohttp.Header.init_with "content-type" mime_type in
    Server.respond_file ~headers ~fname:legal_path () >>| fun resp ->
    if resp |> fst |> Cohttp.Response.status = `Not_found
    then `Not_found
    else `Ok (Response.of_response_body resp)

let m ~local_path ~uri_prefix =
  let filter handler req =
    if Request.meth req = `GET then
      let local_map = { prefix=uri_prefix; local_path } in
      let local_path = req |> Request.uri |> Uri.path in
      if local_path |> String.is_prefix ~prefix:uri_prefix then
        public_serve local_map ~requested:local_path >>= function
        | `Not_found -> handler req
        | `Ok x -> return x
      else
        handler req
    else
      handler req
  in Opium_kernel.Rock.Middleware.create ~name:"Static Pages" ~filter
