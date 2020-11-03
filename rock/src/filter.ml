type ('req, 'rep, 'req_, 'rep_) t = ('req, 'rep) Service.t -> ('req_, 'rep_) Service.t
type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t

let ( >>> ) f1 f2 s = s |> f1 |> f2
let apply_all filters service = ListLabels.fold_left filters ~init:service ~f:( |> )
