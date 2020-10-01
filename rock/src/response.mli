(** Module to create HTTP responses. *)

type t =
  { version : Httpaf.Version.t
  ; status : Httpaf.Status.t
  ; reason : string option
  ; headers : Httpaf.Headers.t
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
  :  ?version:Httpaf.Version.t
  -> ?status:Httpaf.Status.t
  -> ?reason:string
  -> ?headers:Httpaf.Headers.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> unit
  -> t
