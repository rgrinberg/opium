open Core.Std
open Async.Std

open Rock

type t = {
  prefix: string;
  local_path: string;
} with fields

val error_body_default : string

val legal_path : t -> string -> string option

val public_serve : t -> requested:string -> Response.t Deferred.t

val m : local_path:string -> uri_prefix:string -> Middleware.t
