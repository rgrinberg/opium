include Hmap.Make(struct type 'a t = string * ('a -> Sexplib.Sexp.t) end)

let sexp_of_t m =
  let open Sexplib.Sexp in
  let l = fold (fun (B (k,v)) l ->
    let (name, to_sexp) = Key.info k in
    List [Atom name; to_sexp v] :: l) m []
  in
  List l

let find_exn t k =
  match find t k with
  | None -> raise Not_found
  | Some s -> s
