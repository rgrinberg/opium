open Import
include Httpaf.Method

let sexp_of_t meth = Sexp_conv.sexp_of_string (to_string meth)
let pp fmt t = Sexp.pp_hum fmt (sexp_of_t t)
