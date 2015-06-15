open Core_kernel.Std
open Cohttp
open Opium_misc

module Service = struct
  type ('req, 'rep) t = 'req -> 'rep Lwt.t with sexp
  let id req = return req
  let const resp = Fn.compose return (Fn.const resp)
end

module Filter = struct
  type ('req, 'rep, 'req_, 'rep_) t =
    ('req, 'rep) Service.t -> ('req_, 'rep_) Service.t with sexp
  type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t with sexp
  let id s = s
  let (>>>) f1 f2 s = s |> f1 |> f2
  let apply_all filters service =
    List.fold_left filters ~init:service ~f:(|>)
end

module Request = struct
  type t = {
    request: Co.Request.t;
    body: Body.t;
    env: Univ_map.t;
  } with fields, sexp_of

  let create ?(body=Body.empty) ?(env=Univ_map.empty) request =
    { request; env ; body }
  let uri     { request; _ } = Co.Request.uri request
  let meth    { request; _ } = Co.Request.meth request
  let headers { request; _ } = Co.Request.headers request
end

module Response = struct
  type t = {
    code: Code.status_code;
    headers: Header.t;
    body: Body.t;
    env: Univ_map.t
  } with fields, sexp_of

  let default_header = Option.value ~default:(Header.init ())

  let create ?(env=Univ_map.empty) ?(body=Body.empty)
        ?headers ?(code=`OK) () =
    { code; env;
      headers=Option.value ~default:(Header.init ()) headers;
      body; }

  let of_string_body ?(env=Univ_map.empty) ?headers ?(code=`OK) body =
    { env; code; headers=default_header headers; body=(Body.of_string body) }

  let of_response_body (resp, body) =
    let code = Response.status resp in
    let headers = Response.headers resp in
    create ~code ~headers ~body ()
end

module Handler = struct
  type t = (Request.t, Response.t) Service.t with sexp_of

  let default _ = return (Response.of_string_body "route failed (404)")

  let not_found _ =
    return (Response.of_string_body
              ~code:`Not_found
              "<html><body><h1>404 - Not found</h1></body></html>")
end

module Middleware = struct
  type t = {
    filter: (Request.t, Response.t) Filter.simple;
    name: Info.t;
  } with fields, sexp_of

  let create ~filter ~name = { filter ; name }

  let apply { filter; _ } handler = filter handler

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
      printf "%s\n" (headers |> Co.Header.to_lines |> String.concat);
      resp)

  let apply_middlewares_debug (middlewares : t list) handler =
    List.fold_left middlewares ~init:handler ~f:(fun h m ->
      wrap_debug (apply m h))
end

module App = struct
  type t = {
    middlewares: Middleware.t list;
    handler: Handler.t;
  } with fields, sexp_of

  let append_middleware t m =
    { t with middlewares=(t.middlewares @ [m]) }

  let create ?(middlewares=[]) ~handler = { middlewares; handler }

end
