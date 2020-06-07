include Httpaf.Method

let sexp_of_t meth = Sexplib0.Sexp_conv.sexp_of_string (to_string meth)
let pp_hum fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
