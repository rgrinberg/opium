open Import

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

let h ?mime_type ?etag ?(headers = Httpaf.Headers.empty) read req =
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
      |> String.split_on_char ~sep:','
      |> List.exists ~f:(fun request_etag -> String.trim request_etag = etag_quoted)
    | _ -> false
  in
  if request_matches_etag
  then Lwt.return @@ Response.make ~status:`Not_modified ~headers ()
  else respond_with_file ~read ~headers
;;
