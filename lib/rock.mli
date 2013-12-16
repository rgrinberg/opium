
module Request : sig
  type t = { request : Cohttp.Request.t; env : Core.Std.Univ_map.t; } with fields
  val create : ?env:Core.Std.Univ_map.t -> Cohttp.Request.t -> t
  val uri : t -> Uri.t
  val meth : t -> Cohttp.Code.meth
end

module Response : sig
  type t = {
    code : Cohttp.Code.status_code;
    headers : Cohttp.Header.t;
    body : string Async.Std.Pipe.Reader.t;
  }
  val default_header : Cohttp.Header.t Core.Std.Option.t -> Cohttp.Header.t
  val create :
    ?body:string Async.Std.Pipe.Reader.t ->
    ?headers:Cohttp.Header.t -> ?code:Cohttp.Code.status_code -> unit -> t
  val string_body :
    ?headers:Cohttp.Header.t ->
    ?code:Cohttp.Code.status_code -> string -> t
end

module Handler : sig
  type t = Request.t -> Response.t Async.Std.Deferred.t
  val call : ('a -> 'b) -> 'a -> 'b
  val default : 'a -> Response.t Async_core.Deferred.t
  val not_found : 'a -> Response.t Async_core.Deferred.t
end

module Middleware : sig
  type t = Handler.t -> Handler.t
  val apply_middlewares : ('a -> 'a) Core.Std.List.t -> 'a -> 'a
end

module App : sig
  type t = { middlewares : Middleware.t list; handler : Handler.t; }
  val create : ?middlewares:Middleware.t list -> handler:Handler.t -> t
  val run :
    t ->
    port:int ->
    (Async_extra.Import.Socket.Address.Inet.t, int) Cohttp_async.Server.t
      Async.Std.Deferred.t
end
