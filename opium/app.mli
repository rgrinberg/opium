(** An opium app provides a set of convenience functions and types to construct
    a rock app.

    - Re-exporting common functions needed in handlers
    - Easy handling of routes and bodies
    - Automatic generation of a command line app
*)
open Core.Std
open Async.Std
open Rock

(** An opium app is a simple builder wrapper around a rock app *)
type t with sexp_of

(** A basic empty app *)
val app : t

(** A builder is a function that transforms an [app] by adding some
    functionality. Builders are usuallys composed with a base app
    using (|>) to create a full app *)
type builder = t -> t with sexp_of

val port : int -> builder

type route = string -> Handler.t -> builder with sexp_of

val get : route
val post : route
val delete : route
val put : route

val patch : route
val options : route
val head : route

val action : Cohttp.Code.meth -> route

val middleware : Middleware.t -> builder

(** Convert an opium app to a rock app *)
val create : t -> Rock.App.t

val start : t -> never_returns

(** Create a core command from a rock app *)
val command : ?summary:string -> Rock.App.t -> Command.t

(** Convenience functions for a running opium app *)
type body = [
  | `Html of Cow.Html.t
  | `Json of Cow.Json.t
  | `Xml of Cow.Xml.t
  | `String of string ]

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
