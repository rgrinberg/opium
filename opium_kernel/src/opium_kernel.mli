(** Opium_kernel

    [Opium_kernel] is a Sinatra like web toolkit for OCaml, based on Httpaf and Lwt. *)

module Request = Request
module Response = Response
module Headers = Headers
module Method = Method
module Version = Version
module Status = Status

module Body : sig
  type content

  (** [t] represents an HTTP message body. *)
  type t

  (** {1 Constructor} *)

  (** [of_string] creates a fixed length body from a string. *)
  val of_string : string -> t

  (** [of_bigstring] creates a fixed length body from a bigstring. *)
  val of_bigstring : Bigstringaf.t -> t

  (** [of_stream] takes a [string Lwt_stream.t] and creates a HTTP body from it. *)
  val of_stream : ?length:Int64.t -> string Lwt_stream.t -> t

  (** [empty] represents a body of size 0L. *)
  val empty : t

  (** [copy t] creates a new instance of the body [t]. If the body is a stream, it is be
      duplicated safely and the initial stream will remain untouched. *)
  val copy : t -> t

  (** {1 Decoders} *)

  (** [to_string t] returns a promise that will eventually be filled with a string
      representation of the body. *)
  val to_string : t -> string Lwt.t

  (** [to_stream t] converts the body to a [string Lwt_stream.t]. *)
  val to_stream : t -> string Lwt_stream.t

  (** {1 Getters and Setters} *)

  val length : t -> Int64.t option

  (** {1 Utilities} *)

  (** [drain t] will repeatedly read values from the body stream and discard them. *)
  val drain : t -> unit Lwt.t

  (** [sexp_of_t t] converts the body [t] to an s-expression *)
  val sexp_of_t : t -> Sexplib0.Sexp.t

  (** [pp] formats the body [t] as an s-expression *)
  val pp : Format.formatter -> t -> unit
    [@@ocaml.toplevel_printer]

  (** [pp_hum] formats the body [t] as an string.

      If the body content is a stream, the pretty printer will output the value
      ["<stream>"]*)
  val pp_hum : Format.formatter -> t -> unit
    [@@ocaml.toplevel_printer]
end
with type t = Body.t

(** A tiny clone of ruby's Rack protocol in OCaml. Which is slightly more general and
    inspired by Finagle. It's not imperative to have this to for such a tiny framework but
    it makes extensions a lot more straightforward *)
module Rock : sig
  (** A service is simply a function that returns its result asynchronously *)
  module Service : sig
    type ('req, 'rep) t = 'req -> 'rep Lwt.t
  end

  (** A filter is a higher order function that transforms a service into another service. *)
  module Filter : sig
    type ('req, 'rep, 'req', 'rep') t = ('req, 'rep) Service.t -> ('req', 'rep') Service.t

    (** A filter is simple when it preserves the type of a service *)
    type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t

    val ( >>> )
      :  ('q1, 'p1, 'q2, 'p2) t
      -> ('q2, 'p2, 'q3, 'p3) t
      -> ('q1, 'p1, 'q3, 'p3) t

    val apply_all
      :  ('req, 'rep) simple list
      -> ('req, 'rep) Service.t
      -> ('req, 'rep) Service.t
  end

  (** A handler is a rock specific service *)
  module Handler : sig
    type t = (Request.t, Response.t) Service.t
  end

  (** Middleware is a named, simple filter, that only works on rock requests/response *)
  module Middleware : sig
    type t = private
      { filter : (Request.t, Response.t) Filter.simple
      ; name : string
      }

    val create : filter:(Request.t, Response.t) Filter.simple -> name:string -> t
  end

  module App : sig
    type t = private
      { middlewares : Middleware.t list
      ; handler : Handler.t
      }

    val append_middleware : t -> Middleware.t -> t
    val create : ?middlewares:Middleware.t list -> handler:Handler.t -> unit -> t
  end

  (** The Halt exception can be raised to stop the interrupt the normal processing flow of
      a request.

      The exception will be handled by the main run function (in {!Server_connection.run})
      and the response will be sent to the client directly.

      This is especially useful when you want to make sure that no other middleware will
      be able to modify the response. *)
  exception Halt of Response.t

  (** Raises a Halt exception to interrupt the processing of the connection and trigger an
      early response. *)
  val halt : Response.t -> unit
end

module Route : sig
  type t

  type matches =
    { params : (string * string) list
    ; splat : string list
    }

  val sexp_of_matches : matches -> Sexplib0.Sexp.t
  val of_string : string -> t
  val to_string : t -> string
  val match_url : t -> string -> matches option
end

module Router : sig
  type 'action t

  val empty : 'action t
  val add : 'a t -> route:Route.t -> meth:Method.t -> action:'a -> 'a t
  val param : Request.t -> string -> string
  val splat : Request.t -> string list
  val m : Rock.Handler.t t -> Rock.Middleware.t
end

module Server_connection : sig
  type error_handler =
    Headers.t -> Httpaf.Server_connection.error -> (Headers.t * Body.t) Lwt.t

  val run
    :  (request_handler:Httpaf.Server_connection.request_handler
        -> error_handler:Httpaf.Server_connection.error_handler
        -> 'a Lwt.t)
    -> ?error_handler:error_handler
    -> Rock.App.t
    -> 'a Lwt.t
end

module Static : sig
  val serve
    :  read:(unit -> (Body.t, [ Status.client_error | Status.server_error ]) Lwt_result.t)
    -> ?mime_type:string
    -> ?etag_of_fname:(string -> string option)
    -> ?headers:Headers.t
    -> string
    -> Rock.Handler.t
end

module Middleware : sig
  val router : Rock.Handler.t Router.t -> Rock.Middleware.t
  val debugger : unit -> Rock.Middleware.t

  val logger
    :  ?time_f:((unit -> Response.t Lwt.t) -> Mtime.span * Response.t Lwt.t)
    -> unit
    -> Rock.Middleware.t

  val allow_cors
    :  ?origins:string list
    -> ?credentials:bool
    -> ?max_age:int
    -> ?headers:string list
    -> ?expose:string list
    -> ?methods:Method.t list
    -> ?send_preflight_response:bool
    -> unit
    -> Rock.Middleware.t

  val static
    :  read:
         (string -> (Body.t, [ Status.client_error | Status.server_error ]) Lwt_result.t)
    -> ?uri_prefix:string
    -> ?headers:Headers.t
    -> ?etag_of_fname:(string -> string option)
    -> unit
    -> Rock.Middleware.t
end
