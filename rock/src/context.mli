include Hmap.S with type 'a Key.info = string * ('a -> Sexplib0.Sexp.t)

val find_exn : 'a key -> t -> 'a

(** {2 Utilities} *)

(** [sexp_of_t t] converts the request [t] to an s-expression *)
val sexp_of_t : t -> Sexplib0.Sexp.t

(** [pp_hum] formats the request [t] as a standard HTTP request *)
val pp_hum : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]
