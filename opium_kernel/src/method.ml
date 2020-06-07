include Httpaf.Method

let sexp_of_t meth = Sexplib0.Sexp_conv.sexp_of_string (to_string (meth :> t))
let string_of_t meth = to_string (meth :> t)
let pp_hum fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
let pp_string fmt t = Format.fprintf fmt "%s" (string_of_t t)
