type ('req, 'res) t = 'req -> 'res Lwt.t

let id req = Lwt.return req

let const resp = Fn.compose Lwt.return (Fn.const resp)
