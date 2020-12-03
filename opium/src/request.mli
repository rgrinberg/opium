(** Module to create and work with HTTP requests.

    It offers convenience functions to read headers, decode a request body or URI.

    The requests are most likely provided to you by Opium when you are writing your
    application, but this module contains all the constructors and setters that you need
    to initialize new requests.

    {3 Working with stream bodies}

    All the functions in this module will clone the stream before reading from it, so you
    can process the body multiple times if needed. Just make sure that you didn't drain
    the body before calling a function that reads from it.

    Functions from other modules may drain the body stream. You can use {!Body.copy} to
    copy the body yourself. *)

type t = Rock.Request.t =
  { version : Version.t
  ; target : string
  ; headers : Headers.t
  ; meth : Method.t
  ; body : Body.t
  ; env : Context.t
  }

(** {1 Constructors} *)

(** {3 [make]} *)

(** [make ?version ?body ?env ?headers target method] creates a new request from the given
    values.

    By default, the HTTP version will be set to 1.1 and the request will not contain any
    header or body. *)
val make
  :  ?version:Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Headers.t
  -> string
  -> Method.t
  -> t

(** {3 [get]} *)

(** [get ?version ?body ?env ?headers target] creates a new [GET] request from the given
    values.

    By default, the HTTP version will be set to 1.1 and the request will not contain any
    header or body. *)
val get
  :  ?version:Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Headers.t
  -> string
  -> t

(** {3 [post]} *)

(** [post ?version ?body ?env ?headers target] creates a new [POST] request from the given
    values.

    By default, the HTTP version will be set to 1.1 and the request will not contain any
    header or body. *)
val post
  :  ?version:Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Headers.t
  -> string
  -> t

(** {3 [put]} *)

(** [put ?version ?body ?env ?headers target] creates a new [PUT] request from the given
    values.

    By default, the HTTP version will be set to 1.1 and the request will not contain any
    header or body. *)
val put
  :  ?version:Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Headers.t
  -> string
  -> t

(** {3 [delete]} *)

(** [delete ?version ?body ?env ?headers target] creates a new [DELETE] request from the
    given values.

    By default, the HTTP version will be set to 1.1 and the request will not contain any
    header or body. *)
val delete
  :  ?version:Version.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> ?headers:Headers.t
  -> string
  -> t

(** {3 [of_plain_text]} *)

