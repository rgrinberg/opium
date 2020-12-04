let m ?unauthorized_handler ~key ~realm ~auth_callback () =
  let unauthorized_handler =
    Option.value unauthorized_handler ~default:(fun _req ->
        Response.of_plain_text "Forbidden access" ~status:`Unauthorized
        |> Response.add_header ("WWW-Authenticate", Auth.string_of_challenge (Basic realm))
        |> Lwt.return)
  in
  let filter handler ({ Request.env; _ } as req) =
    let open Lwt.Syntax in
    let+ resp =
      match Request.authorization req with
      | None -> unauthorized_handler req
      | Some (Other _) -> unauthorized_handler req
      | Some (Basic (username, password)) ->
        let* user_opt = auth_callback ~username ~password in
        (match user_opt with
        | None -> unauthorized_handler req
        | Some user ->
          let env = Context.add key user env in
          let req = { req with Request.env } in
          handler req)
    in
    match resp.Response.status with
    | `Unauthorized ->
      Response.add_header
        ("WWW-Authenticate", Auth.string_of_challenge (Basic realm))
        resp
    | _ -> resp
  in
  Rock.Middleware.create ~name:"Basic authentication" ~filter
;;
