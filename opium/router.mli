type 'action t with sexp

val create : unit -> _ t

module Route : sig
  type t with sexp
  val of_string : string -> t
  val to_string : t -> string
  val match_url : t -> string -> (string * string) list option
end

val add : 'a t
  -> route:Route.t
  -> meth:Cohttp.Code.meth
  -> action:'a -> unit

val routes : _ t -> Route.t list

val param : Rock.Request.t -> string -> string

val m : Rock.Handler.t t -> Rock.Middleware.t
