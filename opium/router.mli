type 'action t with sexp

val create : unit -> _ t

module Route : sig
  type t with sexp
  type matches = {
    params: (string * string) list;
    splat: string list;
  } with fields, sexp

  val of_string : string -> t
  val to_string : t -> string
  val match_url : t -> string -> matches option
end

val add : 'a t
  -> route:Route.t
  -> meth:Cohttp.Code.meth
  -> action:'a -> unit

val param : Rock.Request.t -> string -> string

val splat : Rock.Request.t -> string list

val m : Rock.Handler.t t -> Rock.Middleware.t
