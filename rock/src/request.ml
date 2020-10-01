type t =
  { version : Version.t
  ; target : string
  ; headers : Headers.t
  ; meth : Method.t
  ; body : Body.t
  ; env : Context.t
  }

let make
    ?(version = { Version.major = 1; minor = 1 })
    ?(body = Body.empty)
    ?(env = Context.empty)
    ?(headers = Headers.empty)
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

let sexp_of_t { version; target; headers; meth; body; env } =
  let open Sexplib0.Sexp_conv in
  let open Sexplib0.Sexp in
  List
    [ List [ Atom "version"; Version.sexp_of_t version ]
    ; List [ Atom "target"; sexp_of_string target ]
    ; List [ Atom "method"; Method.sexp_of_t meth ]
    ; List [ Atom "headers"; Headers.sexp_of_t headers ]
    ; List [ Atom "body"; Body.sexp_of_t body ]
    ; List [ Atom "env"; Context.sexp_of_t env ]
    ]
;;

let pp fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)

let pp_hum fmt t =
  Format.fprintf
    fmt
    "%s %s %s\n%s\n\n%a\n%!"
    (Method.to_string t.meth)
    t.target
    (Version.to_string t.version)
    (Headers.to_string t.headers)
    Body.pp_hum
    t.body
;;
