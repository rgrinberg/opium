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

let respond_with_file ?headers ~read =
  let open Lwt.Syntax in
  let* body = read () in
  match body with
  | Error status ->
    let headers = Option.value headers ~default:Httpaf.Headers.empty in
    let resp = Response.make ~headers ~status:(status :> Httpaf.Status.t) () in
    Lwt.return resp
  | Ok body ->
    let headers = Option.value headers ~default:Httpaf.Headers.empty in
    let resp = Response.make ~headers ~status:`OK ~body () in
    Lwt.return resp
;;

let serve ?mime_type ?etag ?(headers = Httpaf.Headers.empty) read req =
  let etag_quoted =
    match etag with
    | Some etag -> Some (Printf.sprintf "%S" etag)
    | None -> None
  in
  let headers =
    match etag_quoted with
    | Some etag_quoted -> Httpaf.Headers.add_unless_exists headers "ETag" etag_quoted
    | None -> headers
  in
  let headers =
    match mime_type with
    | Some mime_type -> Httpaf.Headers.add_unless_exists headers "Content-Type" mime_type
    | None -> headers
  in
  let request_if_none_match = Httpaf.Headers.get req.Request.headers "If-None-Match" in
  let request_matches_etag =
    match request_if_none_match, etag_quoted with
    | Some request_etags, Some etag_quoted ->
      request_etags
      |> Stringext.split ~on:','
      |> ListLabels.exists ~f:(fun request_etag -> String.trim request_etag = etag_quoted)
    | _ -> false
  in
  if request_matches_etag
  then Lwt.return @@ Response.make ~status:`Not_modified ~headers ()
  else respond_with_file ~read ~headers
;;

let m ~read ?(uri_prefix = "/") ?headers ?etag_of_fname () =
  let open Lwt.Syntax in
  let filter handler req =
    if req.Request.meth = `GET
    then (
      let local_path = req.target in
      if local_path |> is_prefix ~prefix:uri_prefix
      then (
        let legal_path = chop_prefix local_path ~prefix:uri_prefix in
        let read () = read legal_path in
        let mime_type = Magic_mime.lookup legal_path in
        let etag =
          match etag_of_fname with
          | Some f -> f legal_path
          | None -> None
        in
        let* res = serve read ~mime_type ?etag ?headers req in
        match res.status with
        | `Not_found -> handler req
        | _ -> Lwt.return res)
      else handler req)
    else handler req
  in
  Rock.Middleware.create ~name:"Static" ~filter
;;
