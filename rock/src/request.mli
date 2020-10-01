(** Module to create and work with HTTP requests.

    It offers convenience functions to read headers, decode a request body or URI.

    The requests are most likely provided to you by Opium when you are writing your
    application, but this module contains all the constructors and setters that you need
    to initialize new requests.

    {3 Working with stream bodies}

    All the functions in this module will clone the stream before reading from it, so you
    can process the body multiple times if needed. Just make sure that you didn't drain
    the body before calling a function that reads from it.

    Functions from other modules may drain the body stream. You can use {!Body.copy} to
    copy the body yourself. *)

type t =
  { version : Version.t
  ; target : string
  ; headers : Headers.t
  ; meth : Method.t
  ; body : Body.t
  ; env : Context.t
  }

(** {1 Constructors} *)

(** {3 [make]} *)

(** [make ?version ?body ?env ?headers target method] creates a new request from the given
    values.

    By default, the HTTP version will be set to 1.1 and the request will not contain any
    header or body. *)
val make
  :  ?version:Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Headers.t
  -> string
  -> Method.t
  -> t

(** {3 [get]} *)

(** [get ?version ?body ?env ?headers target] creates a new [GET] request from the given
    values.

    By default, the HTTP version will be set to 1.1 and the request will not contain any
    header or body. *)
val get
  :  ?version:Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Headers.t
  -> string
  -> t

(** {3 [post]} *)

(** [post ?version ?body ?env ?headers target] creates a new [POST] request from the given
    values.

    By default, the HTTP version will be set to 1.1 and the request will not contain any
    header or body. *)
val post
  :  ?version:Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Headers.t
  -> string
  -> t

(** {3 [put]} *)

(** [put ?version ?body ?env ?headers target] creates a new [PUT] request from the given
    values.

    By default, the HTTP version will be set to 1.1 and the request will not contain any
    header or body. *)
val put
  :  ?version:Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Headers.t
  -> string
  -> t

(** {3 [delete]} *)

(** [delete ?version ?body ?env ?headers target] creates a new [DELETE] request from the
    given values.

    By default, the HTTP version will be set to 1.1 and the request will not contain any
    header or body. *)
val delete
  :  ?version:Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Headers.t
  -> string
  -> t

(** {1 Utilities} *)

(** {3 [sexp_of_t]} *)

(** [sexp_of_t t] converts the request [t] to an s-expression *)
val sexp_of_t : t -> Sexplib0.Sexp.t

(** {3 [pp]} *)

(** [pp] formats the request [t] as an s-expression *)
val pp : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]

(** {3 [pp_hum]} *)

(** [pp_hum] formats the request [t] as a standard HTTP request *)
val pp_hum : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]
