type t =
  { version : Httpaf.Version.t
  ; target : string
  ; headers : Httpaf.Headers.t
  ; meth : Httpaf.Method.t
  ; body : Body.t
  ; env : Context.t
  }

let client_address =
  Context.Key.create ("client address", Sexplib0.Sexp_conv.sexp_of_string)
;;

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

let with_client_address t addr = { t with env = Context.add client_address addr t.env }
let client_address t = Context.find client_address t.env

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
