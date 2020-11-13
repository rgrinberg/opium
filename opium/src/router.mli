open Import

module Route : sig
  type t

  val of_string_result : string -> (t, string) result
  val of_string : string -> t
  val sexp_of_t : t -> Sexp.t
  val to_string : t -> string
end

module Params : sig
  type t

  val named : t -> string -> string
  val unnamed : t -> string list
  val sexp_of_t : t -> Sexp.t
end

type 'a t

val empty : 'a t
val add : 'a t -> Route.t -> 'a -> 'a t
val update : 'a t -> Route.t -> f:('a option -> 'a) -> 'a t
val match_url : 'a t -> string -> ('a * Params.t) option
val sexp_of_t : ('a -> Sexp.t) -> 'a t -> Sexp.t
