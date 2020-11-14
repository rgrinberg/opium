open Import
include Httpaf.Headers

let add_list_unless_exists t hs =
  List.fold_left hs ~init:t ~f:(fun acc (k, v) -> add_unless_exists acc k v)
;;

let sexp_of_t headers =
  let open Sexp_conv in
  let sexp_of_header = sexp_of_list (sexp_of_pair sexp_of_string sexp_of_string) in
  sexp_of_header (to_list headers)
;;

let pp fmt t = Sexp.pp_hum fmt (sexp_of_t t)
let pp_hum fmt t = Format.fprintf fmt "%s" (to_string t)
