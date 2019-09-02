module Fn = struct
  let compose f g x = f (g x)

  let const f _ = f
end

module Service = struct
  type ('req, 'res) t = 'req -> 'res Lwt.t

  let id req = Lwt.return req

  let const resp = Fn.compose Lwt.return (Fn.const resp)
end

module Filter = struct
  type ('req, 'res, 'req_, 'res_) t =
    ('req, 'res) Service.t -> ('req_, 'res_) Service.t

  type ('req, 'res) simple = ('req, 'res, 'req, 'res) t

  let id s = s

  let ( >>> ) f1 f2 = Fn.compose f2 f1

  let apply_all filters service =
    ListLabels.fold_left ~f:( |> ) ~init:service filters
end
