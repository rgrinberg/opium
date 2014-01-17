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
end
