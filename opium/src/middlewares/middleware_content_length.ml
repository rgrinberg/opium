let m =
  let open Lwt.Syntax in
  let filter handler req =
    let+ res = handler req in
    let length = Body.length res.Response.body in
    match length with
    | None ->
      res
      |> Response.remove_header "Content-Length"
      |> Response.add_header_unless_exists ("Transfer-Encoding", "chunked")
    | Some l -> Response.add_header_or_replace ("Content-Length", Int64.to_string l) res
  in
  Rock.Middleware.create ~name:"Content length" ~filter
;;
