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
let add map ~key ~data = S.add (E key) data map
let find map ~key =
  try Some (S.find (E key) map)
  with Not_found _ -> None
