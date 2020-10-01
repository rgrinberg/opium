(** Module to create and work with HTTP responses.

    It offers convenience functions to create common responses and update them. *)

type t =
  { version : Version.t
  ; status : Status.t
  ; reason : string option
  ; headers : Headers.t
  ; body : Body.t
  ; env : Context.t
  }

(** {1 Constructors} *)

(** {3 [make]} *)

(** [make ?version ?status ?reason ?headers ?body ?env ()] creates a new response from the
    given values.

    By default, the HTTP version will be set to 1.1, the HTTP status to 200 and the
    response will not contain any header or body. *)
val make
  :  ?version:Version.t
  -> ?status:Status.t
  -> ?reason:string
  -> ?headers:Headers.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> unit
  -> t

(** {1 Utilities} *)

(** {3 [sexp_of_t]} *)

(** [sexp_of_t t] converts the response [t] to an s-expression *)
val sexp_of_t : t -> Sexplib0.Sexp.t

(** {3 [pp]} *)

(** [pp] formats the response [t] as an s-expression *)
val pp : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]

(** {3 [pp_hum]} *)

(** [pp_hum] formats the response [t] as a standard HTTP response *)
val pp_hum : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]
