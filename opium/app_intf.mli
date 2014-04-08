(** An opium app provides a set of convenience functions and types to construct
    a rock app.

    - Re-exporting common functions needed in handlers
    - Easy handling of routes and bodies
    - Automatic generation of a command line app
*)
open Core.Std
open Async.Std
open Rock

(** You may provide your own router by implementing the following
    signature. The default app is instantiated with [Opium.Router] *)
module type Router = sig
  module Route : sig
    type t with sexp
    val of_string : string -> t
  end
  (* TODO: remove this extraneous type variable *)
  type 'action t with sexp
  val create : unit -> _ t
  val add : 'a t
    -> route:Route.t
    -> meth:Cohttp.Code.meth
    -> action:'a -> unit
  val param : Request.t -> string -> string
  val m : Handler.t t -> Middleware.t
end

module type S = sig
  (** An opium app is a simple builder wrapper around a rock app *)
  type t with sexp_of

  (** A basic empty app *)
  val app : t

  (** A builder is a function that transforms an [app] by adding some
      functionality. Builders are usuallys composed with a base app
      using (|>) to create a full app *)
  type builder = t -> t with sexp_of

  val port : int -> builder

  (** A route is a function that returns a buidler that hooks up a
      handler to a url mapping *)
  type route = string -> Handler.t -> builder with sexp_of

  (** Method specific routes *)
  val get : route
  val post : route
  val delete : route
  val put : route

  (** Less common method specific routes  *)
  val patch : route
  val options : route
  val head : route

  val action : Cohttp.Code.meth -> route

  val middleware : Middleware.t -> builder

  (** Convert an opium app to a rock app *)
  val create : t -> Rock.App.t

  val start : ?on_handler_error:Rock.App.error_handler -> t -> never_returns

  (** Create a core command from a rock app *)
  val command : ?on_handler_error:Rock.App.error_handler
    -> ?summary:string -> Rock.App.t -> Command.t

  (** Convenience functions for a running opium app *)
  type body = [
    | `Html of Cow.Html.t
    | `Json of Cow.Json.t
    | `Xml of Cow.Xml.t
    | `String of string ]

  val json_of_body_exn : Request.t -> Cow.Json.t Deferred.t

  val param : Request.t -> string -> string

  val respond : ?headers:Cohttp.Header.t
    -> ?code:Cohttp.Code.status_code
    -> body
    -> Response.t

  (* Same as return (respond ...) *)
  val respond' : ?headers:Cohttp.Header.t
    -> ?code:Cohttp.Code.status_code
    -> body
    -> Response.t Deferred.t
end
