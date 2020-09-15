val m
  :  read:(string -> (Body.t, [ Status.client_error | Status.server_error ]) Lwt_result.t)
  -> ?uri_prefix:string
  -> ?headers:Headers.t
  -> ?etag_of_fname:(string -> string option)
  -> unit
  -> Rock.Middleware.t

val serve
  :  ?mime_type:string
  -> ?etag:string
  -> ?headers:Headers.t
  -> (unit -> (Body.t, [ Status.client_error | Status.server_error ]) Lwt_result.t)
  -> Rock.Handler.t
