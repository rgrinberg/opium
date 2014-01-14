open Core.Std
open Async.Std
open Rock

type builder

val param : Request.t -> string -> string
val respond : ?headers:Cohttp.Header.t -> ?code:Cohttp.Code.status_code ->
  [< `Html of Cow.Html.t
  | `Json of Cow.Json.t
  | `String of string
  | `Xml of Cow.Xml.t ] -> Response.t

val respond' : ?headers:Cohttp.Header.t -> ?code:Cohttp.Code.status_code ->
  [< `Html of Cow.Html.t
  | `Json of Cow.Json.t
  | `String of string
  | `Xml of Cow.Xml.t ] -> Response.t Deferred.t

type route = string -> Handler.t -> builder

val action : Router.meth -> route

val get : route
val post : route
val delete : route
val put : route

val patch : route
val options : route
val head : route

val start : ?verbose:bool -> ?debug:bool -> ?port:int
  -> ?extra_middlewares:(Rock.Middleware.t list)
  -> builder list -> never_returns
