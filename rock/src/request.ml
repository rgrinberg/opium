type t =
  { version : Httpaf.Version.t
  ; target : string
  ; headers : Httpaf.Headers.t
  ; meth : Httpaf.Method.t
  ; body : Body.t
  ; env : Context.t
  ; peer_addr : string
  }

let make
    ?(version = { Httpaf.Version.major = 1; minor = 1 })
    ?(body = Body.empty)
    ?(env = Context.empty)
    ?(headers = Httpaf.Headers.empty)
    ~peer_addr
    target
    meth
  =
  { version; target; headers; meth; body; env; peer_addr }
;;

let get ?version ?body ?env ?headers ~peer_addr target =
  make ?version ?body ?env ?headers ~peer_addr target `GET
;;

let post ?version ?body ?env ?headers ~peer_addr target =
  make ?version ?body ?env ?headers ~peer_addr target `POST
;;

let put ?version ?body ?env ?headers ~peer_addr target =
  make ?version ?body ?env ?headers ~peer_addr target `PUT
;;

let delete ?version ?body ?env ?headers ~peer_addr target =
  make ?version ?body ?env ?headers ~peer_addr target `DELETE
;;
