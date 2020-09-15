type 'a t

val m : Rock.Handler.t t -> Rock.Middleware.t
val empty : 'action t
val add : 'a t -> route:Route.t -> meth:Method.t -> action:'a -> 'a t
val param : Request.t -> string -> string
val splat : Request.t -> string list
