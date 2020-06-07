module Exn = struct
  type t = exn

  let sexp_of_t = Sexplib0.Sexp_conv.sexp_of_exn
  let pp fmt t = Sexplib0.Sexp.pp fmt t
  let to_string t = Printexc.to_string t
end
