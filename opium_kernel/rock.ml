module Service = struct
  type ('req, 'res) t = 'req -> 'res Lwt.t

  let id req = Lwt.return req
end

module Filter = struct
  type ('req, 'rep, 'req_, 'rep_) t =
    ('req, 'rep) Service.t -> ('req_, 'rep_) Service.t
  [@@deriving sexp]

  type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t [@@deriving sexp]

  let ( >>> ) f1 f2 s = s |> f1 |> f2

  let apply_all filters service =
    ListLabels.fold_left filters ~init:service ~f:( |> )
end

module Handler = struct
  type t = (Request.t, Response.t) Service.t
end

module Middleware = struct
  type t = {filter: (Request.t, Response.t) Filter.simple; name: string}

  let create ~filter ~name = {filter; name}

  let apply {filter; _} handler = filter handler
end

module App = struct
  type t = {middlewares: Middleware.t list; handler: Handler.t}

  let append_middleware t m = {t with middlewares= t.middlewares @ [m]}

  let create ?(middlewares = []) ~handler = {middlewares; handler}
end
