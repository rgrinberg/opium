include Hmap.S with type 'a Key.info = string * ('a -> Sexplib.Sexp.t)

val sexp_of_t : t -> Sexplib.Sexp.t

val find_exn : 'a key -> t -> 'a
