type 'action t with sexp

val create : unit -> _ t

module Route : sig
  type t with sexp
  val create : string -> t
  val match_url : t -> string -> (string * string) list option
end

val add : 'a t
  -> route:Route.t
  -> meth:Cohttp.Code.meth
  -> action:'a -> unit

val param : Rock.Request.t -> string -> string

val m : Rock.Handler.t t -> Rock.Middleware.t
