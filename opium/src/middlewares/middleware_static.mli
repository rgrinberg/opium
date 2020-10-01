val m
  :  read:
       (string
        -> ( Rock.Body.t
           , [ Rock.Status.client_error | Rock.Status.server_error ] )
           Lwt_result.t)
  -> ?uri_prefix:string
  -> ?headers:Rock.Headers.t
  -> ?etag_of_fname:(string -> string option)
  -> unit
  -> Rock.Middleware.t

val serve
  :  ?mime_type:string
  -> ?etag:string
  -> ?headers:Rock.Headers.t
  -> (unit
      -> ( Rock.Body.t
         , [ Rock.Status.client_error | Rock.Status.server_error ] )
         Lwt_result.t)
  -> Rock.Handler.t
