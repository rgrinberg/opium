(* A major part of this documentation is extracted from
   {{:https://github.com/inhabitedtype/httpaf/blob/master/lib/httpaf.mli}.

   Copyright (c) 2016, Inhabited Type LLC

   All rights reserved.*)

(** Request Method

    The request method token is the primary source of request semantics; it indicates the
    purpose for which the client has made this request and what is expected by the client
    as a successful result.

    See {{:https://tools.ietf.org/html/rfc7231#section-4} RFC7231§4} for more details. *)

type standard =
  [ `GET
    (** {{:https://tools.ietf.org/html/rfc7231#section-4.3.1} RFC7231§4.3.1}. Safe,
        Cacheable. *)
  | `HEAD
    (** {{:https://tools.ietf.org/html/rfc7231#section-4.3.2} RFC7231§4.3.2}. Safe,
        Cacheable. *)
  | `POST
    (** {{:https://tools.ietf.org/html/rfc7231#section-4.3.3} RFC7231§4.3.3}. Cacheable. *)
  | `PUT
    (** {{:https://tools.ietf.org/html/rfc7231#section-4.3.4} RFC7231§4.3.4}. Idempotent. *)
  | `DELETE
    (** {{:https://tools.ietf.org/html/rfc7231#section-4.3.5} RFC7231§4.3.5}. Idempotent. *)
  | `CONNECT (** {{:https://tools.ietf.org/html/rfc7231#section-4.3.6} RFC7231§4.3.6}. *)
  | `OPTIONS
    (** {{:https://tools.ietf.org/html/rfc7231#section-4.3.7} RFC7231§4.3.7}. Safe.*)
  | `TRACE
    (** {{:https://tools.ietf.org/html/rfc7231#section-4.3.8} RFC7231§4.3.8}. Safe.*)
  ]

type t =
  [ standard
  | `Other of string (** Methods defined outside of RFC7231, or custom methods. *)
  ]

(** Request methods are considered "safe" if their defined semantics are essentially
    read-only; i.e., the client does not request, and does not expect, any state change on
    the origin server as a result of applying a safe method to a target resource.
    Likewise, reasonable use of a safe method is not expected to cause any harm, loss of
    property, or unusual burden on the origin server.

    See {{:https://tools.ietf.org/html/rfc7231#section-4.2.1} RFC7231§4.2.1} for more
    details. *)
val is_safe : standard -> bool

(** Request methods can be defined as "cacheable" to indicate that responses to them are
    allowed to be stored for future reuse.

    See {{:https://tools.ietf.org/html/rfc7234} RFC7234} for more details. *)
val is_cacheable : standard -> bool

(** A request method is considered "idempotent" if the intended effect on the server of
    multiple identical requests with that method is the same as the effect for a single
    such request. Of the request methods defined by this specification, PUT, DELETE, and
    safe request methods are idempotent.

    See {{:https://tools.ietf.org/html/rfc7231#section-4.2.2} RFC7231§4.2.2} for more
    details. *)
val is_idempotent : standard -> bool

(** {2 Utilities} *)

(** [to_string t] returns a string representation of the method [t]. *)
val to_string : t -> string

(** [of_string s] returns a method from its string representation [s]. *)
val of_string : string -> t

(** [sexp_of_t t] converts the request [t] to an s-expression *)
val sexp_of_t : t -> Sexplib0.Sexp.t

(** [pp] formats the request [t] as an s-expression *)
val pp : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]
