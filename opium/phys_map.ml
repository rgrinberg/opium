type e = E : 'a -> e
module S =
  Map.Make(struct
    type t = e
    let compare (E x) (E y) =
      if x == (Obj.magic y) then
        0
      else
        Hashtbl.(compare (hash x) (hash y))
  end)
type 'a t = 'a S.t
let empty = S.empty
let mem map ~key = S.mem (E key) map
let remove map ~key = S.remove (E key) map
let find map ~key =
  try Some (S.find (E key) map)
  with Not_found _ -> None
let add map ~key ~data =
  match find map ~key with
  | Some _ -> `Duplicate
  | None -> `Ok (S.add (E key) data map)
let add_exn map ~key ~data =
  match add map ~key ~data with
  | `Duplicate -> invalid_arg "Phys_map.add_exn: Duplicate key"
  | `Ok s -> s
