(** A tiny clone of ruby's Rack protocol in OCaml based on "Crack"
    which is slightly more general and inspired by Finagle. It's not
    imperative to have this to for such a tiny framework but it makes
    extensions a lot more straightforward *)
open Core.Std
open Async.Std
open Cohttp
open Crack
module Co = Cohttp

module Request = struct
  type t = {
    request: Cohttp.Request.t;
    env: Univ_map.t;
  } with fields

  let create ?(env=Univ_map.empty) request = { request; env }
  let uri { request; _ } = Co.Request.uri request
  let meth { request; _ } = Co.Request.meth request
end

module Response = struct
  type t = {
    code: Code.status_code;
    headers: Header.t;
    body: string Pipe.Reader.t;
    env: Univ_map.t
  } with fields

  let default_header = Option.value ~default:(Header.init ())

  let create ?(env=Univ_map.empty) ?body ?headers ?(code=`OK) () =
    { code; env;
      headers=Option.value ~default:(Header.init ()) headers;
      body= (match body with
        | None -> Pipe_extra.singleton ""
        | Some b -> b); }
  let string_body ?(env=Univ_map.empty) ?headers ?(code=`OK) body =
    { env; code; headers=default_header headers; body=(Pipe_extra.singleton body) }
end

module Handler = struct
  type t = (Request.t, Response.t) Service.t

  let default _ = return @@ Response.string_body "route failed (404)"

  let not_found _ =
    return @@ Response.string_body
                ~code:`Not_found
                "<html><body><h1>404 - Not found</h1></body></html>"
end

module Middleware = struct
  type t = (Request.t, Response.t) Filter.simple

  (* wrap_debug/apply_middlewares_debug are used for debugging when
     middlewares are stepping over each other *)
  let wrap_debug handler ({ Request.env ; request } as req) =
    let env = Univ_map.sexp_of_t env in
    let req' = request
               |> Co.Request.headers
               |> Co.Header.to_lines in
    printf "Env:\n%s\n" (Sexp.to_string_hum env);
    printf "%s\n" (String.concat req');
    let resp = handler req in
    resp >>| (fun ({Response.headers; _} as resp) ->
      printf "%s\n" (String.concat @@
                     (headers |> Co.Header.to_lines)
                    );
      resp)

  let apply_middlewares_debug (middlewares : t list) handler =
    List.fold_left middlewares ~init:handler ~f:(fun h m ->
      wrap_debug (m h))
end

module App = struct
  type t = {
    middlewares: Middleware.t list;
    handler: Handler.t
  } with fields

  let create ?(middlewares=[]) ~handler = { middlewares; handler }

  let run { handler; middlewares } ~port =
    let module Server = Cohttp_async.Server in
    let middlewares = Array.of_list middlewares in
    Server.create
      ~on_handler_error:`Raise (Tcp.on_port port)
      begin fun ~body sock req ->
        let req = Request.create req in
        let handler = Filter.apply_all' middlewares handler in
        handler req >>| fun {Response.code; headers; body} ->
        Server.respond ~headers ~body code
      end
end
