open Core.Std
open Async.Std
open Rock

type 'a filter = 'a -> 'a Deferred.t
type 'a t
type 'a builder

val param : Request.t -> string -> string
val respond : ?headers:Cohttp.Header.t -> ?code:Cohttp.Code.status_code ->
  [< `Html of Cow.Html.t
  | `Json of Cow.Json.t
  | `String of string
  | `Xml of Cow.Xml.t ] -> Response.t Deferred.t

val get : string -> 'a -> 'a builder
val post : string -> 'a -> 'a builder
val delete : string -> 'a -> 'a builder
val put : string -> 'a -> 'a builder

val start : ?verbose:bool -> ?debug:bool -> ?port:int
  -> ?extra_middlewares:(Rock.Middleware.t list)
  -> Handler.t builder list -> never_returns
