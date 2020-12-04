module Context = Context
module Headers = Headers
module Cookie = Cookie
module Method = Method
module Version = Version
module Status = Status
module Body = Body
module Request = Request
module Response = Response
module App = App
module Route = Route
module Auth = Auth

module Router : sig
  type 'action t

  val empty : 'action t
  val add : 'a t -> route:Route.t -> meth:Method.t -> action:'a -> 'a t
  val param : Request.t -> string -> string
  val splat : Request.t -> string list
end

(** Collection of handlers commonly used to build Opium applications *)
module Handler : sig
  (** [serve ?mime_type ?etag ?headers read] returns a handler that will serve the result
      of [read ()].

      It is typically used to serve static file by providing a read function, either
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

  (** [debugger] creates a middleware that that catches any error that occurs when
      processing the request and pretty prints the error in an an HTML page.

      It should only be used during development: you probably don't want to serve a detail
      of the error to your users in production. *)
  val debugger : Rock.Middleware.t

  (** {3 [logger]} *)

  (** [logger] creates a middleware that logs the requests and their response.

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
  val logger : Rock.Middleware.t

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

  (** {3 [static_unix]} *)

  (** [static_unix ~local_path ?uri_prefix ?headers ?etag_of_fname ()] creates a
      middleware that is used to serve static content from a local filesystem.

      The behaviour of the middleware is the same as {!static}, since the latter is used
      with a [read] function that reads from the local filesystem. *)
  val static_unix
    :  local_path:string
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
      respond with a [`Method_not_allowed] status ([HTTP 405]) if the method is not
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

  (** {3 [basic_auth]} *)

  (** [basic_auth ?unauthorized_handler ~key ~real ~auth_callback] creates a middleware
      that proctects handlers with an authentication mechanism.

      The requests have to provide an [Authorization] header with the format
      [Basic = <credentials>]. [auth_callback] is called with the username and password
      extracted from the credentials. If the user does not contain a valid [Authorization]
      header, or if the [auth_callback] returns [None], the request is redirected to
      [unauthorized_handler] (by default, returns a "Forbidden access" message). *)
  val basic_auth
    :  ?unauthorized_handler:Rock.Handler.t
    -> key:'a Context.key
    -> realm:string
    -> auth_callback:(username:string -> password:string -> 'a option Lwt.t)
    -> unit
    -> Rock.Middleware.t
end
