(** Expression that represent a target or multiple *)

type t

type matches =
  { params : (string * string) list
  ; splat : string list
  }

(** [sexp_of_t matches] converts the matches [matches] to an s-expression *)
val sexp_of_matches : matches -> Sexplib0.Sexp.t

(** [of_string s] returns a route from its string representation [s]. *)
val of_string : string -> t

(** [to_string t] returns a string representation of the route [t]. *)
val to_string : t -> string

(** [match_url t url] return the matches of the url [url] for the route [t], or [None] if
    the url does not match. *)
val match_url : t -> string -> matches option
