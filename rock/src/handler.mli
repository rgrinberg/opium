(** A handler is a rock specific service. *)

type t = (Request.t, Response.t) Service.t
