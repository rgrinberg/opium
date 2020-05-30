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

module Pp = struct
  open Sexplib0
  open Sexp_conv

  let sexp_of_version version =
    Sexp.(
      List
        [ Atom "version"
        ; List [Atom "major"; sexp_of_int version.Httpaf.Version.major]
        ; List [Atom "minor"; sexp_of_int version.minor] ])

  let sexp_of_target target = Sexp.(List [Atom "target"; sexp_of_string target])

  let sexp_of_headers headers =
    let sexp_of_header =
      sexp_of_list (sexp_of_pair sexp_of_string sexp_of_string)
    in
    Sexp.(
      List [Atom "headers"; sexp_of_header (Httpaf.Headers.to_list headers)])

  let sexp_of_meth meth =
    Sexp.(
      List
        [ Atom "method"
        ; sexp_of_string (Httpaf.Method.to_string (meth :> Httpaf.Method.t)) ])

  let sexp_of_body body = Sexp.(List [Atom "body"; Body.sexp_of_t body])

  let sexp_of_env env = Sexp.(List [Atom "env"; Hmap0.sexp_of_t env])

  let sexp_of_status status =
    Sexp.(List [Atom "status"; sexp_of_int (Httpaf.Status.to_code status)])

  let sexp_of_reason reason =
    Sexp.(List [Atom "reason"; sexp_of_option sexp_of_string reason])
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

  let sexp_of_t t =
    Sexplib0.Sexp.(
      List
        [ Pp.sexp_of_version t.version
        ; Pp.sexp_of_target t.target
        ; Pp.sexp_of_headers t.headers
        ; Pp.sexp_of_meth t.meth
        ; Pp.sexp_of_body t.body
        ; Pp.sexp_of_env t.env ])

  let pp_hum fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
end

module Response = struct
  type t =
    { version: Httpaf.Version.t
    ; status: Httpaf.Status.t
    ; reason: string option
    ; headers: Httpaf.Headers.t
    ; body: Body.t
    ; env: Hmap0.t }

  let make ?(version = {Httpaf.Version.major= 1; minor= 1}) ?(status = `OK)
      ?reason ?(headers = Httpaf.Headers.empty) ?(body = Body.empty)
      ?(env = Hmap0.empty) () =
    {version; status; reason; headers; body; env}

  let sexp_of_t {version; status; reason; headers; body; env} =
    Sexplib0.Sexp.(
      List
        [ Pp.sexp_of_version version
        ; Pp.sexp_of_status status
        ; Pp.sexp_of_reason reason
        ; Pp.sexp_of_headers headers
        ; Pp.sexp_of_body body
        ; Pp.sexp_of_env env ])

  let pp_hum fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
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
