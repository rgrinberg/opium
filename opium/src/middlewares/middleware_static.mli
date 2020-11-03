val m
  :  read:(string -> (Body.t, [ Status.client_error | Status.server_error ]) Lwt_result.t)
  -> ?uri_prefix:string
  -> ?headers:Headers.t
  -> ?etag_of_fname:(string -> string option)
  -> unit
  -> Rock.Middleware.t
