open Core.Std
open Async.Std

module Service : sig
  type ('req, 'rep) t = 'req -> 'rep Deferred.t with sexp

  val id : ('a, 'a) t
end

module Filter : sig
  type ('req, 'rep, 'req', 'rep') t =
    ('req, 'rep) Service.t -> ('req', 'rep') Service.t
  with sexp

  type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t
  with sexp

  val id : ('req, 'rep) simple

  val (>>>) : ('q1, 'p1, 'q2, 'p2) t
    -> ('q2, 'p2, 'q3, 'p3) t
    -> ('q1, 'p1, 'q3, 'p3) t

  val apply_all : ('req, 'rep) simple List.t
    -> ('req, 'rep) Service.t
    -> ('req, 'rep) Service.t

  val apply_all' : ('req, 'rep) simple Array.t
    -> ('req, 'rep) Service.t
    -> ('req, 'rep) Service.t
end

module Request : sig
  type t = {
    request : Cohttp.Request.t;
    env : Univ_map.t;
  } with fields, sexp_of

  val create : ?env:Univ_map.t -> Cohttp.Request.t -> t
  val uri : t -> Uri.t
  val meth : t -> Cohttp.Code.meth
  val headers : t -> Cohttp.Header.t
end

module Response : sig
  type t = {
    code : Cohttp.Code.status_code;
    headers : Cohttp.Header.t;
    body : Cohttp_async.Body.t;
    env: Univ_map.t
  } with fields, sexp_of

  val create :
    ?env: Univ_map.t ->
    ?body:Cohttp_async.Body.t ->
    ?headers:Cohttp.Header.t -> ?code:Cohttp.Code.status_code -> unit -> t

  val string_body :
    ?env: Univ_map.t ->
    ?headers:Cohttp.Header.t ->
    ?code:Cohttp.Code.status_code -> string -> t
end

module Handler : sig
  type t = (Request.t, Response.t) Service.t with sexp_of
  val default : t
  val not_found : t
end

module Middleware : sig
  type t = {
    filter: (Request.t, Response.t) Filter.simple;
    name: Info.t;
  } with fields, sexp_of

  val create : filter:(Request.t, Response.t) Filter.simple -> name:Info.t -> t
end

module App : sig
  type t = {
    middlewares : Middleware.t list;
    handler : Handler.t;
  } with fields, sexp_of

  val append_middleware : t -> Middleware.t -> t

  val create : ?middlewares:Middleware.t list -> handler:Handler.t -> t
  val run : t -> port:int ->
    (Socket.Address.Inet.t, int) Cohttp_async.Server.t
      Deferred.t
end
