(** A tiny clone of ruby's Rack protocol in OCaml. Which is slightly
    more general and inspired by Finagle. It's not imperative to have
    this to for such a tiny framework but it makes extensions a lot
    more straightforward *)

(** A service is simply a function that returns its result
    asynchronously *)
module Service : sig
  type ('req, 'rep) t = 'req -> 'rep Lwt.t [@@deriving sexp]

  val id : ('a, 'a) t
  val const : 'rep -> (_, 'rep) t
end

(** A filter is a higher order function that transforms a service into
    another service. *)
module Filter : sig
  type ('req, 'rep, 'req', 'rep') t =
    ('req, 'rep) Service.t -> ('req', 'rep') Service.t
  [@@deriving sexp]

  (** A filter is simple when it preserves the type of a service *)
  type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t
  [@@deriving sexp]

  val id : ('req, 'rep) simple

  val (>>>) : ('q1, 'p1, 'q2, 'p2) t
    -> ('q2, 'p2, 'q3, 'p3) t
    -> ('q1, 'p1, 'q3, 'p3) t

  val apply_all : ('req, 'rep) simple list
    -> ('req, 'rep) Service.t
    -> ('req, 'rep) Service.t
end

module Request : sig
  type t = {
    request: Cohttp.Request.t;
    body:    Cohttp_lwt.Body.t;
    env:     Hmap0.t;
  } [@@deriving fields, sexp_of]

  val create : ?body:Cohttp_lwt.Body.t
    -> ?env:Hmap0.t
    -> Cohttp.Request.t -> t
  (** Convenience accessors on the request field  *)
  val uri : t -> Uri.t
  val meth : t -> Cohttp.Code.meth
  val headers : t -> Cohttp.Header.t
end

module Response : sig
  type t = {
    code:    Cohttp.Code.status_code;
    headers: Cohttp.Header.t;
    body:    Cohttp_lwt.Body.t;
    env:     Hmap0.t
  } [@@deriving fields, sexp_of]

  val create :
    ?env: Hmap0.t ->
    ?body:Cohttp_lwt.Body.t ->
    ?headers:Cohttp.Header.t ->
    ?code:Cohttp.Code.status_code ->
    unit -> t

  val of_string_body :
    ?env: Hmap0.t ->
    ?headers:Cohttp.Header.t ->
    ?code:Cohttp.Code.status_code ->
    string -> t

  val of_response_body : Cohttp.Response.t * Cohttp_lwt.Body.t -> t
end

(** A handler is a rock specific service *)
module Handler : sig
  type t = (Request.t, Response.t) Service.t [@@deriving sexp_of]
  val default : t
  val not_found : t
end

(** Middleware is a named, simple filter, that only works on rock
    requests/response *)
module Middleware : sig
  type t [@@deriving sexp_of]

  val filter : t -> (Request.t, Response.t) Filter.simple

  val apply : t -> (Request.t, Response.t) Service.t -> Request.t -> Response.t Lwt.t

  val name : t -> string

  val create : filter:(Request.t, Response.t) Filter.simple
    -> name:string -> t
end

module App : sig
  type t [@@deriving sexp_of]

  val handler : t -> Handler.t

  val middlewares : t -> Middleware.t list

  val append_middleware : t -> Middleware.t -> t

  val create : ?middlewares:Middleware.t list -> handler:Handler.t -> t
end
