module Body = Body
module Status = Status
module Version = Version
module Headers = Headers
module Method = Method
module Request = Request
module Response = Response

module Service = struct
  type ('req, 'res) t = 'req -> 'res Lwt.t

  let id req = Lwt.return req
end

module Filter = struct
  type ('req, 'rep, 'req_, 'rep_) t = ('req, 'rep) Service.t -> ('req_, 'rep_) Service.t
  type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t

  let ( >>> ) f1 f2 s = s |> f1 |> f2
  let apply_all filters service = ListLabels.fold_left filters ~init:service ~f:( |> )
end

module Handler = struct
  type t = (Request.t, Response.t) Service.t
end

module Middleware = struct
  type t =
    { filter : (Request.t, Response.t) Filter.simple
    ; name : string
    }

  let create ~filter ~name = { filter; name }
  let apply { filter; _ } handler = filter handler
end

module App = struct
  type t =
    { middlewares : Middleware.t list
    ; handler : Handler.t
    }

  let append_middleware t m = { t with middlewares = t.middlewares @ [ m ] }
  let create ?(middlewares = []) ~handler () = { middlewares; handler }
end

exception Halt of Response.t

let halt response = raise (Halt response)