(** [of_plain_text ?version ?headers ?env ~body target method] creates a new request from
    the given values and a string body.

    The content type of the request will be set to [text/plain] and the body will contain
    the string [body].

    {3 Example}

    The request initialized with:

    {[ Request.of_plain_text ~body:"Hello World" "/target" `POST ]}

    Will be represented as:

    {%html: <pre>
POST /target HTTP/HTTP/1.1
Content-Type: text/plain

Hello World </pre>%} *)
val of_plain_text
  :  ?version:Version.t
  -> ?headers:Headers.t
  -> ?env:Context.t
  -> body:string
  -> string
  -> Method.t
  -> t

(** {3 [of_json]} *)

(** [of_json ?version ?headers ?env ~body target method] creates a new request from the
    given values and a json body.

    The content type of the request will be set to [application/json] and the body will
    contain the json payload [body].

    {3 Example}

    The request initialized with:

    {[ Request.of_json ~body:(`Assoc [ "Hello", `String "World" ]) "/target" `POST ]}

    Will be represented as:

    {%html: <pre>
POST /target HTTP/HTTP/1.1
Content-Type: application/json

{"Hello":"World"} </pre> %} *)
val of_json
  :  ?version:Version.t
  -> ?headers:Headers.t
  -> ?env:Context.t
  -> body:Yojson.Safe.t
  -> string
  -> Method.t
  -> t

(** {3 [of_urlencoded]} *)

(** [of_urlencoded ?version ?headers ?env ~body target method] creates a new request from
    the given values and a urlencoded body.

    The content type of the request will be set to [application/x-www-form-urlencoded] and
    the body will contain the key value pairs [body] formatted in the urlencoded format.

    {3 Example}

    The request initialized with:

    {[ Request.of_urlencoded ~body:[ "key", [ "value" ] ] "/target" `POST ]}

    Will be represented as:

    {%html: <pre>
POST /target HTTP/HTTP/1.1
Content-Type: application/x-www-form-urlencoded

key=value </pre> %} *)
val of_urlencoded
  :  ?version:Version.t
  -> ?headers:Headers.t
  -> ?env:Context.t
  -> body:(string * string list) list
  -> string
  -> Method.t
  -> t

(** {1 Decoders} *)

(** {3 [to_plain_text]} *)

(** [to_plain_text t] parses the body of the request [t] as a string.

    {3 Example}

    {[
      let request = Request.of_plain_text "Hello world!"
      let body = Request.to_json request
    ]}

    [body] will be:

    {[ "Hello world!" ]} *)
val to_plain_text : t -> string Lwt.t

(** {3 [to_json]} *)

(** [to_json t] parses the body of the request [t] as a JSON structure.

    If the body of the request cannot be parsed as a JSON structure, [None] is returned.
    Use {!to_json_exn} to raise an exception instead.

    {3 Example}

    {[
      let request = Request.of_json (`Assoc [ "Hello", `String "World" ])
      let body = Request.to_json request
    ]}

    [body] will be:

    {[ `Assoc [ "Hello", `String "World" ] ]} *)
val to_json : t -> Yojson.Safe.t option Lwt.t

(** {3 [to_json_exn]} *)

(** [to_json_exn t] parses the body of the request [t] as a JSON structure.

    If the body of the request cannot be parsed as a JSON structure, an [Invalid_argument]
    exception is raised. Use {!to_json} to return an option instead. *)
val to_json_exn : t -> Yojson.Safe.t Lwt.t

(** {3 [to_urlencoded]} *)

(** [to_urlencoded t] parses the body of the request [t] from a urlencoded format to a
    list of key-values pairs.

    This function exist to offer a simple way to get all of the key-values pairs, but most
    of the time, you'll probably only want the value of a key given. If you don't need the
    entire list of values, it is recommended to use {!urlencoded} instead.

    If the body of the request cannot be parsed as a urlencoded string, an empty list is
    returned.

    {3 Example}

    {[
      let request =
        Request.of_urlencoded
          ~body:[ "username", [ "admin" ]; "password", [ "password" ] ]
          "/"
          `POST
      ;;

      let values = Request.to_urlencoded request
    ]}

    [values] will be:

    {[ [ "username", [ "admin" ]; "password", [ "password" ] ] ]} *)
val to_urlencoded : t -> (string * string list) list Lwt.t

(** {3 [to_multipart_form_data]} *)

(** [to_multipart_form_data ?callback t] parses the body of the request [t] from a
    [multipart/form-data] format to a list of key-values pairs.

    The request has to to contain a [Content-Type] header with a value
    [multipart/form-data] and the HTTP method has to be [POST], otherwise the request will
    not be parsed an [None] will be returned. See {!to_multipart_form_data_exn} to raise
    an exception instead.

    If the body of the request cannot be parsed as a [multipart/form-data] string, an
    empty list is returned.

    When provided, the callback is a function of type
    [val _ : ~filename:string ~name:string string -> Lwt.unit] that is called for each
    part of the body. *)
val to_multipart_form_data
  :  ?callback:(name:string -> filename:string -> string -> unit Lwt.t)
  -> t
  -> (string * string) list option Lwt.t

(** {3 [to_multipart_form_data_exn]} *)

(** [to_multipart_form_data_exn ?callback t] parses the body of the request [t] from a
    [multipart/form-data] format to a list of key-values pairs.

    The request has to to contain a [Content-Type] header with a value
    [multipart/form-data] and the HTTP method has to be [POST], otherwise the request will
    not be parsed and an [Invalid_argument] exception will be raised. See
    {!to_multipart_form_data} to return an option instead.

    If the body of the request cannot be parsed as a [multipart/form-data] string, an
    empty list is returned.

    When provided, the callback is a function of type
    [val _ : ~filename:string ~name:string string -> Lwt.unit] that is called for each
    part of the body. *)
val to_multipart_form_data_exn
  :  ?callback:(name:string -> filename:string -> string -> unit Lwt.t)
  -> t
  -> (string * string) list Lwt.t

(** {1 Getters and Setters} *)

(** {2 General Headers} *)

(** {3 [header]} *)

(** [header key t] returns the value of the header with key [key] in the request [t].

    If multiple headers have the key [key], only the value of the first header will be
    returned.

    If you want to return all the values if multiple headers are found, you can use
    {!headers}. *)
val header : string -> t -> string option

(** {3 [headers]} *)

(** [headers] returns the values of all headers with the key [key] in the request [t].

    If you want to return the value of only the first header with the key [key], you can
    use {!header}. *)
val headers : string -> t -> string list

(** {3 [add_header]} *)

(** [add_header (key, value) t] adds a header with the key [key] and the value [value] to
    the request [t].

    If a header with the same key is already persent, a new header is appended to the list
    of headers regardless. If you want to add the header only if an header with the same
    key could not be found, you can use {!add_header_unless_exists}.

    See also {!add_headers} to add multiple headers. *)
val add_header : string * string -> t -> t

(** {3 [add_header_or_replace]} *)

(** [add_header_or_replace (key, value) t] adds a header with the key [key] and the value
    [value] to the request [t].

    If a header with the same key already exist, its value is replaced by [value]. If you
    want to add the header only if it doesn't already exist, you can use
    {!add_header_unless_exists}.

    See also {!add_headers_or_replace} to add multiple headers. *)
val add_header_or_replace : string * string -> t -> t

(** {3 [add_header_unless_exists]} *)

(** [add_header_unless_exists (key, value) t] adds a header with the key [key] and the
    value [value] to the request [t] if an header with the same key does not already
    exist.

    If a header with the same key already exist, the request remains unmodified. If you
    want to add the header regardless of whether the header is already present, you can
    use {!add_header}.

    See also {!add_headers_unless_exists} to add multiple headers. *)
val add_header_unless_exists : string * string -> t -> t

(** {3 [add_headers]} *)

(** [add_headers headers t] adds the headers [headers] to the request [t].

    The headers are added regardless of whether a header with the same key is already
    present. If you want to add the header only if an header with the same key could not
    be found, you can use {!add_headers_unless_exists}.

    See also {!add_header} to add a single header. *)
val add_headers : (string * string) list -> t -> t

(** {3 [add_headers_or_replace]} *)

(** [add_headers_or_replace (key, value) t] adds a headers [headers] to the request [t].

    If a header with the same key already exist, its value is replaced by [value]. If you
    want to add the header only if it doesn't already exist, you can use
    {!add_headers_unless_exists}.

    See also {!add_header_or_replace} to add a single header. *)
val add_headers_or_replace : (string * string) list -> t -> t

(** {3 [add_headers_unless_exists]} *)

(** [add_headers_unless_exists headers t] adds the headers [headers] to the request [t] if
    an header with the same key does not already exist.

    If a header with the same key already exist, the header is will not be added to the
    request. If you want to add the header regardless of whether the header is already
    present, you can use {!add_headers}.

    See also {!add_header_unless_exists} to add a single header. *)
val add_headers_unless_exists : (string * string) list -> t -> t

(** {3 [remove_header]} *)

(** [remove_header (key, value) t] removes all the headers with the key [key] from the
    request [t].

    If no header with the key [key] exist, the request remains unmodified. *)
val remove_header : string -> t -> t

(** {2 Specific Headers} *)

(** {3 [content_type]} *)

(** [content_type t] returns the value of the header [Content-Type] of the request [t]. *)
val content_type : t -> string option

(** {3 [set_content_type]} *)

(** [set_content_type content_type t] returns a copy of [t] with the value of the header
    [Content-Type] set to [content_type]. *)
val set_content_type : string -> t -> t

(** {3 [authorization]} *)

(** [authorization t] returns the value of the header [Authorization] of the request [t]. *)
val authorization : t -> Auth.Credential.t option

(** {3 [set_authorization]} *)

(** [set_authorization authorization t] returns a copy of [t] with the value of the header
    [Authorization] set to [authorization]. *)
val set_authorization : Auth.Credential.t -> t -> t

(** {2 Cookies} *)

(** {3 [cookie]} *)

(** [cookie ?signed_with key t] returns the value of the cookie with key [key] in the
    [Cookie] header of the request [t].

    If [signed_with] is provided, the cookies will be unsigned with the given Signer and
    only a cookie with a valid signature will be returned.

    If the request does not contain a valid [Cookie] or if no cookie with the key [key]
    exist, [None] will be returned. *)
val cookie : ?signed_with:Cookie.Signer.t -> string -> t -> string option

(** {3 [cookies]} *)

(** [cookies ?signed_with t] returns all the value of the cookies in the [Cookie] header
    of the request [t].

    If [signed_with] is provided, the cookies will be unsigned with the given Signer and
    only the cookies with a valid signature will be returned.

    If the request does not contain a valid [Cookie], [None] will be returned. *)
val cookies : ?signed_with:Cookie.Signer.t -> t -> Cookie.value list

(** {3 [add_cookie]} *)

(** [add_cookie ?sign_with ?expires ?scope ?same_site ?secure ?http_only value t] adds a
    cookie with value [value] to the request [t].

    If a cookie with the same key already exists, its value will be replaced with the new
    value of [value].

    If [sign_with] is provided, the cookie will be signed with the given Signer. *)
val add_cookie : ?sign_with:Cookie.Signer.t -> Cookie.value -> t -> t

(** {3 [add_cookie_unless_exists]} *)

(** [add_cookie_unless_exists ?sign_with ?expires ?scope ?same_site ?secure ?http_only
    value t] adds a cookie with value [value] to the request [t].

    If a cookie with the same key already exists, it will remain untouched.

    If [sign_with] is provided, the cookie will be signed with the given Signer. *)
val add_cookie_unless_exists : ?sign_with:Cookie.Signer.t -> Cookie.value -> t -> t

(** {3 [remove_cookie]} *)

(** [remove_cookie key t] removes the cookie of key [key] from the [Cookie] header of the
    request [t]. *)
val remove_cookie : string -> t -> t

(** {2 Body} *)

(** {3 [urlencoded]} *)

(** [urlencoded key t] returns the first value associated to [key] in the urlencoded body
    of the request [t].

    The function only returns the first value for the given key, because in the great
    majority of cases, there is only one parameter per key. If you want to return all the
    values associated to the key, you can use {!to_urlencoded}.

    If the key could not be found or if the request could not be parsed as urlencoded,
    [None] is returned. Use {!urlencoded_exn} to raise an exception instead.

    {3 Example}

    {[
      let request =
        Request.of_urlencoded
          ~body:[ "username", [ "admin" ]; "password", [ "password" ] ]
          "/"
          `POST
      ;;

      let username = Request.urlencoded "username" request
    ]}

    [username] will be:

    {[ Some "admin" ]} *)
val urlencoded : string -> t -> string option Lwt.t

(** {3 [urlencoded_exn]} *)

(** [urlencoded_exn key t] returns the first value associated to [key] in the urlencoded
    body of the request [t].

    The function only returns the first value for the given key, because in the great
    majority of cases, there is only one parameter per key. If you want to return all the
    values associated to the key, you can use {!to_urlencoded}.

    If the key could not be found or if the request could not be parsed as urlencoded, an
    [Invalid_argument] exception is raised. Use {!urlencoded} to return an option instead. *)
val urlencoded_exn : string -> t -> string Lwt.t

(** {3 [urlencoded_list]} *)

(** [urlencoded_list key t] returns all the values associated to [key] in the urlencoded
    body of the request [t].

    If the key could not be found or if the request could not be parsed as urlencoded, an
    empty list [\[\]] is returned instead. *)
val urlencoded_list : string -> t -> string list Lwt.t

(** {2 URI} *)

(** {3 [query]} *)

(** [query key t] returns the first value associated to [key] in the URI query parameters
    of the request [t].

    The function only returns the first value for the given key, because in the great
    majority of cases, there is only one parameter per key. If you want to return all the
    values associated to the key, you can use {!query_list}.

    If the key could not be found or if the request URI does not contain any query
    parameter, [None] is returned. Use {!query_exn} to raise an exception instead.

    {3 Example}

    {[
      let request = Request.make "/target?key=value" `GET
      let query = Request.query "key" request
    ]}

    [query] will be:

    {[ Some "value" ]} *)
val query : string -> t -> string option

(** {3 [query_exn]} *)

(** [query_exn key t] returns the first value associated to [key] in the URI query
    parameters of the request [t].

    The function only returns the first value for the given key, because in the great
    majority of cases, there is only one parameter per key. If you want to return all the
    values associated to the key, you can use {!query_list}.

    If the key could not be found or if the request URI does not contain any query
    parameter, an [Invalid_argument] exception is raised. Use {!query} to return an option
    instead. *)
val query_exn : string -> t -> string

(** {3 [query_list]} *)

(** [query_list key t] returns all the values associated to [key] in the URI query
    parameters of the request [t].

    This function exist to offer a simple way to get all of the values associated to a
    key, but most of the time, there is only one value per key. If you're not specifically
    trying to decode a request with multiple values per key, it is recommended to use
    {!query} instead.

    If the key could not be found or if the request could not be parsed as query, an empty
    list is returned.

    {3 Example}

    {[
      let request = Request.make "/target?key=value&key2=value2" `GET
      let values = Request.query_list request
    ]}

    [values] will be:

    {[ [ "key", [ "value" ]; "key2", [ "value2" ] ] ]} *)
val query_list : t -> (string * string list) list

(** {1 Utilities} *)

(** {3 [sexp_of_t]} *)

(** [sexp_of_t t] converts the request [t] to an s-expression *)
val sexp_of_t : t -> Sexplib0.Sexp.t

(** {3 [pp]} *)

(** [pp] formats the request [t] as an s-expression *)
val pp : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]

(** {3 [pp_hum]} *)

(** [pp_hum] formats the request [t] as a standard HTTP request *)
val pp_hum : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]
