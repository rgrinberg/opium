open Core.Std
open Async.Std
open Rock

(** An opium app is a simple builder wrapper around a rock app *)
type t with sexp_of

(** empty app skeleton *)
val app : t

type builder = t -> t with sexp_of

type body = [
  | `Html of Cow.Html.t
  | `Json of Cow.Json.t
  | `String of string
  | `Xml of Cow.Xml.t ]

val param : Request.t -> string -> string

val respond : ?headers:Cohttp.Header.t
  -> ?code:Cohttp.Code.status_code
  -> body
  -> Response.t

val respond' : ?headers:Cohttp.Header.t
  -> ?code:Cohttp.Code.status_code
  -> body
  -> Response.t Deferred.t

type route = string -> Handler.t -> builder with sexp_of

val get : route
val post : route
val delete : route
val put : route

val patch : route
val options : route
val head : route

val action : Cohttp.Code.meth -> route

val create : t -> Rock.App.t

val middleware : Middleware.t -> builder

val start : ?verbose:bool -> ?debug:bool -> ?port:int
  -> ?extra_middlewares:(Rock.Middleware.t list)
  -> builder list -> never_returns

val command : ?name:string -> Rock.App.t -> Command.t
