type content =
  [ `Empty
  | `String of string
  | `Bigstring of Bigstringaf.t
  | `Stream of string Lwt_stream.t
  ]

(** [t] represents an HTTP message body. *)
type t =
  { length : Int64.t option
  ; content : content
  }

(** {3 Constructor} *)

(** [of_string] creates a fixed length body from a string. *)
val of_string : string -> t

(** [of_bigstring] creates a fixed length body from a bigstring. *)
val of_bigstring : Bigstringaf.t -> t

(** [empty] represents a body of size 0L. *)
val empty : t

(** [of_stream] takes a [string Lwt_stream.t] and creates a HTTP body from it. *)
val of_stream : ?length:Int64.t -> string Lwt_stream.t -> t

(** [copy t] creates a new instance of the body [t]. If the body is a stream, it is be
    duplicated safely and the initial stream will remain untouched. *)
val copy : t -> t

(** {3 Utilities} *)

(** [to_string t] returns a promise that will eventually be filled with a string
    representation of the body. *)
val to_string : t -> string Lwt.t

(** [to_stream t] converts the body to a [string Lwt_stream.t]. *)
val to_stream : t -> string Lwt_stream.t

(** [drain t] will repeatedly read values from the body stream and discard them. *)
val drain : t -> unit Lwt.t

(** [sexp_of_t t] converts the body [t] to an s-expression *)
val sexp_of_t : t -> Sexplib0.Sexp.t

(** [pp_hum] formats the body [t] as an s-expression *)
val pp_hum : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]
