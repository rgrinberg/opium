type content =
  [ `Empty
  | `String of string
  | `Bigstring of Bigstringaf.t
  | (* TODO: switch to a iovec based stream *)
    `Stream of string Lwt_stream.t
  ]

type t =
  { length : Int64.t option
  ; content : content
  }

val of_string : string -> t
val of_bigstring : Bigstringaf.t -> t
val of_stream : ?length:Int64.t -> string Lwt_stream.t -> t
val empty : t
val copy : t -> t
val to_string : t -> string Lwt.t
val to_stream : t -> string Lwt_stream.t
val length : t -> Int64.t option
val drain : t -> unit Lwt.t
val sexp_of_t : t -> Sexplib0.Sexp.t
val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]
val pp_hum : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]
