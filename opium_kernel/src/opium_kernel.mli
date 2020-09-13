(** Opium_kernel

    [Opium_kernel] is a Sinatra like web toolkit for OCaml, based on Httpaf and Lwt. *)

module Hmap0 = Hmap0
module Request = Request
module Response = Response
module Headers = Headers
module Method = Method
module Version = Version
module Status = Status
module Cookie = Cookie

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

(** Module that offers convenience functions to serve static content *)
module Static : sig
  (** [serve ?mime_type ?etag ?headers read] returns a handler that will serve the result
      of [read ()].

      It is typically use to serve static file by providing a read function, either
      reading from the local filesystem, or from a remote one such as Amazon S3.

      The response will contain an ETag header and a the HTTP code [304] will be returned
      if the computed ETag matches the one specified in the request. *)
  val serve
    :  ?mime_type:string
    -> ?etag:string
    -> ?headers:Headers.t
    -> (unit -> (Body.t, [ Status.client_error | Status.server_error ]) Lwt_result.t)
    -> Rock.Handler.t
end

(** Collection of middlewares commonly used to build Opium applications. *)
module Middleware : sig
  (** {3 [router]} *)

  (** [router router] creates a middleware that route the request to an handler depending
      on the URI of the request.

      The middleware [router] takes a instance of [Router.t]. It will call the handler if
      a match is found in the given list of endpoint, and will fallback to the default
      handler otherwise.

      The routes can use pattern patching to match multiple endpoints.

      A URI segment preceded with a colon ":" will match any string and will insert the
      value of the segment in the environment of the request.

      For instance, the middleware defined with:

      {[
        let router =
          Router.add
            Router.empty
            ~action:Handler.hello_world
            ~meth:`GET
            ~route:"/hello/:name"
        ;;

        let middleware = Middleware.router router
      ]}

      will match any URI that matches "/hello/" followed by a string. This value of the
      last segment will be inserted in the request environment with the key "name", and
      the request will be handled by handler defined in [Handler.hello_world].

      Another way to use pattern matching is to use the wildchar "*" character. The URI
      segment using "*" will match any URI segment, but will not insert the value of the
      segment in the request enviroment.

      For instance, the middleware defined with:

      {[
        let router =
          Router.add Router.empty ~action:Handler.hello_world ~meth:`GET ~route:"/*/hello"
        ;;

        let middleware = Middleware.router router
      ]}

      will redirect any URI containing two segments with the last segment containing
      "hello" to the handler defined in [Handler.hello_world]. *)
  val router : Rock.Handler.t Router.t -> Rock.Middleware.t

  (** {3 [debugger]} *)

  (** [debugger ()] creates a middleware that that catches any error that occurs when
      processing the request and pretty prints the error in an an HTML page.

      It should only be used during development: you probably don't want to serve a detail
      of the error to your users in production. *)
  val debugger : unit -> Rock.Middleware.t

  (** {3 [logger]} *)

  (** [logger ?time_f ()] creates a middleware that logs the requests and their response.

      The request's target URL and the HTTP method are logged with the "info" verbosity.
      Once the request has been processed successfully, the response's HTTP code is logged
      with the "info" verbosity.

      If the body of the request or the response are a string (as opposed to a stream),
      their content is logged with the "debug" verbosity.

      If an error occurs while processing the request, the error is logged with an "error"
      verbosity.

      Note that this middleware is best used as the first middleware of the pipeline
      because any previous middleware might change the request / response after [Logger]
      has been applied. *)
  val logger
    :  ?time_f:((unit -> Response.t Lwt.t) -> Mtime.span * Response.t Lwt.t)
    -> unit
    -> Rock.Middleware.t

  (** {3 [allow_cors]} *)

  (** [allow_cors ?origins ?credentials ?max_age ?headers ?expose ?methods
      ?send_preflight_response ()] creates a middleware that adds Cross-Origin Resource
      Sharing (CORS) header to the responses. *)
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

  (** {3 [static]} *)

  (** [static ~read ?uri_prefix ?headers ?etag_of_fname ()] creates a middleware that is
      used to serve static content.

      It is Unix-independent, you can provide your own read function that could read from
      in-memory content, or read a Unix filesystem, or even connect to a third party
      service such as S3.

      The responses will contain a [Content-type] header that is auto-detected based on
      the file extension using the {!Magic_mime.lookup} function. Additional headers can
      be provided through [headers].

      It supports the HTTP entity tag (ETag) protocol to provide web cache validation. If
      [etag_of_fname] is provided, the response will contain an [ETag] header. If the
      request contains an [If-None-Match] header with an [ETag] equal to that generated by
      [etag_of_fname], this middleware will respond with [304 Not Modified]. *)
  val static
    :  read:
         (string -> (Body.t, [ Status.client_error | Status.server_error ]) Lwt_result.t)
    -> ?uri_prefix:string
    -> ?headers:Headers.t
    -> ?etag_of_fname:(string -> string option)
    -> unit
    -> Rock.Middleware.t

  (** {3 [content_length]} *)

  (** [content_length] is middleware that overrides the request's [POST] method with the
      method defined in the [_method] request parameter.

      The [POST] method can be overridden by the following HTTP methods:

      - [PUT]
      - [PATCH]
      - [DELETE] *)
  val content_length : Rock.Middleware.t

  (** {3 [method_override]} *)

  (** [method_override] is a middleware that replaces the HTTP method with the one found
      in the [_method] field of [application/x-www-form-urlencoded] encoded [POST]
      requests.

      Requests that are not [application/x-www-form-urlencoded] encoded or with method
      different than [POST] remain untouched.

      This is especially useful when sending requests from HTML form, because they only
      support the [GET] and [POST] method. *)
  val method_override : Rock.Middleware.t

  (** {3 [method_required]} *)

  (** [method_required] creates a middleware that filters the requests by method and
      respond with a [`Method_not_allowed] status ([HTTP 304]) if the method is not
      allowed. *)
  val method_required : ?allowed_methods:Method.t list -> unit -> Rock.Middleware.t

  (** {3 [etag]} *)

  (** [etag] is a middleware that adds an ETag header to responses and respond with the
      HTTP code [304] when the computed ETag matches the one specified in the request. *)
  val etag : Rock.Middleware.t

  (** {3 [head]} *)

  (** [head] is a middleware that add supports for [HEAD] request for handlers that
      receive [GET] requests.

      It works by replacing the [HEAD] method by the [GET] method before sending the
      request to the handler, and removes the body of the response before sending it to
      the client. *)
  val head : Rock.Middleware.t
end
