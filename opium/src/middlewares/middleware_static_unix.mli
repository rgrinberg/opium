val m
  :  local_path:string
  -> ?uri_prefix:string
  -> ?headers:Headers.t
  -> ?etag_of_fname:(string -> string option Lwt.t)
  -> unit
  -> Rock.Middleware.t
