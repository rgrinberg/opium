val debug : Rock.Middleware.t
(** This middleware will pretty print requests and exceptions in the event of a
    crash in the server. Useful for debugging. *)

val trace : Rock.Middleware.t
