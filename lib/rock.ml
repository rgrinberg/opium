(** A tiny clone of ruby's Rack protocol in OCaml. It's not imperative
    to have this to for such a tiny framework but it makes extensions
    a lot more straightforward *)
open Core.Std
open Async.Std
open Cohttp
module Co = Cohttp

module Request = struct
  type t = {
    request: Cohttp.Request.t;
    mutable env: Univ_map.t;
  } with fields
  let create ?(env=Univ_map.empty) request =
    { request; env }
  let uri { request; _ } = Co.Request.uri request
  let meth { request; _ } = Co.Request.meth request
end

module Response = struct
  type t = {
    code: Code.status_code;
    headers: Header.t;
    body: string Pipe.Reader.t;
  } with fields

  let default_header = Option.value ~default:(Header.init ())

  let create ?body ?headers ?(code=`OK) () =
    { code;
      headers=Option.value ~default:(Header.init ()) headers;
      body= (match body with
          | None -> Pipe_extra.singleton ""
          | Some b -> b); }
  let string_body ?headers ?(code=`OK) body =
    { code; headers=default_header headers; body=(Pipe_extra.singleton body) }
end

module Handler = struct
  type t = Request.t -> Response.t Deferred.t
  let call app req = app req

  let default _ = return @@ Response.create ()
  let not_found _ =
    return @@ Response.string_body ~code:`Not_found
      "<html><body><h1>404 - Not found</h1></body></html>"
end

module Middleware = struct
  type t = Handler.t -> Handler.t

  let apply_middlewares middlewares handler =
    List.fold_left middlewares ~init:handler ~f:(fun h m -> m h)
end

module App = struct
  type t = {
    middlewares: Middleware.t list;
    handler: Handler.t
  } with fields

  let create ?(middlewares=[]) ~handler = { middlewares; handler }

  let run { handler; middlewares } ~port =
    let module Server = Cohttp_async.Server in
    let middlewares = List.rev middlewares in
    Server.create ~on_handler_error:`Raise (Tcp.on_port port)
      begin fun ~body sock req ->
        let req = Request.create req in
        let handler = Middleware.apply_middlewares middlewares handler in
        Handler.call handler req >>| fun {Response.code; headers; body} ->
        Server.respond ~headers ~body code
      end
end
