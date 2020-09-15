val m
  :  ?time_f:((unit -> Response.t Lwt.t) -> Mtime.span * Response.t Lwt.t)
  -> unit
  -> Rock.Middleware.t

val request_to_string : Request.t -> string Lwt.t
