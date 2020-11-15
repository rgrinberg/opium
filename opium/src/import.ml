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
end

module String = StringLabels
