(** [Static] is used to serve static content.

    It is Unix-independent, you can provide your own read function that could
    read from in-memory content, or read a Unix filesystem, or even connect to a
    third party service such as S3.

    The responses will contain a [Content-type] header that is auto-detected
    based on the file extension using the {!Magic_mime.lookup} function.
    Additional headers can be provided through [headers].

    It supports the HTTP entity tag (ETag) protocol to provide web cache
    validation. If [etag_of_fname] is provided, the response will contain an
    [ETag] header. If the request contains an [If-None-Match] header with an
    [ETag] equal to that generated by [etag_of_fname], this middleware will
    respond with [304 Not Modified]. *)

open Lwt.Syntax

let log_src =
  Logs.Src.create ~doc:"Opium middleware to server static files" "opium.static_server"
;;

module Log = (val Logs.src_log log_src : Logs.LOG)

let is_prefix ~prefix s =
  String.length prefix <= String.length s
  &&
  let i = ref 0 in
  while !i < String.length prefix && s.[!i] = prefix.[!i] do
    incr i
  done;
  !i = String.length prefix
;;

let chop_prefix ~prefix s =
  assert (is_prefix ~prefix s);
  String.sub s (String.length prefix) String.(length s - length prefix)
;;

let add_opt_header_unless_exists headers k v =
  match headers with
  | Some h -> Httpaf.Headers.add_unless_exists h k v
  | None -> Httpaf.Headers.of_list [ k, v ]
;;

let respond_with_file ?mime_type ?headers ~read name =
  let* body = read () in
  match body with
  | Error status ->
    let headers = Option.value headers ~default:Httpaf.Headers.empty in
    let resp = Rock.Response.make ~headers ~status:(status :> Httpaf.Status.t) () in
    Lwt.return resp
  | Ok body ->
    let mime_type = mime_type |> Option.value ~default:(Magic_mime.lookup name) in
    let headers = add_opt_header_unless_exists headers "Content-Type" mime_type in
    let resp = Rock.Response.make ~headers ~status:`OK ~body () in
    Lwt.return resp
;;

let serve ~read ?mime_type ?etag_of_fname ?(headers = Httpaf.Headers.empty) fname req =
  let etag_quoted =
    match etag_of_fname with
    | Some f ->
      (match f fname with
      | Some etag -> Some (Printf.sprintf "%S" etag)
      | None -> None)
    | None -> None
  in
  let headers =
    match etag_quoted with
    | Some etag_quoted -> Httpaf.Headers.add_unless_exists headers "ETag" etag_quoted
    | None -> headers
  in
  let request_if_none_match =
    Httpaf.Headers.get req.Rock.Request.headers "If-None-Match"
  in
  let request_matches_etag =
    match request_if_none_match, etag_quoted with
    | Some request_etags, Some etag_quoted ->
      request_etags
      |> Stringext.split ~on:','
      |> ListLabels.exists ~f:(fun request_etag -> String.trim request_etag = etag_quoted)
    | _ -> false
  in
  if request_matches_etag
  then Lwt.return @@ Rock.Response.make ~status:`Not_modified ~headers ()
  else respond_with_file ~read ?mime_type ~headers fname
;;

let m ~read ?(uri_prefix = "/") ?headers ?etag_of_fname () =
  let filter handler req =
    if req.Rock.Request.meth = `GET
    then (
      let local_path = req.target in
      if local_path |> is_prefix ~prefix:uri_prefix
      then (
        let legal_path = chop_prefix local_path ~prefix:uri_prefix in
        let read () = read legal_path in
        let* res = serve ~read ?etag_of_fname ?headers legal_path req in
        match res.status with
        | `Not_found -> handler req
        | _ -> Lwt.return res)
      else handler req)
    else handler req
  in
  Rock.Middleware.create ~name:"Static" ~filter
;;