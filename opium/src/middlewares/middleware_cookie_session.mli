exception Session_not_found

val find : string -> Request.t -> string option
val set : string * string option -> Response.t -> Response.t
val m : ?cookie_key:string -> Cookie.Signer.t -> Rock.Middleware.t
