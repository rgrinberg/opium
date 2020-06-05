include Httpaf.Version

let sexp_of_t version =
  let open Sexplib0 in
  let open Sexp_conv in
  Sexp.List
    [ List [ Atom "major"; sexp_of_int version.major ]
    ; List [ Atom "minor"; sexp_of_int version.minor ]
    ]
;;

let string_of_t version = Printf.sprintf "%d.%d" version.major version.minor
let pp_hum fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
let pp_string fmt t = Format.fprintf fmt "%s" (string_of_t t)
