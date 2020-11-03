let m =
  let open Lwt.Syntax in
  let filter handler req =
    let content_type = Request.content_type req in
    match req.Request.meth, content_type with
    | `POST, Some "application/x-www-form-urlencoded" ->
      let* method_result =
        Request.urlencoded "_method" req
        |> Lwt.map (fun el -> Option.map String.uppercase_ascii el)
      in
      let method_ =
        match method_result with
        | Some m ->
          (match Method.of_string m with
          | (`PUT | `DELETE | `Other "PATCH") as m -> m
          | _ -> req.meth)
        | None -> req.meth
      in
      handler { req with meth = method_ }
    | _ -> handler req
  in
  Rock.Middleware.create ~name:"Method override" ~filter
;;
