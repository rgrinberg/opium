type 'action t [@@deriving sexp]

val create : unit -> _ t

val add : 'a t
  -> route:Opium_route.t
  -> meth:Cohttp.Code.meth
  -> action:'a -> unit

val param : Opium_rock.Request.t -> string -> string

val splat : Opium_rock.Request.t -> string list

val m : Opium_rock.Handler.t t -> Opium_rock.Middleware.t
