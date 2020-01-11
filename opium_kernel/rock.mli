(** A tiny clone of ruby's Rack protocol in OCaml. Which is slightly more
    general and inspired by Finagle. It's not imperative to have this to for
    such a tiny framework but it makes extensions a lot more straightforward *)

module Body = Misc.Body

(** A service is simply a function that returns its result
    asynchronously *)
module Service : sig
  type ('req, 'rep) t = 'req -> 'rep Lwt.t

  val id : ('a, 'a) t

  val const : 'rep -> (_, 'rep) t
end

(** A filter is a higher order function that transforms a service into another
    service. *)
module Filter : sig
  type ('req, 'rep, 'req', 'rep') t =
    ('req, 'rep) Service.t -> ('req', 'rep') Service.t

  type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t

  val id : ('req, 'rep) simple

  val ( >>> ) :
    ('q1, 'p1, 'q2, 'p2) t -> ('q2, 'p2, 'q3, 'p3) t -> ('q1, 'p1, 'q3, 'p3) t

  val apply_all :
    ('req, 'rep) simple list -> ('req, 'rep) Service.t -> ('req, 'rep) Service.t
end

module Request : sig
  type t = {
    request: Httpaf.Request.t;
    uri:     Uri.t;
    body:    Body.t;
    env:     Hmap0.t;
  } [@@deriving fields, sexp_of]

  val create : ?body:Body.t
    -> ?env:Hmap0.t
    -> Httpaf.Request.t -> t
  (** Convenience accessors on the request field  *)
  val uri : t -> Uri.t
  val meth : t -> Httpaf.Method.t
  val headers : t -> Httpaf.Headers.t
end

module Response : sig
  type t = {
    code:    Httpaf.Status.t;
    headers: Httpaf.Headers.t;
    body:    Body.t;
    env:     Hmap0.t
  } [@@deriving fields]

  val create :
    ?env: Hmap0.t ->
    ?body: Body.t ->
    ?headers: Httpaf.Headers.t ->
    ?code: Httpaf.Status.t ->
    unit -> t

  val of_string_body :
    ?env: Hmap0.t ->
    ?headers: Httpaf.Headers.t ->
    ?code: Httpaf.Status.t ->
    string -> t

  val of_bigstring_body :
    ?env: Hmap0.t ->
    ?headers: Httpaf.Headers.t ->
    ?code: Httpaf.Status.t ->
    Bigstringaf.t -> t

  val of_response_body : Httpaf.Response.t * Body.t -> t
end

(** A handler is a rock specific service *)
module Handler : sig
  type t = (Request.t, Response.t) Service.t
  val default : t

  val not_found : t
end

(** Middleware is a named, simple filter, that only works on rock
    requests/response *)
module Middleware : sig
  type t

  val filter : t -> (Request.t, Response.t) Filter.simple

  val apply :
    t -> (Request.t, Response.t) Service.t -> Request.t -> Response.t Lwt.t

  val name : t -> string

  val create : filter:(Request.t, Response.t) Filter.simple -> name:string -> t
end

module App : sig
  type t

  val handler : t -> Handler.t

  val middlewares : t -> Middleware.t list

  val append_middleware : t -> Middleware.t -> t

  val create : ?middlewares:Middleware.t list -> handler:Handler.t -> t
end
