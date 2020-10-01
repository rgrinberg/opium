(* The implementation of this middleware is based on Finagle's HeadFilter
   https://github.com/twitter/finagle/blob/develop/finagle-http/src/main/scala/com/twitter/finagle/http/filter/HeadFilter.scala

   It has to be before {!Middleware_content_length} *)

let m =
  let open Lwt.Syntax in
  let filter handler req =
    let req =
      match req.Request.meth with
      | `HEAD -> { req with meth = `GET }
      | _ -> req
    in
    let* response = handler req in
    let body_length = Body.length response.Response.body in
    let response =
      match body_length with
      | Some l ->
        { response with body = Body.empty }
        |> Response.add_header_or_replace ("Content-Length", Int64.to_string l)
        |> Response.remove_header "Content-Encoding"
      | None ->
        { response with body = Body.empty }
        |> Response.remove_header "Content-Length"
        |> Response.remove_header "Content-Encoding"
    in
    Lwt.return response
  in
  Rock.Middleware.create ~name:"Head" ~filter
;;
