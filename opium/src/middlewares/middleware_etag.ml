open Import

(* TODO: The non-cached responses should include Cache-Control, Content-Location, Date,
   ETag, Expires, and Vary *)

let etag_of_body body =
  let encode s =
    s
    |> Cstruct.of_string
    |> Mirage_crypto.Hash.digest `MD5
    |> Cstruct.to_string
    |> Base64.encode_exn
  in
  match body.Body.content with
  | `String s -> Some (encode s)
  | `Bigstring b -> Some (b |> Bigstringaf.to_string |> encode)
  | `Empty -> Some (encode "")
  | `Stream _ -> None
;;

let m =
  let filter handler req =
    let open Lwt.Syntax in
    let* response = handler req in
    match response.Response.status with
    | `OK | `Created | `Accepted ->
      let etag_quoted =
        match etag_of_body response.Response.body with
        | Some etag -> Some (Printf.sprintf "%S" etag)
        | None -> None
      in
      let response =
        match etag_quoted with
        | Some etag_quoted ->
          Response.add_header_or_replace ("ETag", etag_quoted) response
        | None -> response
      in
      let request_if_none_match = Response.header "If-None-Match" response in
      let request_matches_etag =
        match request_if_none_match, etag_quoted with
        | Some request_etags, Some etag_quoted ->
          request_etags
          |> String.split_on_char ~sep:','
          |> List.exists ~f:(fun request_etag -> String.trim request_etag = etag_quoted)
        | _ -> false
      in
      if request_matches_etag
      then Lwt.return @@ Response.make ~status:`Not_modified ~headers:response.headers ()
      else Lwt.return response
    | _ -> Lwt.return response
  in
  Rock.Middleware.create ~name:"ETag" ~filter
;;
