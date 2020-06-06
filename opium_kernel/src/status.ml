include Httpaf.Status

let sexp_of_t status =
  let open Sexplib0 in
  let open Sexp_conv in
  sexp_of_int (to_code status)
;;

let string_of_t status = string_of_int (to_code status)
let pp_hum fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
let pp_string fmt t = Format.fprintf fmt "%s" (string_of_t t)
