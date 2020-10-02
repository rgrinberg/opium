(* A major part of this documentation is extracted from
   {{:https://github.com/inhabitedtype/httpaf/blob/master/lib/httpaf.mli}.

   Copyright (c) 2016, Inhabited Type LLC

   All rights reserved.*)

(** Protocol Version

    HTTP uses a "<major>.<minor>" numbering scheme to indicate versions of the protocol.
    The protocol version as a whole indicates the sender's conformance with the set of
    requirements laid out in that version's corresponding specification of HTTP.

    See {{:https://tools.ietf.org/html/rfc7230#section-2.6} RFC7230§2.6} for more
    details. *)

type t = Httpaf.Version.t =
  { major : int
  ; minor : int
  }

(** [compare] ??? *)
val compare : t -> t -> int

(** [to_string] ??? *)
val to_string : t -> string

(** [of_string] ??? *)
val of_string : string -> t

(** {2 Utilities} *)

(** [sexp_of_t t] converts the request [t] to an s-expression *)
val sexp_of_t : t -> Sexplib0.Sexp.t

(** [pp] formats the request [t] as an s-expression *)
val pp : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]

(** [pp_hum] formats the request [t] as a standard HTTP request *)
val pp_hum : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]
