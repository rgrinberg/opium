type t =
  { version : Httpaf.Version.t
  ; target : string
  ; headers : Httpaf.Headers.t
  ; meth : Httpaf.Method.t
  ; body : Body.t
  ; env : Context.t
  }

let make
    ?(version = { Httpaf.Version.major = 1; minor = 1 })
    ?(body = Body.empty)
    ?(env = Context.empty)
    ?(headers = Httpaf.Headers.empty)
    target
    meth
  =
  { version; target; headers; meth; body; env }
;;

let get ?version ?body ?env ?headers target =
  make ?version ?body ?env ?headers target `GET
;;

let post ?version ?body ?env ?headers target =
  make ?version ?body ?env ?headers target `POST
;;

let put ?version ?body ?env ?headers target =
  make ?version ?body ?env ?headers target `PUT
;;

let delete ?version ?body ?env ?headers target =
  make ?version ?body ?env ?headers target `DELETE
;;
