(** Module to create HTTP requests. *)

type t =
  { version : Httpaf.Version.t
  ; target : string
  ; headers : Httpaf.Headers.t
  ; meth : Httpaf.Method.t
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
  :  ?version:Httpaf.Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Httpaf.Headers.t
  -> string
  -> Httpaf.Method.t
  -> t

(** {3 [get]} *)

(** [get ?version ?body ?env ?headers target] creates a new [GET] request from the given
    values.

    By default, the HTTP version will be set to 1.1 and the request will not contain any
    header or body. *)
val get
  :  ?version:Httpaf.Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Httpaf.Headers.t
  -> string
  -> t

(** {3 [post]} *)

(** [post ?version ?body ?env ?headers target] creates a new [POST] request from the given
    values.

    By default, the HTTP version will be set to 1.1 and the request will not contain any
    header or body. *)
val post
  :  ?version:Httpaf.Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Httpaf.Headers.t
  -> string
  -> t

(** {3 [put]} *)

(** [put ?version ?body ?env ?headers target] creates a new [PUT] request from the given
    values.

    By default, the HTTP version will be set to 1.1 and the request will not contain any
    header or body. *)
val put
  :  ?version:Httpaf.Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Httpaf.Headers.t
  -> string
  -> t

(** {3 [delete]} *)

(** [delete ?version ?body ?env ?headers target] creates a new [DELETE] request from the
    given values.

    By default, the HTTP version will be set to 1.1 and the request will not contain any
    header or body. *)
val delete
  :  ?version:Httpaf.Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Httpaf.Headers.t
  -> string
  -> t
