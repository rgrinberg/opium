(* Simple cookie module.  Cookies are base64'd and percent encoded
*)
val cookies : Rock.Request.t -> Cohttp.Cookie.cookie list
val get : Rock.Request.t -> key:string -> string option
val set : Rock.Response.t -> key:string -> data:string -> Rock.Response.t
val set_cookies : Rock.Response.t -> (string * string) list -> Rock.Response.t
val m : Rock.Middleware.t
