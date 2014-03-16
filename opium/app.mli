open Core.Std
open Async.Std
open Rock

(** An opium app is a simple builder wrapper around a rock app *)
type t with sexp_of

(** Functions for constructing an opium app *)
val app : t

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

(** Convert an opium app to a rock app  *)
val create : t -> Rock.App.t

val middleware : Middleware.t -> builder

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

val respond' : ?headers:Cohttp.Header.t
  -> ?code:Cohttp.Code.status_code
  -> body
  -> Response.t Deferred.t
