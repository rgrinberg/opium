(** Collection of functions to run a server from a Rock app. *)

type error_handler =
  Unix.sockaddr
  -> Httpaf.Headers.t
  -> Httpaf.Server_connection.error
  -> (Httpaf.Headers.t * Body.t) Lwt.t

val default_error_handler : Unix.sockaddr -> Httpaf.Server_connection.error_handler

val create_error_handler
  :  error_handler
  -> Unix.sockaddr
  -> Httpaf.Server_connection.error_handler

val create_request_handler
  :  Unix.sockaddr
  -> Rock.App.t
  -> Httpaf.Server_connection.request_handler

(** The Halt exception can be raised to interrupt the normal processing flow of a request.

    The exception will be handled by the main run function (in {!Server_connection.run})
    and the response will be sent to the client directly.

    This is especially useful when you want to make sure that no other middleware will be
    able to modify the response. *)
exception Halt of Response.t

(** Raises a Halt exception to interrupt the processing of the connection and trigger an
    early response. *)
val halt : Response.t -> 'a
