type error_handler =
  Headers.t -> Httpaf.Server_connection.error -> (Headers.t * Body.t) Lwt.t

val run
  :  (request_handler:Httpaf.Server_connection.request_handler
      -> error_handler:Httpaf.Server_connection.error_handler
      -> 'a Lwt.t)
  -> ?error_handler:error_handler
  -> ?middlewares:Middleware.t list
  -> Handler.t
  -> 'a Lwt.t

exception Halt of Response.t

val halt : Response.t -> Response.t Lwt.t
