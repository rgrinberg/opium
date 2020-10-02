val m
  :  local_path:string
  -> ?uri_prefix:string
  -> ?headers:Headers.t
  -> ?etag_of_fname:(string -> string option)
  -> unit
  -> Rock.Middleware.t
