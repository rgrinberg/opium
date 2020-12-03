module Challenge : sig
  type t = Basic of string

  val t_of_sexp : Sexplib0.Sexp.t -> t
  val sexp_of_t : t -> Sexplib0.Sexp.t
end

module Credential : sig
  type t =
    | Basic of string * string
    | Other of string

  val t_of_sexp : Sexplib0.Sexp.t -> t
  val sexp_of_t : t -> Sexplib0.Sexp.t
end

val string_of_credential : Credential.t -> string
val credential_of_string : string -> Credential.t
val string_of_challenge : Challenge.t -> string
