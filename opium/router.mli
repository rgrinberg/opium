open Core.Std

type 'action t with sexp

val create : unit -> _ t

module Route : sig
  type t with sexp
  val create : string -> t
  val match_url : t -> string -> (string * string) list option

  (** Exported for testing only *)
  val get_named_matches : ?rex:t -> ?pat:string
    -> string -> (string * string) list
end

val add : 'a t
  -> route:Route.t
  -> meth:Cohttp.Code.meth
  -> action:'a -> unit

val param : Rock.Request.t -> string -> string

val m : Rock.Handler.t t -> Rock.Middleware.t
