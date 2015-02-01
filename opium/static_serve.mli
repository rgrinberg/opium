(** Middleware serves all fiels (recursively) in the [local_path] directory
    under the [uri_prefix] url *)
val m : local_path:string -> uri_prefix:string -> Opium_rock.Middleware.t
