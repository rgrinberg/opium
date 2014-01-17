open Core.Std
open Async.Std

module Service : sig
  type ('req, 'rep) t = 'req -> 'rep Deferred.t

  val id : ('a, 'a) t
end

module Filter : sig
  type ('req, 'rep, 'req', 'rep') t =
    ('req, 'rep) Service.t -> ('req', 'rep') Service.t

  type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t

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
  } with fields

  val create : ?env:Univ_map.t -> Cohttp.Request.t -> t
  val uri : t -> Uri.t
  val meth : t -> Cohttp.Code.meth
end

module Response : sig
  type t = {
    code : Cohttp.Code.status_code;
    headers : Cohttp.Header.t;
    body : string Pipe.Reader.t;
    env: Univ_map.t
  } with fields

  val create :
    ?env: Univ_map.t ->
    ?body:string Pipe.Reader.t ->
    ?headers:Cohttp.Header.t -> ?code:Cohttp.Code.status_code -> unit -> t

  val string_body :
    ?env: Univ_map.t ->
    ?headers:Cohttp.Header.t ->
    ?code:Cohttp.Code.status_code -> string -> t
end

module Handler : sig
  type t = (Request.t, Response.t) Service.t
  val default : t
  val not_found : t
end

module Middleware : sig
  type t = (Request.t, Response.t) Filter.simple
end

module App : sig
  type t = {
    middlewares : Middleware.t list;
    handler : Handler.t;
  } with fields

  val create : ?middlewares:Middleware.t list -> handler:Handler.t -> t
  val run : t -> port:int ->
    (Async_extra.Import.Socket.Address.Inet.t, int) Cohttp_async.Server.t
      Deferred.t
end
