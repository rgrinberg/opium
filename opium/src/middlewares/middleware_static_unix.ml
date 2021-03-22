open Lwt.Syntax

let default_etag ~local_path fname =
  let fpath = Filename.concat local_path fname in
  let* exists = Lwt_unix.file_exists fpath in
  if exists then
    let* stat = Lwt_unix.stat fpath in
    let hash =
      Marshal.to_string stat.st_mtime []
      |> Cstruct.of_string
      |> Mirage_crypto.Hash.digest `MD5
      |> Cstruct.to_string
      |> Base64.encode_exn
    in
    Lwt.return_some hash
  else
    Lwt.return_none
;;

let m ~local_path ?uri_prefix ?headers ?(etag_of_fname=default_etag ~local_path) () =
  let read fname =
    let* body = Body.of_file (Filename.concat local_path fname) in
    match body with
    | None -> Lwt.return (Error `Not_found)
    | Some body -> Lwt.return (Ok body)
  in
  Middleware_static.m ~read ?uri_prefix ?headers ~etag_of_fname ()
;;
