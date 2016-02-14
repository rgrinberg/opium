let return = Lwt.return
let (>>=) = Lwt.(>>=)
let (>>|) = Lwt.(>|=)

module Body = Cohttp_lwt_body
