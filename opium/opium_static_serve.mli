(** Middleware serves all files (recursively) in the [local_path] directory
    under the [uri_prefix] url.  The responses contain a [Content-type]
    header that is auto-detected based on the file extension using the
    {!Magic_mime.lookup} function. *)
val m : local_path:string -> uri_prefix:string -> Opium_kernel.Rock.Middleware.t
