type t

type matches =
  { params : (string * string) list
  ; splat : string list
  }

val sexp_of_matches : matches -> Sexplib0.Sexp.t
val of_string : string -> t
val to_string : t -> string
val match_url : t -> string -> matches option
