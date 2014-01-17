open Core.Std
open Async.Std

val m : local_path:string -> uri_prefix:string -> Rock.Middleware.t
