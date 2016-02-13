(** Module with helpful aliases in transitioning from async to lwt *)
let return = Lwt.return
let (>>|) = Lwt.(>|=)
let (>>=) = Lwt.(>>=)

module Co     = Cohttp
module Body   = Cohttp_lwt_body
module Server = Cohttp_lwt_unix.Server
