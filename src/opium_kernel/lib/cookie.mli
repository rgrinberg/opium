(** Simple cookie module. Cookie values are percent encoded. *)

val cookies : Rock.Request.t -> (string * string) list
(** Fetch all cookies from a rock request *)

val get : Rock.Request.t -> key:string -> string option
(** Get the follow of a cookie with a certain key *)

val set :
     ?expiration:Cohttp.Cookie.expiration
  -> ?path:string
  -> ?domain:string
  -> ?secure:bool
  -> ?http_only:bool
  -> Rock.Response.t
  -> key:string
  -> data:string
  -> Rock.Response.t
(** Set the value of a cookie with a certain key in a response *)

val set_cookies :
     ?expiration:Cohttp.Cookie.expiration
  -> ?path:string
  -> ?domain:string
  -> ?secure:bool
  -> ?http_only:bool
  -> Rock.Response.t
  -> (string * string) list
  -> Rock.Response.t
(** Like set but will do multiple cookies at once *)

val m : Rock.Middleware.t
(** Rock middleware to add the the functionality above *)
