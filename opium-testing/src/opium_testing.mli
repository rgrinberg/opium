(** This module provides helpers to easily test Opium applications with Alcotest. *)

(** {3 [Testable]} *)

(** Collection of [Alcotest] testables for [Opium_kernel] types. *)
module Testable : sig
  (** An {!Alcotest.testable} for {!Opium_kernel.Status.t} instances. *)
  val status : Opium_kernel.Status.t Alcotest.testable

  (** An {!Alcotest.testable} for {!Opium_kernel.Method.t} instances. *)
  val meth : Opium_kernel.Method.t Alcotest.testable

  (** An {!Alcotest.testable} for {!Opium_kernel.Version.t} instances. *)
  val version : Opium_kernel.Version.t Alcotest.testable

  (** An {!Alcotest.testable} for {!Opium_kernel.Body.t} instances. *)
  val body : Opium_kernel.Body.t Alcotest.testable

  (** An {!Alcotest.testable} for {!Opium_kernel.Request.t} instances. *)
  val request : Opium_kernel.Request.t Alcotest.testable

  (** An {!Alcotest.testable} for {!Opium_kernel.Response.t} instances. *)
  val response : Opium_kernel.Response.t Alcotest.testable
end

(** {3 [handle_request]} *)

(** [handle_request app request response] processes a request [request] with the given
    Opium_kernel application [app].

    It processes the request the same [Opium_kernel.Server_connection.run] would and
    returns the generated response. *)
val handle_request
  :  Opium_kernel.Rock.App.t
  -> Opium_kernel.Request.t
  -> Opium_kernel.Response.t Lwt.t

(** {3 [check_status]} *)

(** [check_status ?msg t1 t2] checks that the status [t1] and [t2] are equal. *)
val check_status : ?msg:string -> Opium_kernel.Status.t -> Opium_kernel.Status.t -> unit

(** {3 [check_status']} *)

(** [check_status' ?msg t1 t2] checks that the status [t1] and [t2] are equal.

    This is a labeled variant of {!check_status} *)
val check_status'
  :  ?msg:string
  -> expected:Opium_kernel.Status.t
  -> actual:Opium_kernel.Status.t
  -> unit

(** {3 [check_meth]} *)

(** [check_meth ?msg t1 t2] checks that the method [t1] and [t2] are equal. *)
val check_meth : ?msg:string -> Opium_kernel.Method.t -> Opium_kernel.Method.t -> unit

(** {3 [check_meth']} *)

(** [check_meth' ?msg t1 t2] checks that the method [t1] and [t2] are equal.

    This is a labeled variant of {!check_meth} *)
val check_meth'
  :  ?msg:string
  -> expected:Opium_kernel.Method.t
  -> actual:Opium_kernel.Method.t
  -> unit

(** {3 [check_version]} *)

(** [check_version ?msg t1 t2] checks that the version [t1] and [t2] are equal. *)
val check_version
  :  ?msg:string
  -> Opium_kernel.Version.t
  -> Opium_kernel.Version.t
  -> unit

(** {3 [check_version']} *)

(** [check_version' ?msg t1 t2] checks that the version [t1] and [t2] are equal.

    This is a labeled variant of {!check_version} *)
val check_version'
  :  ?msg:string
  -> expected:Opium_kernel.Version.t
  -> actual:Opium_kernel.Version.t
  -> unit

(** {3 [check_body]} *)

(** [check_body ?msg t1 t2] checks that the body [t1] and [t2] are equal. *)
val check_body : ?msg:string -> Opium_kernel.Body.t -> Opium_kernel.Body.t -> unit

(** {3 [check_body']} *)

(** [check_body' ?msg t1 t2] checks that the body [t1] and [t2] are equal.

    This is a labeled variant of {!check_body} *)
val check_body'
  :  ?msg:string
  -> expected:Opium_kernel.Body.t
  -> actual:Opium_kernel.Body.t
  -> unit

(** {3 [check_request]} *)

(** [check_request ?msg t1 t2] checks that the request [t1] and [t2] are equal. *)
val check_request
  :  ?msg:string
  -> Opium_kernel.Request.t
  -> Opium_kernel.Request.t
  -> unit

(** {3 [check_request']} *)

(** [check_request' ?msg t1 t2] checks that the request [t1] and [t2] are equal.

    This is a labeled variant of {!check_request} *)
val check_request'
  :  ?msg:string
  -> expected:Opium_kernel.Request.t
  -> actual:Opium_kernel.Request.t
  -> unit

(** {3 [check_response]} *)

(** [check_response ?msg t1 t2] checks that the response [t1] and [t2] are equal. *)
val check_response
  :  ?msg:string
  -> Opium_kernel.Response.t
  -> Opium_kernel.Response.t
  -> unit

(** {3 [check_response']} *)

(** [check_response' ?msg t1 t2] checks that the response [t1] and [t2] are equal.

    This is a labeled variant of {!check_response} *)
val check_response'
  :  ?msg:string
  -> expected:Opium_kernel.Response.t
  -> actual:Opium_kernel.Response.t
  -> unit

(** {3 [assert_body_contains]} *)

(** [check_body_contains ?msg s t] checks that the body [t] contains the string [s]. *)
val check_body_contains : ?msg:string -> string -> Opium_kernel.Body.t -> unit Lwt.t
