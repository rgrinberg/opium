module K : module type of struct
  include Opium_kernel.Make (Cohttp_lwt_unix.IO)
end

val debug : K.Rock.Middleware.t
(** This middleware will pretty print requests and exceptions in the event of a
    crash in the server. Useful for debugging. *)

val trace : K.Rock.Middleware.t
