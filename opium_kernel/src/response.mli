type t =
  { version : Version.t
  ; status : Status.t
  ; reason : string option
  ; headers : Headers.t
  ; body : Body.t
  ; env : Hmap0.t
  }

(** {3 Constructors} *)

(** [make ?version ?status ?reason ?headers ?body ?env ()] creates a new response from the
    given values. *)
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

    The response will contain the header [Location] with the value [target] and a Redirect
    HTTP status (a Redirect HTTP status starts with 3).

    By default, the HTTP status is [302 Found]. *)
val redirect_to
  :  ?status:Status.redirection
  -> ?version:Httpaf.Version.t
  -> ?reason:string
  -> ?headers:Httpaf.Headers.t
  -> ?env:Hmap0.t
  -> string
  -> t

(** [of_plain_text ?status ?version ?reason ?headers ?env body] creates a new request from
    the given values and a string body.

    The content type of the request will be set to [text/plain] and the body will contain
    the string [body].

    {4 Example}

    The request initialized with:

    {[ Response.of_plain_text "Hello World" ]}

    Will be represented as:

    {%html: <pre>
HTTP/HTTP/1.1 200 
Content-Type: text/plain

Hello World </pre>%} *)
val of_plain_text
  :  ?version:Version.t
  -> ?status:Status.t
  -> ?reason:string
  -> ?headers:Headers.t
  -> ?env:Hmap0.t
  -> string
  -> t

(** [of_json ?status ?version ?reason ?headers ?env payload] creates a new request from
    the given values and a JSON body.

    The content type of the request will be set to [application/json] and the body will
    contain the json payload [body].

    {4 Example}

    The request initialized with:

    {[ Response.of_json (`Assoc [ "Hello", `String "World" ]) ]}

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

(** [of_html ?status ?version ?reason ?headers ?env payload] creates a new request from
    the given values and a HTML body.

    The content type of the request will be set to [text/html; charset=utf-8] and the body
    will contain the HTML payload [body].

    The header [Connection] will be set to [Keep-Alive] to opimize for bandwitdh, since it
    is assumed that users who request HTML content will be likely to make further
    requests.

    {4 Example}

    The request initialized with:

    {[
      Response.of_html
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
          Format.asprintf "%a" (Tyxml.Html.pp ()) body |> Opium_kernel.Body.of_string
        in
        Opium_kernel.Response.of_html ?version ?status ?reason ?headers ?env body
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

(** ??? *)
val of_svg
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

(** [headers] returns the values of all headers with the key [key] in the response [t].

    If you want to return the value of only the first header with the key [key], you can
    use {!header}. *)
val headers : string -> t -> string list

(** [add_header (key, value) t] adds a header with the key [key] and the value [value] to
    the response [t].

    If a header with the same key is already persent, a new header is appended to the list
    of headers regardless. If you want to add the header only if an header with the same
    key could not be found, you can use {!add_header_unless_exists}.

    See also {!add_headers} to add multiple headers. *)
val add_header : string * string -> t -> t

(** [add_header_unless_exists (key, value) t] adds a header with the key [key] and the
    value [value] to the response [t] if an header with the same key does not already
    exist.

    If a header with the same key already exist, the response remains unmodified. If you
    want to add the header regardless of whether the header is already present, you can
    use {!add_header}.

    See also {!add_headers_unless_exists} to add multiple headers. *)
val add_header_unless_exists : string * string -> t -> t

(** [add_headers headers response] adds the headers [headers] to the response [t].

    The headers are added regardless of whether a header with the same key is already
    present. If you want to add the header only if an header with the same key could not
    be found, you can use {!add_headers_unless_exists}.

    See also {!add_header} to add a single header. *)
val add_headers : (string * string) list -> t -> t

(** [add_headers_unless_exists headers response] adds the headers [headers] to the
    response [t] if an header with the same key does not already exist.

    If a header with the same key already exist, the header is will not be added to the
    response. If you want to add the header regardless of whether the header is already
    present, you can use {!add_headers}.

    See also {!add_header_unless_exists} to add a single header. *)
val add_headers_unless_exists : (string * string) list -> t -> t

(** [content_type response] returns the value of the header [Content-Type] of the response
    [response]. *)
val content_type : t -> string option

(** [set_content_type content_type response] returns a copy of [response] with the value
    of the header [Content-Type] set to [content_type]. *)
val set_content_type : string -> t -> t

(** [status response] returns the HTTP status of the response [response]. *)
val status : t -> Status.t

(** [set_status status response] returns a copy of [response] with the HTTP status set to
    [content_type]. *)
val set_status : Status.t -> t -> t

(** {3 Utilities} *)

(** [sexp_of_t t] converts the response [t] to an s-expression *)
val sexp_of_t : t -> Sexplib0.Sexp.t

(** [pp_hum] formats the response [t] as an s-expression *)
val pp_hum : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]

(** [pp_http] formats the response [t] as a standard HTTP response *)
val pp_http : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]
