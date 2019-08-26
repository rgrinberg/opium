val debug : Opium_kernel.Rock.Middleware.t
(** This middleware will pretty print requests and exceptions in the event of a
    crash in the server. Useful for debugging. *)

val trace : Opium_kernel.Rock.Middleware.t
