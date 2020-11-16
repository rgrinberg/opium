include Sexplib0

module List = struct
  include ListLabels

  let rec filter_opt = function
    | [] -> []
    | None :: l -> filter_opt l
    | Some x :: l -> x :: filter_opt l
  ;;

  let rec find_map ~f = function
    | [] -> None
    | x :: l ->
      (match f x with
      | Some _ as result -> result
      | None -> find_map ~f l)
  ;;

  let replace_or_add_to_list ~f to_add l =
    let rec aux acc l found =
      match l with
      | [] -> rev (if not found then to_add :: acc else acc)
      | el :: rest ->
        if f el to_add then aux (to_add :: acc) rest true else aux (el :: acc) rest found
    in
    aux [] l false
  ;;
end

module String = struct
  include StringLabels

  let rec check_prefix s ~prefix len i =
    i = len || (s.[i] = prefix.[i] && check_prefix s ~prefix len (i + 1))
  ;;

  let is_prefix s ~prefix =
    let len = length s in
    let prefix_len = length prefix in
    len >= prefix_len && check_prefix s ~prefix prefix_len 0
  ;;
end
