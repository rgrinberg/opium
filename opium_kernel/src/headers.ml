include Httpaf.Headers

let add_list_unless_exists t hs =
  ListLabels.fold_left hs ~init:t ~f:(fun acc (k, v) -> add_unless_exists acc k v)
;;

let sexp_of_t headers =
  let open Sexplib0 in
  let open Sexp_conv in
  let sexp_of_header = sexp_of_list (sexp_of_pair sexp_of_string sexp_of_string) in
  sexp_of_header (to_list headers)
;;

let string_of_t headers =
  to_list headers
  |> List.map (fun (header, value) -> Printf.sprintf "%s: %s" header value)
  |> String.concat "\n"
;;

let pp_hum fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
let pp_string fmt t = Format.fprintf fmt "%s" (string_of_t t)
