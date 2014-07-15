(** This middleware will pretty print requests and exceptions in the
    event of a crash in the server. Useful for debugging. *)
val debug : Opium_rock.Middleware.t
val trace : Opium_rock.Middleware.t
