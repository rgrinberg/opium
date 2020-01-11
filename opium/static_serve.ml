open Opium_kernel__Misc
open Sexplib.Std
module Server = Httpaf_lwt_unix.Server
open Opium_kernel.Rock

type t = {prefix: string; local_path: string} [@@deriving fields, sexp]

let legal_path {prefix; local_path} requested =
  let p = String.chop_prefix requested ~prefix in
  let requested_path = Filename.concat local_path p in
  if String.is_prefix requested_path ~prefix:local_path then Some requested_path
  else None

exception Isnt_a_file

let add_opt_header_unless_exists headers k v =
  match headers with
  | Some h -> Httpaf.Headers.add_unless_exists h k v
  | None -> Httpaf.Headers.of_list [(k, v)]

let respond_with_file ?headers ~name () =
  Lwt.catch
    (fun () ->
      Lwt_unix.stat name
      >>= (fun s ->
            if Unix.(s.st_kind <> S_REG) then Lwt.fail Isnt_a_file
            else Lwt.return_unit)
      >>= fun () ->
      Lwt_io.with_file ~mode:Lwt_io.input name (fun ic ->
          Lwt_io.read ic
          >>= fun body ->
          let mime_type = Magic_mime.lookup name in
          let headers =
            add_opt_header_unless_exists headers "content-type" mime_type
          in
          let resp = Httpaf.Response.create ~headers `OK in
          return (resp, body)))
    (fun e ->
      match e with
      | Isnt_a_file ->
          let resp = Httpaf.Response.create `Not_found in
          return (resp, "")
      | exn -> Lwt.fail exn)

let public_serve t ~requested ~request_if_none_match ?etag_of_fname ?(headers = Httpaf.Headers.empty) ()
    =
  match legal_path t requested with
  | None -> return `Not_found
  | Some legal_path ->
      let etag_quoted =
        match etag_of_fname with
        | Some f -> Some (Printf.sprintf "%S" (f legal_path))
        | None -> None
      in
      let headers =
        match etag_quoted with
        | Some etag_quoted -> Httpaf.Headers.add_unless_exists headers "etag" etag_quoted
        | None -> headers
      in
      let request_matches_etag =
        match (request_if_none_match, etag_quoted) with
        | Some request_etags, Some etag_quoted ->
            request_etags |> Stringext.split ~on:','
            |> List.exists ~f:(fun request_etag ->
                   String.trim request_etag = etag_quoted)
        | _ -> false
      in
      if request_matches_etag then
        `Ok (Response.create ~code:`Not_modified ~headers ()) |> Lwt.return
      else
        respond_with_file ~headers ~name:legal_path ()
        >>| fun (resp, body) ->
        if resp.status = `Not_found then `Not_found
        else `Ok (Response.of_response_body (resp, `String body))

let m ~local_path ~uri_prefix ?headers ?etag_of_fname () =
  let filter handler req =
    if Request.meth req = `GET then
      let local_map = {prefix= uri_prefix; local_path} in
      let local_path = req |> Request.uri |> Uri.path in
      if local_path |> String.is_prefix ~prefix:uri_prefix then
        let request_if_none_match =
          Httpaf.Headers.get (Request.headers req) "If-None-Match"
        in
        public_serve local_map ~requested:local_path ~request_if_none_match
          ?etag_of_fname ?headers ()
        >>= function `Not_found -> handler req | `Ok x -> return x
      else handler req
    else handler req
  in
  Opium_kernel.Rock.Middleware.create ~name:"Static Pages" ~filter
