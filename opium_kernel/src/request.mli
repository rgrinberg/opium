type t =
  { version : Version.t
  ; target : string
  ; headers : Headers.t
  ; meth : Method.t
  ; body : Body.t
  ; env : Hmap0.t
  }

(** {3 Constructor} *)

(** [make ?version ?body ?env ?headers target method] creates a new request from the given
    values. *)
val make
  :  ?version:Version.t
  -> ?body:Body.t
  -> ?env:Hmap0.t
  -> ?headers:Headers.t
  -> string
  -> Method.t
  -> t

(** [of_string ?version ?headers ?env ~body target method] creates a new request from the
    given values and a string body.

    The content type of the request will be set to [text/plain] and the body will contain
    the string [body].

    {4 Example}

    The request initialized with:

    {[ Request.of_string ~body:"Hello World" "/target" `POST () ]}

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

(** [of_json ?version ?headers ?env ~body target method] creates a new request from the
    given values and a json body.

    The content type of the request will be set to [application/json] and the body will
    contain the json payload [body].

    {4 Example}

    The request initialized with:

    {[ Request.of_json ~body:(`Assoc [ "Hello", `String "World" ]) "/target" `POST () ]}

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

(** [of_urlencoded ?version ?headers ?env ~body target method] creates a new request from
    the given values and a urlencoded body.

    The content type of the request will be set to [application/x-www-form-urlencoded] and
    the body will contain the key value pairs [body] formatted in the urlencoded format.

    {4 Example}

    The request initialized with:

    {[ Request.of_urlencoded ~body:[ "key", [ "value" ] ] "/target" `POST () ]}

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

    If you want to return the value of only the first header with the key [key], you can
    use {!header}. *)
val headers : string -> t -> string list

(** [add_header (key, value) t] adds a header with the key [key] and the value [value] to
    the request [t].

    If a header with the same key is already persent, a new header is appended to the list
    of headers regardless. If you want to add the header only if an header with the same
    key could not be found, you can use {!add_header_unless_exists}.

    See also {!add_headers} to add multiple headers. *)
val add_header : string * string -> t -> t

(** [add_header_unless_exists (key, value) t] adds a header with the key [key] and the
    value [value] to the request [t] if an header with the same key does not already
    exist.

    If a header with the same key already exist, the request remains unmodified. If you
    want to add the header regardless of whether the header is already present, you can
    use {!add_header}.

    See also {!add_headers_unless_exists} to add multiple headers. *)
val add_header_unless_exists : string * string -> t -> t

(** [add_headers headers request] adds the headers [headers] to the request [t].

    The headers are added regardless of whether a header with the same key is already
    present. If you want to add the header only if an header with the same key could not
    be found, you can use {!add_headers_unless_exists}.

    See also {!add_header} to add a single header. *)
val add_headers : (string * string) list -> t -> t

(** [add_headers_unless_exists headers request] adds the headers [headers] to the request
    [t] if an header with the same key does not already exist.

    If a header with the same key already exist, the header is will not be added to the
    request. If you want to add the header regardless of whether the header is already
    present, you can use {!add_headers}.

    See also {!add_header_unless_exists} to add a single header. *)
val add_headers_unless_exists : (string * string) list -> t -> t

(** [urlencoded key t] returns the value associated to [key] in the urlencoded request
    [t].

    Since the request can be a stream, the return value is a promise.

    If the key could not be found or if the request could not be parsed as urlencoded, an
    error is returned. *)
val urlencoded : string -> t -> string option Lwt.t

(** [urlencoded2 key1 key2 t] returns the values respectively associated to [key1] and
    [key2] in the urlencoded request [t].

    Since the request can be a stream, the return value is a promise.

    If one of the key could not be found or if the request could not be parsed as
    urlencoded, an error is returned. *)
val urlencoded2 : string -> string -> t -> (string * string) option Lwt.t

(** [urlencoded2 key1 key2 key3 t] returns the values respectively associated to [key1],
    [key2] and [key3] in the urlencoded request [t].

    Since the request can be a stream, the return value is a promise.

    If one of the key could not be found or if the request could not be parsed as
    urlencoded, an error is returned. *)
val urlencoded3
  :  string
  -> string
  -> string
  -> t
  -> (string * string * string) option Lwt.t

(** ??? *)
val urlencoded4
  :  string
  -> string
  -> string
  -> string
  -> t
  -> (string * string * string * string) option Lwt.t

(** ??? *)
val urlencoded5
  :  string
  -> string
  -> string
  -> string
  -> string
  -> t
  -> (string * string * string * string * string) option Lwt.t

(** ??? *)
val query : string -> t -> string option Lwt.t

(** ??? *)
val query2 : string -> string -> t -> (string * string) option Lwt.t

(** ??? *)
val query3 : string -> string -> string -> t -> (string * string * string) option Lwt.t

(** ??? *)
val query4
  :  string
  -> string
  -> string
  -> string
  -> t
  -> (string * string * string * string) option Lwt.t

(** ??? *)
val query5
  :  string
  -> string
  -> string
  -> string
  -> string
  -> t
  -> (string * string * string * string * string) option Lwt.t

(** ??? *)
val param : string -> t -> string option Lwt.t

(** ??? *)
val param2 : string -> string -> t -> (string * string) option Lwt.t

(** ??? *)
val param3 : string -> string -> string -> t -> (string * string * string) option Lwt.t

(** ??? *)
val param4
  :  string
  -> string
  -> string
  -> string
  -> t
  -> (string * string * string * string) option Lwt.t

(** ??? *)
val param5
  :  string
  -> string
  -> string
  -> string
  -> string
  -> t
  -> (string * string * string * string * string) option Lwt.t

(** [content_type request] returns the value of the header [Content-Type] of the request
    [request]. *)
val content_type : t -> string option

(** [set_content_type content_type request] returns a copy of [request] with the value of
    the header [Content-Type] set to [content_type]. *)
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
