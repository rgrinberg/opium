type t with sexp

type matches = {
  params: (string * string) list;
  splat: string list;
} with fields, sexp

val of_string : string -> t
val to_string : t -> string

val match_url : t -> string -> matches option
