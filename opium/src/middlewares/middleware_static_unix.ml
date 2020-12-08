let m ~local_path ?uri_prefix ?headers ?etag_of_fname () =
  let open Lwt.Syntax in
  let read fname =
    let* body = Body.of_file (Filename.concat local_path fname) in
    match body with
    | None -> Lwt.return (Error `Not_found)
    | Some body -> Lwt.return (Ok body)
  in
  Middleware_static.m ~read ?uri_prefix ?headers ?etag_of_fname ()
;;
