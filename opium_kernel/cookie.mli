(** Simple cookie module.  Cookie values are percent encoded. *)

(** Fetch all cookies from a rock request *)
val cookies : Rock.Request.t -> (string * string) list

(** Get the follow of a cookie with a certain key *)
val get : Rock.Request.t -> key:string -> string option

(** Set the value of a cookie with a certain key in a response *)
val set
  : ?expiration:Cohttp.Cookie.expiration
  -> ?path:string
  -> ?domain:string
  -> ?secure:bool
  -> ?http_only:bool
  -> Rock.Response.t
  -> key:string
  -> data:string
  -> Rock.Response.t

(** Like set but will do multiple cookies at once *)
val set_cookies
  : ?expiration:Cohttp.Cookie.expiration
  -> ?path:string
  -> ?domain:string
  -> ?secure:bool
  -> ?http_only:bool
  -> Rock.Response.t
  -> (string * string) list
  -> Rock.Response.t

(** Rock middleware to add the the functionality above *)
val m : Rock.Middleware.t
