open Core.Std

type 'a t with sexp

val create : unit -> _ t

val add : 'a t -> Cohttp.Code.meth -> 'a -> unit

module Route : sig
  type t
  val create : string -> t
  val match_url : t -> string -> (string * string) list option

  (** Exported for testing only *)
  val get_named_matches : ?rex:t -> ?pat:string
    -> string -> (string * string) list
end

type 'action endpoint with sexp

val endpoint : meth:Cohttp.Code.meth
  -> route:Route.t
  -> action:'action
  -> 'action endpoint

val param : Rock.Request.t -> string -> string

val m : (Rock.Handler.t endpoint) t -> Rock.Middleware.t
