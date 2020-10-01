type t =
  { version : Version.t
  ; status : Status.t
  ; reason : string option
  ; headers : Headers.t
  ; body : Body.t
  ; env : Context.t
  }

let make
    ?(version = { Version.major = 1; minor = 1 })
    ?(status = `OK)
    ?reason
    ?(headers = Headers.empty)
    ?(body = Body.empty)
    ?(env = Context.empty)
    ()
  =
  { version; status; reason; headers; body; env }
;;

let sexp_of_t { version; status; reason; headers; body; env } =
  let open Sexplib0.Sexp_conv in
  let open Sexplib0.Sexp in
  List
    [ List [ Atom "version"; Version.sexp_of_t version ]
    ; List [ Atom "status"; Status.sexp_of_t status ]
    ; List [ Atom "reason"; sexp_of_option sexp_of_string reason ]
    ; List [ Atom "headers"; Headers.sexp_of_t headers ]
    ; List [ Atom "body"; Body.sexp_of_t body ]
    ; List [ Atom "env"; Context.sexp_of_t env ]
    ]
;;

let http_string_of_t t =
  Format.asprintf
    "%a %a %s\n%a\n%a"
    Version.pp_hum
    t.version
    Status.pp_hum
    t.status
    (Option.value ~default:"" t.reason)
    Headers.pp_hum
    t.headers
    Body.pp_hum
    t.body
;;

let pp fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
let pp_hum fmt t = Format.fprintf fmt "%s\n%!" (http_string_of_t t)
