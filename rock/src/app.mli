type t = private
  { middlewares : Middleware.t list
  ; handler : Handler.t
  }

val append_middleware : t -> Middleware.t -> t
val create : ?middlewares:Middleware.t list -> handler:Handler.t -> unit -> t
