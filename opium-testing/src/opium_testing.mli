(** This module provides helpers to easily test Opium applications with Alcotest. *)

(** {3 [Testable]} *)

(** Collection of [Alcotest] testables for [Opium] types. *)
module Testable : sig
  (** An {!Alcotest.testable} for {!Opium.Status.t} instances. *)
  val status : Opium.Status.t Alcotest.testable

  (** An {!Alcotest.testable} for {!Opium.Method.t} instances. *)
  val meth : Opium.Method.t Alcotest.testable

  (** An {!Alcotest.testable} for {!Opium.Version.t} instances. *)
  val version : Opium.Version.t Alcotest.testable

  (** An {!Alcotest.testable} for {!Opium.Body.t} instances. *)
  val body : Opium.Body.t Alcotest.testable

  (** An {!Alcotest.testable} for {!Opium.Request.t} instances. *)
  val request : Opium.Request.t Alcotest.testable

  (** An {!Alcotest.testable} for {!Opium.Response.t} instances. *)
  val response : Opium.Response.t Alcotest.testable

  (** An {!Alcotest.testable} for {!Opium.Cookie.t} instances. *)
  val cookie : Opium.Cookie.t Alcotest.testable
end

(** {3 [handle_request]} *)

(** [handle_request app request response] processes a request [request] with the given
    Opium application [app].

    It processes the request the same [Opium.Server_connection.run] would and returns the
    generated response. *)
val handle_request : Opium.App.t -> Opium.Request.t -> Opium.Response.t Lwt.t

(** {3 [check_status]} *)

(** [check_status ?msg t1 t2] checks that the status [t1] and [t2] are equal. *)
val check_status : ?msg:string -> Opium.Status.t -> Opium.Status.t -> unit

(** {3 [check_status']} *)

(** [check_status' ?msg t1 t2] checks that the status [t1] and [t2] are equal.

    This is a labeled variant of {!check_status} *)
val check_status'
  :  ?msg:string
  -> expected:Opium.Status.t
  -> actual:Opium.Status.t
  -> unit

(** {3 [check_meth]} *)

(** [check_meth ?msg t1 t2] checks that the method [t1] and [t2] are equal. *)
val check_meth : ?msg:string -> Opium.Method.t -> Opium.Method.t -> unit

(** {3 [check_meth']} *)

(** [check_meth' ?msg t1 t2] checks that the method [t1] and [t2] are equal.

    This is a labeled variant of {!check_meth} *)
val check_meth' : ?msg:string -> expected:Opium.Method.t -> actual:Opium.Method.t -> unit

(** {3 [check_version]} *)

(** [check_version ?msg t1 t2] checks that the version [t1] and [t2] are equal. *)
val check_version : ?msg:string -> Opium.Version.t -> Opium.Version.t -> unit

(** {3 [check_version']} *)

(** [check_version' ?msg t1 t2] checks that the version [t1] and [t2] are equal.

    This is a labeled variant of {!check_version} *)
val check_version'
  :  ?msg:string
  -> expected:Opium.Version.t
  -> actual:Opium.Version.t
  -> unit

(** {3 [check_body]} *)

(** [check_body ?msg t1 t2] checks that the body [t1] and [t2] are equal. *)
val check_body : ?msg:string -> Opium.Body.t -> Opium.Body.t -> unit

(** {3 [check_body']} *)

(** [check_body' ?msg t1 t2] checks that the body [t1] and [t2] are equal.

    This is a labeled variant of {!check_body} *)
val check_body' : ?msg:string -> expected:Opium.Body.t -> actual:Opium.Body.t -> unit

(** {3 [check_request]} *)

(** [check_request ?msg t1 t2] checks that the request [t1] and [t2] are equal. *)
val check_request : ?msg:string -> Opium.Request.t -> Opium.Request.t -> unit

(** {3 [check_request']} *)

(** [check_request' ?msg t1 t2] checks that the request [t1] and [t2] are equal.

    This is a labeled variant of {!check_request} *)
val check_request'
  :  ?msg:string
  -> expected:Opium.Request.t
  -> actual:Opium.Request.t
  -> unit

(** {3 [check_response]} *)

(** [check_response ?msg t1 t2] checks that the response [t1] and [t2] are equal. *)
val check_response : ?msg:string -> Opium.Response.t -> Opium.Response.t -> unit

(** {3 [check_response']} *)

(** [check_response' ?msg t1 t2] checks that the response [t1] and [t2] are equal.

    This is a labeled variant of {!check_response} *)
val check_response'
  :  ?msg:string
  -> expected:Opium.Response.t
  -> actual:Opium.Response.t
  -> unit

(** {3 [check_cookie]} *)

(** [check_cookie ?msg t1 t2] checks that the cookie [t1] and [t2] are equal. *)
val check_cookie : ?msg:string -> Opium.Cookie.t -> Opium.Cookie.t -> unit

(** {3 [check_cookie']} *)

(** [check_cookie' ?msg t1 t2] checks that the cookie [t1] and [t2] are equal.

    This is a labeled variant of {!check_cookie} *)
val check_cookie'
  :  ?msg:string
  -> expected:Opium.Cookie.t
  -> actual:Opium.Cookie.t
  -> unit

(** {3 [check_body_contains]} *)

(** [check_body_contains ?msg s t] checks that the body [t] contains the string [s]. *)
val check_body_contains : ?msg:string -> string -> Opium.Body.t -> unit Lwt.t
