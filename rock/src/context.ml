include Hmap.Make (struct
  type 'a t = string * ('a -> Sexplib0.Sexp.t)
end)
