(** This middleware will pretty print requests and exceptions in the
    event of a crash in the server. Useful for debugging. *)
val debug : Rock.Middleware.t
val trace : Rock.Middleware.t
