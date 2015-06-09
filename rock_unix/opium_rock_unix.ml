open Core_kernel.Std
open Opium_rock
open Opium_misc

module Server = Cohttp_lwt_unix.Server

let run app ~port =
  let middlewares = (App.middlewares app) |> List.map ~f:Middleware.filter in
  Server.create ~mode:(`TCP (`Port port)) (
    Server.make ~callback:(fun _ req body ->
      let req = Request.create ~body req in
      let handler = Filter.apply_all middlewares (App.handler app) in
      handler req >>= fun { Response.code; headers; body } ->
      Server.respond ~headers ~body ~status:code ()
    ) ()
  )

