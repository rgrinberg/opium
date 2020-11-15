include Sexplib0

module List = struct
  include ListLabels

  let rec filter_opt = function
    | [] -> []
    | None :: l -> filter_opt l
    | Some x :: l -> x :: filter_opt l
  ;;
end

module String = StringLabels
