open Core.Std
open Async.Std

module Co = Cohttp_async

open Rock

type t = {
  prefix: string;
  local_path: string;
} with fields, sexp

let error_body_default =
  "<html><body><h1>404 Not Found</h1></body></html>"

let pipe_of_file ?error_body filename =
  Monitor.try_with ~run:`Now
    (fun () ->
       Reader.open_file filename
       >>| fun rd ->
       `Ok (Reader.pipe rd))
  >>| function
  | Ok res -> res
  | Error exn ->
    let body = Option.value ~default:error_body_default error_body in
    `Not_found (Pipe.of_list [body])

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
    let body = Cohttp_async.Body.of_string error_body_default in
    return @@ Response.create ~body ~code:`Not_found ()
  | Some legal_path ->
    pipe_of_file legal_path
    >>| function
    | `Ok body -> Response.create ~body:(Cohttp_async.Body.of_pipe body) ()
    | `Not_found body -> Response.create ~body:(Cohttp_async.Body.of_pipe body)
                           ~code:`Not_found ()

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
  in { Rock.Middleware.name = Info.of_string "Static Pages"; filter }
