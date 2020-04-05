module Hmap0 : sig
  include Hmap.S with type 'a Key.info = string * ('a -> Sexplib0.Sexp.t)

  val sexp_of_t : t -> Sexplib0.Sexp.t

  val pp_hum : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]

  val find_exn : 'a key -> t -> 'a
end

module Body : sig
  type content =
    private
    [ `Empty
    | `String of string
    | `Bigstring of Bigstringaf.t
    | (* TODO: switch to a iovec based stream *)
      `Stream of string Lwt_stream.t ]

  type t = private {length: Int64.t option; content: content}

  val sexp_of_t : t -> Sexplib0.Sexp.t

  val pp_hum : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]

  val drain : t -> unit Lwt.t

  val to_string : t -> string Lwt.t

  val to_stream : t -> string Lwt_stream.t

  val of_string : string -> t

  val of_bigstring : Bigstringaf.t -> t

  val empty : t

  val of_stream : ?length:Int64.t -> string Lwt_stream.t -> t
end

module Rock : sig
  (** A tiny clone of ruby's Rack protocol in OCaml. Which is slightly more
      general and inspired by Finagle. It's not imperative to have this to for
      such a tiny framework but it makes extensions a lot more straightforward *)

  (** A service is simply a function that returns its result asynchronously *)
  module Service : sig
    type ('req, 'rep) t = 'req -> 'rep Lwt.t
  end

  (** A filter is a higher order function that transforms a service into another
      service. *)
  module Filter : sig
    type ('req, 'rep, 'req', 'rep') t =
      ('req, 'rep) Service.t -> ('req', 'rep') Service.t

    (** A filter is simple when it preserves the type of a service *)
    type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t

    val ( >>> ) :
      ('q1, 'p1, 'q2, 'p2) t -> ('q2, 'p2, 'q3, 'p3) t -> ('q1, 'p1, 'q3, 'p3) t

    val apply_all :
         ('req, 'rep) simple list
      -> ('req, 'rep) Service.t
      -> ('req, 'rep) Service.t
  end

  module Request : sig
    type t = private
      { version: Httpaf.Version.t
      ; target: string
      ; headers: Httpaf.Headers.t
      ; meth: Httpaf.Method.standard
      ; body: Body.t
      ; env: Hmap0.t }

    val make :
         ?version:Httpaf.Version.t
      -> ?body:Body.t
      -> ?env:Hmap0.t
      -> ?headers:Httpaf.Headers.t
      -> string
      -> Httpaf.Method.standard
      -> unit
      -> t

    val sexp_of_t : t -> Sexplib0.Sexp.t

    val pp_hum : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]
  end

  module Response : sig
    type t = private
      { version: Httpaf.Version.t
      ; status: Httpaf.Status.t
      ; reason: string option
      ; headers: Httpaf.Headers.t
      ; body: Body.t
      ; env: Hmap0.t }

    val make :
         ?version:Httpaf.Version.t
      -> ?status:Httpaf.Status.t
      -> ?reason:string
      -> ?headers:Httpaf.Headers.t
      -> ?body:Body.t
      -> ?env:Hmap0.t
      -> unit
      -> t

    val sexp_of_t : t -> Sexplib0.Sexp.t

    val pp_hum : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]
  end

  (** A handler is a rock specific service *)
  module Handler : sig
    type t = (Request.t, Response.t) Service.t
  end

  (** Middleware is a named, simple filter, that only works on rock
      requests/response *)
  module Middleware : sig
    type t = private
      {filter: (Request.t, Response.t) Filter.simple; name: string}

    val create :
      filter:(Request.t, Response.t) Filter.simple -> name:string -> t
  end

  module App : sig
    type t = private {middlewares: Middleware.t list; handler: Handler.t}

    val append_middleware : t -> Middleware.t -> t

    val create : ?middlewares:Middleware.t list -> handler:Handler.t -> t
  end
end

module Route : sig
  type t

  type matches = {params: (string * string) list; splat: string list}

  val of_string : string -> t

  val to_string : t -> string
end

module Router : sig
  type 'action t

  val create : unit -> _ t

  val add :
    'a t -> route:Route.t -> meth:Httpaf.Method.standard -> action:'a -> unit

  val param : Rock.Request.t -> string -> string

  val splat : Rock.Request.t -> string list

  val m : Rock.Handler.t t -> Rock.Middleware.t
end

module Server_connection : sig
  type error_handler =
       Httpaf.Headers.t
    -> Httpaf.Server_connection.error
    -> (Httpaf.Headers.t * Body.t) Lwt.t

  val run :
       (   request_handler:Httpaf.Server_connection.request_handler
        -> error_handler:Httpaf.Server_connection.error_handler
        -> 'a Lwt.t)
    -> ?error_handler:error_handler
    -> Rock.App.t
    -> 'a Lwt.t
end
