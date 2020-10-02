(** Middleware is a named, simple filter, that only works on rock requests/response. *)

type t = private
  { filter : (Request.t, Response.t) Filter.simple
  ; name : string
  }

val create : filter:(Request.t, Response.t) Filter.simple -> name:string -> t
val apply : t -> Handler.t -> Handler.t
