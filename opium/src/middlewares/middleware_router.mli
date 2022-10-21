type t

val m : t -> Rock.Middleware.t
val empty : t
val add : t -> route:Router.Route.t -> meth:Method.t -> action:Rock.Handler.t -> t
val param : Request.t -> string -> string
val splat : Request.t -> string list
