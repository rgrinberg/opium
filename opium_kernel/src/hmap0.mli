include Hmap.S with type 'a Key.info = string * ('a -> Sexplib0.Sexp.t)

val sexp_of_t : t -> Sexplib0.Sexp.t
val pp_hum : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]
val find_exn : 'a key -> t -> 'a
