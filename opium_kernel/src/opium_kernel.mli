(** Opium_kernel

    [Opium_kernel] is a Sinatra like web toolkit for OCaml, based on Httpaf and Lwt. *)

module Hmap0 : sig
  include Hmap.S with type 'a Key.info = string * ('a -> Sexplib0.Sexp.t)

  val sexp_of_t : t -> Sexplib0.Sexp.t
  val pp_hum : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]
  val find_exn : 'a key -> t -> 'a
end

(** A tiny clone of ruby's Rack protocol in OCaml. Which is slightly more general and
    inspired by Finagle. It's not imperative to have this to for such a tiny framework but
    it makes extensions a lot more straightforward *)
module Rock : sig
  module Headers : module type of Headers
  module Method : module type of Method
  module Version : module type of Version
  module Status : module type of Status

  module Body : sig
    type content =
      private
      [ `Empty
      | `String of string
      | `Bigstring of Bigstringaf.t
      | `Stream of string Lwt_stream.t
      ]

    (** [t] represents an HTTP message body. *)
    type t = private
      { length : Int64.t option
      ; content : content
      }

    (** [drain t] will repeatedly read values from the body stream and discard them. *)
    val drain : t -> unit Lwt.t

    (** [to_string t] returns a promise that will eventually be filled with a string
        representation of the body. *)
    val to_string : t -> string Lwt.t

    (** [to_stream t] converts the body to a [string Lwt_stream.t]. *)
    val to_stream : t -> string Lwt_stream.t

    (** [of_string] creates a fixed length body from a string. *)
    val of_string : string -> t

    (** [of_bigstring] creates a fixed length body from a bigstring. *)
    val of_bigstring : Bigstringaf.t -> t

    (** [empty] represents a body of size 0L. *)
    val empty : t

    (** [of_stream] takes a [string Lwt_stream.t] and creates a HTTP body from it. *)
    val of_stream : ?length:Int64.t -> string Lwt_stream.t -> t

    (** [copy t] creates a new instance of the body [t]. If the body is a stream, it is be
        duplicated safely and the initial stream will remain untouched. *)
    val copy : t -> t

    (** [sexp_of_t t] converts the body [t] to an s-expression *)
    val sexp_of_t : t -> Sexplib0.Sexp.t

    (** [pp_hum] formats the body [t] as an s-expression *)
    val pp_hum : Format.formatter -> t -> unit
      [@@ocaml.toplevel_printer]
  end

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

  module Request : sig
    type t =
      { version : Version.t
      ; target : string
      ; headers : Headers.t
      ; meth : Method.t
      ; body : Body.t
      ; env : Hmap0.t
      }

    (** {3 Constructor} *)

    (** [make ?version ?body ?env ?headers target method] creates a new request from the
        given values. *)
    val make
      :  ?version:Version.t
      -> ?body:Body.t
      -> ?env:Hmap0.t
      -> ?headers:Headers.t
      -> string
      -> Method.t
      -> t

    (** [of_string ?version ?headers ?env ~body target method] creates a new request from
        the given values and a string body.

        The content type of the request will be set to [text/plain] and the body will
        contain the string [body].

        {4 Example}

        The request initialized with:

        {[ Rock.Request.of_string ~body:"Hello World" "/target" `POST () ]}

        Will be represented as:

        {%html: <pre>
POST /target HTTP/HTTP/1.1
Content-Type: text/plain

Hello World </pre>%} *)
    val of_string
      :  ?version:Version.t
      -> ?headers:Headers.t
      -> ?env:Hmap0.t
      -> body:string
      -> string
      -> Method.t
      -> t

    (** [of_json ?version ?headers ?env ~body target method] creates a new request from
        the given values and a json body.

        The content type of the request will be set to [application/json] and the body
        will contain the json payload [body].

        {4 Example}

        The request initialized with:

        {[
          Rock.Request.of_json
            ~body:(`Assoc [ "Hello", `String "World" ])
            "/target"
            `POST
            ()
        ]}

        Will be represented as:

        {%html: <pre>
POST /target HTTP/HTTP/1.1
Content-Type: application/json

{"Hello":"World"} </pre> %} *)
    val of_json
      :  ?version:Version.t
      -> ?headers:Headers.t
      -> ?env:Hmap0.t
      -> body:Yojson.Safe.t
      -> string
      -> Method.t
      -> t

    (** [of_urlencoded ?version ?headers ?env ~body target method] creates a new request
        from the given values and a urlencoded body.

        The content type of the request will be set to [application/x-www-form-urlencoded]
        and the body will contain the key value pairs [body] formatted in the urlencoded
        format.

        {4 Example}

        The request initialized with:

        {[ Rock.Request.of_urlencoded ~body:[ "key", [ "value" ] ] "/target" `POST () ]}

        Will be represented as:

        {%html: <pre>
POST /target HTTP/HTTP/1.1
Content-Type: application/x-www-form-urlencoded

key=value </pre> %} *)
    val of_urlencoded
      :  ?version:Version.t
      -> ?headers:Headers.t
      -> ?env:Hmap0.t
      -> body:(string * string list) list
      -> string
      -> Method.t
      -> t

    (** {3 Getters and Setters} *)

    (** [header key t] returns the value of the header with key [key] in the request [t].

        If multiple headers have the key [key], only the value of the first header will be
        returned.

        If you want to return all the values if multiple headers are found, you can use
        {!headers}. *)
    val header : string -> t -> string option

    (** [headers] returns the values of all headers with the key [key] in the request [t].

        If you want to return the value of only the first header with the key [key], you
        can use {!header}. *)
    val headers : string -> t -> string list

    (** [add_header (key, value) t] adds a header with the key [key] and the value [value]
        to the request [t].

        If a header with the same key is already persent, a new header is appended to the
        list of headers regardless. If you want to add the header only if an header with
        the same key could not be found, you can use {!add_header_unless_exists}.

        See also {!add_headers} to add multiple headers. *)
    val add_header : string * string -> t -> t

    (** [add_header_unless_exists (key, value) t] adds a header with the key [key] and the
        value [value] to the request [t] if an header with the same key does not already
        exist.

        If a header with the same key already exist, the request remains unmodified. If
        you want to add the header regardless of whether the header is already present,
        you can use {!add_header}.

        See also {!add_headers_unless_exists} to add multiple headers. *)
    val add_header_unless_exists : string * string -> t -> t

    (** [add_headers headers request] adds the headers [headers] to the request [t].

        The headers are added regardless of whether a header with the same key is already
        present. If you want to add the header only if an header with the same key could
        not be found, you can use {!add_headers_unless_exists}.

        See also {!add_header} to add a single header. *)
    val add_headers : (string * string) list -> t -> t

    (** [add_headers_unless_exists headers request] adds the headers [headers] to the
        request [t] if an header with the same key does not already exist.

        If a header with the same key already exist, the header is will not be added to
        the request. If you want to add the header regardless of whether the header is
        already present, you can use {!add_headers}.

        See also {!add_header_unless_exists} to add a single header. *)
    val add_headers_unless_exists : (string * string) list -> t -> t

    (** [urlencoded key t] returns the value associated to [key] in the urlencoded request
        [t].

        Since the request can be a stream, the return value is a promise.

        If the key could not be found or if the request could not be parsed as urlencoded,
        an error is returned. *)
    val urlencoded : string -> t -> (string, string) Lwt_result.t

    (** [urlencoded2 key1 key2 t] returns the values respectively associated to [key1] and
        [key2] in the urlencoded request [t].

        Since the request can be a stream, the return value is a promise.

        If one of the key could not be found or if the request could not be parsed as
        urlencoded, an error is returned. *)
    val urlencoded2 : string -> string -> t -> (string * string, string) Lwt_result.t

    (** [urlencoded2 key1 key2 key3 t] returns the values respectively associated to
        [key1], [key2] and [key3] in the urlencoded request [t].

        Since the request can be a stream, the return value is a promise.

        If one of the key could not be found or if the request could not be parsed as
        urlencoded, an error is returned. *)
    val urlencoded3
      :  string
      -> string
      -> string
      -> t
      -> (string * string * string, string) Lwt_result.t

    (** [content_type request] returns the value of the header [Content-Type] of the
        request [request]. *)
    val content_type : t -> string option

    (** [set_content_type content_type request] returns a copy of [request] with the value
        of the header [Content-Type] set to [content_type]. *)
    val set_content_type : string -> t -> t

    (** {3 Utilities} *)

    (** [sexp_of_t t] converts the request [t] to an s-expression *)
    val sexp_of_t : t -> Sexplib0.Sexp.t

    (** [pp_hum] formats the request [t] as an s-expression *)
    val pp_hum : Format.formatter -> t -> unit
      [@@ocaml.toplevel_printer]

    (** [pp_http] formats the request [t] as a standard HTTP request *)
    val pp_http : Format.formatter -> t -> unit
      [@@ocaml.toplevel_printer]
  end

  module Response : sig
    type t =
      { version : Version.t
      ; status : Status.t
      ; reason : string option
      ; headers : Headers.t
      ; body : Body.t
      ; env : Hmap0.t
      }

    (** {3 Constructors} *)

    (** [make ?version ?status ?reason ?headers ?body ?env ()] creates a new response from
        the given values. *)
    val make
      :  ?version:Version.t
      -> ?status:Status.t
      -> ?reason:string
      -> ?headers:Headers.t
      -> ?body:Body.t
      -> ?env:Hmap0.t
      -> unit
      -> t

    (** [redirect_to ?status ?version ?reason ?headers ?env target] creates a new Redirect
        response from the given values.

        The response will contain the header [Location] with the value [target] and a
        Redirect HTTP status (a Redirect HTTP status starts with 3).

        By default, the HTTP status is [302 Found]. *)
    val redirect_to
      :  ?status:Rock.Status.redirection
      -> ?version:Httpaf.Version.t
      -> ?reason:string
      -> ?headers:Httpaf.Headers.t
      -> ?env:Hmap0.t
      -> string
      -> t

    (** [of_string ?status ?version ?reason ?headers ?env body] creates a new request from
        the given values and a string body.

        The content type of the request will be set to [text/plain] and the body will
        contain the string [body].

        {4 Example}

        The request initialized with:

        {[ Rock.Response.of_string "Hello World" ]}

        Will be represented as:

        {%html: <pre>
HTTP/HTTP/1.1 200 
Content-Type: text/plain

Hello World </pre>%} *)
    val of_string
      :  ?version:Version.t
      -> ?status:Status.t
      -> ?reason:string
      -> ?headers:Headers.t
      -> ?env:Hmap0.t
      -> string
      -> t

    (** [of_json ?status ?version ?reason ?headers ?env payload] creates a new request
        from the given values and a JSON body.

        The content type of the request will be set to [application/json] and the body
        will contain the json payload [body].

        {4 Example}

        The request initialized with:

        {[ Rock.Response.of_json (`Assoc [ "Hello", `String "World" ]) ]}

        Will be represented as:

        {%html: <pre>
HTTP/HTTP/1.1 200 
Content-Type: application/json

{"Hello":"World"} </pre> %} *)
    val of_json
      :  ?version:Version.t
      -> ?status:Status.t
      -> ?reason:string
      -> ?headers:Headers.t
      -> ?env:Hmap0.t
      -> Yojson.Safe.t
      -> t

    (** [of_html ?status ?version ?reason ?headers ?env payload] creates a new request
        from the given values and a HTML body.

        The content type of the request will be set to [text/html] and the body will
        contain the HTML payload [body].

        {4 Example}

        The request initialized with:

        {[
          Rock.Response.of_html
            "<html>\n\
             <head>\n\
            \  <title>Title</title>\n\
             </head>\n\
             <body>\n\
            \  Hello World\n\
             </body>\n\
             </html>"
        ]}

        Will be represented as:

        {%html: <pre>
HTTP/HTTP/1.1 200 
Content-Type: text/html

&lt;html&gt;
&lt;head&gt;
  &lt;title&gt;Title&lt;/title&gt;
&lt;/head&gt;
&lt;body&gt;
  Hello World
&lt;/body&gt;
&lt;/html&gt; </pre> %}

        {4 Tyxml}

        It is common to use [tyxml] to generate HTML. If that's your case, here's sample
        function to create a [t] from a [\[ `Html \] Tyxml_html.elt]:

        {[
          let response_of_tyxml ?version ?status ?reason ?headers ?env body =
            let body =
              Format.asprintf "%a" (Tyxml.Html.pp ()) body
              |> Opium_kernel.Rock.Body.of_string
            in
            Opium_kernel.Rock.Response.of_html ?version ?status ?reason ?headers ?env body
          ;;
        ]}*)
    val of_html
      :  ?version:Version.t
      -> ?status:Status.t
      -> ?reason:string
      -> ?headers:Headers.t
      -> ?env:Hmap0.t
      -> string
      -> t

    (** {3 Getters and Setters} *)

    (** [header key t] returns the value of the header with key [key] in the response [t].

        If multiple headers have the key [key], only the value of the first header will be
        returned.

        If you want to return all the values if multiple headers are found, you can use
        {!headers}. *)
    val header : string -> t -> string option

    (** [headers] returns the values of all headers with the key [key] in the response
        [t].

        If you want to return the value of only the first header with the key [key], you
        can use {!header}. *)
    val headers : string -> t -> string list

    (** [add_header (key, value) t] adds a header with the key [key] and the value [value]
        to the response [t].

        If a header with the same key is already persent, a new header is appended to the
        list of headers regardless. If you want to add the header only if an header with
        the same key could not be found, you can use {!add_header_unless_exists}.

        See also {!add_headers} to add multiple headers. *)
    val add_header : string * string -> t -> t

    (** [add_header_unless_exists (key, value) t] adds a header with the key [key] and the
        value [value] to the response [t] if an header with the same key does not already
        exist.

        If a header with the same key already exist, the response remains unmodified. If
        you want to add the header regardless of whether the header is already present,
        you can use {!add_header}.

        See also {!add_headers_unless_exists} to add multiple headers. *)
    val add_header_unless_exists : string * string -> t -> t

    (** [add_headers headers response] adds the headers [headers] to the response [t].

        The headers are added regardless of whether a header with the same key is already
        present. If you want to add the header only if an header with the same key could
        not be found, you can use {!add_headers_unless_exists}.

        See also {!add_header} to add a single header. *)
    val add_headers : (string * string) list -> t -> t

    (** [add_headers_unless_exists headers response] adds the headers [headers] to the
        response [t] if an header with the same key does not already exist.

        If a header with the same key already exist, the header is will not be added to
        the response. If you want to add the header regardless of whether the header is
        already present, you can use {!add_headers}.

        See also {!add_header_unless_exists} to add a single header. *)
    val add_headers_unless_exists : (string * string) list -> t -> t

    (** [content_type response] returns the value of the header [Content-Type] of the
        response [response]. *)
    val content_type : t -> string option

    (** [set_content_type content_type response] returns a copy of [response] with the
        value of the header [Content-Type] set to [content_type]. *)
    val set_content_type : string -> t -> t

    (** {3 Utilities} *)

    (** [sexp_of_t t] converts the response [t] to an s-expression *)
    val sexp_of_t : t -> Sexplib0.Sexp.t

    (** [pp_hum] formats the response [t] as an s-expression *)
    val pp_hum : Format.formatter -> t -> unit
      [@@ocaml.toplevel_printer]

    (** [pp_http] formats the response [t] as a standard HTTP response *)
    val pp_http : Format.formatter -> t -> unit
      [@@ocaml.toplevel_printer]
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
  val param : Rock.Request.t -> string -> string
  val splat : Rock.Request.t -> string list
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
    :  read:
         (unit
          -> (Rock.Body.t, [ Status.client_error | Status.server_error ]) Lwt_result.t)
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
    :  ?time_f:((unit -> Rock.Response.t Lwt.t) -> Mtime.span * Rock.Response.t Lwt.t)
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
         (string
          -> (Rock.Body.t, [ Status.client_error | Status.server_error ]) Lwt_result.t)
    -> ?uri_prefix:string
    -> ?headers:Headers.t
    -> ?etag_of_fname:(string -> string option)
    -> unit
    -> Rock.Middleware.t
end
