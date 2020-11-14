open Import

let allowed_methods = [ `GET; `HEAD; `POST ]

let m ?(allowed_methods = allowed_methods) () =
  let filter handler req =
    match List.mem req.Request.meth ~set:allowed_methods with
    | true -> handler req
    | false -> Lwt.return (Response.make ~status:`Method_not_allowed ())
  in
  Rock.Middleware.create ~name:"Method required" ~filter
;;
