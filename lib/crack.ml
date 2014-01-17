open Core.Std
open Async.Std

module Service = struct
  type ('req, 'rep) t = 'req -> 'rep Deferred.t
  let id req = return req
end

module Filter = struct
  type ('req, 'rep, 'req_, 'rep_) t =
    ('req, 'rep) Service.t -> ('req_, 'rep_) Service.t
  type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t
  let id s = s
  let (>>>) f1 f2 s = s |> f1 |> f2
  let apply_all filters service =
    List.fold_left filters ~init:service ~f:(|>)
  let apply_all' filters service =
    Array.fold filters ~init:service ~f:(|>)
end
