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

module Request = struct
  type t =
    { version: Httpaf.Version.t
    ; target: string
    ; headers: Httpaf.Headers.t
    ; meth: Httpaf.Method.standard
    ; body: Body.t
    ; env: Hmap0.t }

  let make ?(version = {Httpaf.Version.major= 1; minor= 1}) ?(body = Body.empty)
      ?(env = Hmap0.empty) ?(headers = Httpaf.Headers.empty) target meth () =
    {version; target; headers; meth; body; env}

  let pp_hum fmt {version; target; headers; meth; _} =
    Format.fprintf fmt
      "((method \"%a\") (target %S) (version \"%a\") (headers %a))"
      Httpaf.Method.pp_hum
      (meth :> Httpaf.Method.t)
      target Httpaf.Version.pp_hum version Httpaf.Headers.pp_hum headers
end

module Response = struct
  type t =
    { version: Httpaf.Version.t option
    ; status: Httpaf.Status.t
    ; reason: string option
    ; headers: Httpaf.Headers.t
    ; body: Body.t
    ; env: Hmap0.t }

  let make ?version ?(status = `OK) ?reason ?(headers = Httpaf.Headers.empty)
      ?(body = Body.empty) ?(env = Hmap0.empty) () =
    {version; status; reason; headers; body; env}
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
