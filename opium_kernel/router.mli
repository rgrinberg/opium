type 'action t

val create : unit -> _ t

val add : 'a t -> route:Route.t -> meth:Httpaf.Method.t -> action:'a -> unit

val param : Rock.Request.t -> string -> string

val splat : Rock.Request.t -> string list

val m : Rock.Handler.t t -> Rock.Middleware.t
