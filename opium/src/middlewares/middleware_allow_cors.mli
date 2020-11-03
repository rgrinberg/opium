val m
  :  ?origins:String.t list
  -> ?credentials:bool
  -> ?max_age:int
  -> ?headers:string list
  -> ?expose:string list
  -> ?methods:Method.t list
  -> ?send_preflight_response:bool
  -> unit
  -> Rock.Middleware.t
