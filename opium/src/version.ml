open Import
include Httpaf.Version

let sexp_of_t version =
  let open Sexp_conv in
  Sexp.List
    [ List [ Atom "major"; sexp_of_int version.major ]
    ; List [ Atom "minor"; sexp_of_int version.minor ]
    ]
;;

let pp fmt t = Sexp.pp_hum fmt (sexp_of_t t)
let pp_hum fmt t = Format.fprintf fmt "%s" (to_string t)
