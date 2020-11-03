val h
  :  ?mime_type:string
  -> ?etag:string
  -> ?headers:Headers.t
  -> (unit -> (Body.t, [ Status.client_error | Status.server_error ]) Lwt_result.t)
  -> Rock.Handler.t
