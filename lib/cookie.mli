
val cookies : Rock.Request.t -> Cohttp.Cookie.cookie list
val get : Rock.Request.t -> key:string -> string option
val set : Rock.Request.t -> key:string -> data:string -> unit
val set_cookies : Rock.Request.t -> (string * string) list -> unit
val m : Rock.Middleware.t
