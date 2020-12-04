(** Authentication functions to work with common HTTP authentication methods. *)

module Challenge : sig
  type t = Basic of string

  (** {3 [t_of_sexp]} *)

  (** [t_of_sexp sexp] parses the s-expression [sexp] into a challenge *)
  val t_of_sexp : Sexplib0.Sexp.t -> t

  (** {3 [sexp_of_t]} *)

  (** [sexp_of_t t] converts the challenge [t] to an s-expression *)
  val sexp_of_t : t -> Sexplib0.Sexp.t
end

module Credential : sig
  type t =
    | Basic of string * string (* username, password *)
    | Other of string

  (** {3 [t_of_sexp]} *)

  (** [t_of_sexp sexp] parses the s-expression [sexp] into credentials *)
  val t_of_sexp : Sexplib0.Sexp.t -> t

  (** {3 [sexp_of_t]} *)

  (** [sexp_of_t t] converts the credentials [t] to an s-expression *)
  val sexp_of_t : t -> Sexplib0.Sexp.t
end

(** {3 [string_of_credential]} *)

(** [string_of_credential cred] converts the credentials into a string usable in the
    [Authorization] header. *)
val string_of_credential : Credential.t -> string

(** {3 [credential_of_string]} *)

(** [credential_of_string s] parses a string from the [Authorization] header into
    credentials. *)
val credential_of_string : string -> Credential.t

(** {3 [string_of_challenge]} *)

(** [string_of_challenge challenge] converts the challenge into a string usable in the
    [WWW-Authenticate] response header. *)
val string_of_challenge : Challenge.t -> string
