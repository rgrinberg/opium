(** Module to create and work with HTTP responses.

    It offers convenience functions to create common responses and update them. *)

type t = Rock.Response.t =
  { version : Version.t
  ; status : Status.t
  ; reason : string option
  ; headers : Headers.t
  ; body : Body.t
  ; env : Context.t
  }

(** {1 Constructors} *)

(** {3 [make]} *)

(** [make ?version ?status ?reason ?headers ?body ?env ()] creates a new response from the
    given values.

    By default, the HTTP version will be set to 1.1, the HTTP status to 200 and the
    response will not contain any header or body. *)
val make
  :  ?version:Version.t
  -> ?status:Status.t
  -> ?reason:string
  -> ?headers:Headers.t
  -> ?body:Body.t
  -> ?env:Context.t
  -> unit
  -> t

(** {3 [of_plain_text]} *)

(** [of_plain_text ?status ?version ?reason ?headers ?env body] creates a new response
    from the given values and a string body.

    The content type of the response will be set to [text/plain] and the body will contain
    the string [body].

    {3 Example}

    The response initialized with:

    {[ Response.of_plain_text "Hello World" ]}

    Will be represented as:

    {%html: <pre>
HTTP/1.1 200 
Content-Type: text/plain

Hello World </pre>%} *)
val of_plain_text
  :  ?version:Version.t
  -> ?status:Status.t
  -> ?reason:string
  -> ?headers:Headers.t
  -> ?env:Context.t
  -> string
  -> t

(** {3 [of_json]} *)

(** [of_json ?status ?version ?reason ?headers ?env payload] creates a new response from
    the given values and a JSON body.

    The content type of the response will be set to [application/json] and the body will
    contain the json payload [body].

    {3 Example}

    The response initialized with:

    {[ Response.of_json (`Assoc [ "Hello", `String "World" ]) ]}

    Will be represented as:

    {%html: <pre>
HTTP/1.1 200 
Content-Type: application/json

{"Hello":"World"} </pre> %} *)
val of_json
  :  ?version:Version.t
  -> ?status:Status.t
  -> ?reason:string
  -> ?headers:Headers.t
  -> ?env:Context.t
  -> Yojson.Safe.t
  -> t

(** {3 [of_html]} *)

(** [of_html ?status ?version ?reason ?headers ?env ?indent payload] creates a new
    response from the given values and a HTML body.

    The content type of the response will be set to [text/html; charset=utf-8] and the
    body will contain the HTML payload [payload].

    The header [Connection] will be set to [Keep-Alive] to opimize for bandwitdh, since it
    is assumed that users who response HTML content will be likely to make further
    responses.

    {3 Example}

    The response initialized with:

    {[
      let my_page =
        let open Tyxml.Html in
        html (head (title (txt "Title")) []) (body [ h1 [ txt "Hello World!" ] ])
      ;;

      let res = Response.of_html ~indent:true my_page
    ]}

    [res] will be represented as:

    {%html: <pre>
HTTP/1.1 200 
Connection: Keep-Alive
Content-Type: text/html; charset=utf-8

&lt;!DOCTYPE html&gt;
&lt;html xmlns=&quot;http://www.w3.org/1999/xhtml&quot;&gt;&lt;head&gt;&lt;title&gt;Title&lt;/title&gt;&lt;/head&gt;
 &lt;body&gt;&lt;h1&gt;Hello World!&lt;/h1&gt;&lt;/body&gt;
&lt;/html&gt; </pre> %} *)
val of_html
  :  ?version:Version.t
  -> ?status:Status.t
  -> ?reason:string
  -> ?headers:Headers.t
  -> ?env:Context.t
  -> ?indent:bool
  -> [ `Html ] Tyxml_html.elt
  -> t

(** {3 [of_xml]} *)

(** [of_xml ?status ?version ?reason ?headers ?env ?indent payload] creates a new response
    from the given values and a XML body.

    The content type of the response will be set to [text/xml; charset=utf-8] and the body
    will contain the XML payload [payload].

    {3 Example}

    The response initialized with:

    {[
      let xml =
        let open Tyxml.Xml in
        node
          "note"
          [ node "to" [ pcdata "Tove" ]
          ; node "from" [ pcdata "Jani" ]
          ; node "heading" [ pcdata "Reminder" ]
          ; node "body" [ pcdata "Don't forget me this weekend!" ]
          ]
      ;;

      let res = Response.of_xml ~indent:true xml
    ]}

    [res] will be represented as:

    {%html: <pre>
HTTP/1.1 200 
Content-Type: application/xml charset=utf-8

&lt;note&gt;&lt;to&gt;Tove&lt;/to&gt;&lt;from&gt;Jani&lt;/from&gt;&lt;heading&gt;Reminder&lt;/heading&gt;
 &lt;body&gt;Don't forget me this weekend!&lt;/body&gt;
&lt;/note&gt; </pre> %} *)
val of_xml
  :  ?version:Version.t
  -> ?status:Status.t
  -> ?reason:string
  -> ?headers:Headers.t
  -> ?env:Context.t
  -> ?indent:bool
  -> Tyxml_xml.elt
  -> t

(** {3 [of_svg]} *)

(** [of_svg ?status ?version ?reason ?headers ?env ?indent payload] creates a new response
    from the given values and a SVG body.

    The content type of the response will be set to [image/svg+xml] and the body will
    contain the SVG payload [payload].

    The header [Connection] will be set to [Keep-Alive] to opimize for bandwitdh, since it
    is assumed that users who response SVG content will be likely to make further
    responses.

    {3 Example}

    The response initialized with:

    {[
      let my_svg =
        let open Tyxml.Svg in
        svg
          [ circle
              ~a:
                [ a_cx (50., None)
                ; a_cy (50., None)
                ; a_r (40., None)
                ; a_fill (`Color ("black", None))
                ]
              []
          ]
      ;;

      let res = Response.of_svg ~indent:true my_svg
    ]}

    [res] will be represented as:

    {%html: <pre>
HTTP/1.1 200 
Connection: Keep-Alive
Content-Type: image/svg+xml

&lt;!DOCTYPE svg PUBLIC &quot;-//W3C//DTD SVG 1.1//EN&quot; &quot;http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd&quot;&gt;
&lt;svg xmlns=&quot;http://www.w3.org/2000/svg&quot;
 xmlns:xlink=&quot;http://www.w3.org/1999/xlink&quot;&gt;
 &lt;circle cx=&quot;50&quot; cy=&quot;50&quot; r=&quot;40&quot; fill=&quot;black&quot;&gt;&lt;/circle&gt;
&lt;/svg&gt; </pre> %} *)
val of_svg
  :  ?version:Version.t
  -> ?status:Status.t
  -> ?reason:string
  -> ?headers:Headers.t
  -> ?env:Context.t
  -> ?indent:bool
  -> [ `Svg ] Tyxml_svg.elt
  -> t

(** {3 [of_file]} *)

(** [of_file ?version ?reason ?headers ?env ?mime fname] creates a new response from a
    file [fname] by reading its content and streaming the response.

    The content type of the response will be set automatically based on the file name
    [fname]. Providing an optional [mime] type overrides the automatic detected one. *)
val of_file
  :  ?version:Version.t
  -> ?reason:string
  -> ?headers:Headers.t
  -> ?env:Context.t
  -> ?mime:string
  -> string
  -> t Lwt.t

(** {3 [redirect_to]} *)

(** [redirect_to ?status ?version ?reason ?headers ?env target] creates a new Redirect
    response from the given values.

    The response will contain the header [Location] with the value [target] and a Redirect
    HTTP status (a Redirect HTTP status starts with 3).

    By default, the HTTP status is [302 Found].

    The response initialized with:

    {[ Response.redirect_to "/redirected" ]}

    Will be represented as:

    {%html: <pre>
HTTP/1.1 302 
Location: /redirected

</pre>%}*)
val redirect_to
  :  ?status:Status.redirection
  -> ?version:Version.t
  -> ?reason:string
  -> ?headers:Headers.t
  -> ?env:Context.t
  -> string
  -> t

(** {1 Decoders} *)

(** {3 [to_json]} *)

(** [to_json t] parses the body of the response [t] as a JSON structure.

    If the body of the response cannot be parsed as a JSON structure, [None] is returned.
    Use {!to_json_exn} to raise an exception instead.

    {3 Example}

    {[
      let response = Response.of_json (`Assoc [ "Hello", `String "World" ])
      let body = Response.to_json response
    ]}

    [body] will be:

    {[ `Assoc [ "Hello", `String "World" ] ]} *)
val to_json : t -> Yojson.Safe.t option Lwt.t

(** {3 [to_json_exn]} *)

(** [to_json_exn t] parses the body of the response [t] as a JSON structure.

    If the body of the response cannot be parsed as a JSON structure, an
    [Invalid_argument] exception is raised. Use {!to_json} to return an option instead. *)
val to_json_exn : t -> Yojson.Safe.t Lwt.t

(** {3 [to_plain_text]} *)

(** [to_plain_text t] parses the body of the response [t] as a string.

    {3 Example}

    {[
      let response = Response.of_plain_text "Hello world!"
      let body = Response.to_json response
    ]}

    [body] will be:

    {[ "Hello world!" ]} *)
val to_plain_text : t -> string Lwt.t

(** {1 Getters and Setters} *)

(** {3 [status]} *)

(** [status response] returns the HTTP status of the response [response]. *)
val status : t -> Status.t

(** {3 [set_status]} *)

(** [set_status status response] returns a copy of [response] with the HTTP status set to
    [content_type]. *)
val set_status : Status.t -> t -> t

(** {2 General Headers} *)

(** [header key t] returns the value of the header with key [key] in the response [t].

    If multiple headers have the key [key], only the value of the first header will be
    returned.

    If you want to return all the values if multiple headers are found, you can use
    {!headers}. *)
val header : string -> t -> string option

(** {3 [headers]} *)

(** [headers] returns the values of all headers with the key [key] in the response [t].

    If you want to return the value of only the first header with the key [key], you can
    use {!header}. *)
val headers : string -> t -> string list

(** {3 [add_header]} *)

(** [add_header (key, value) t] adds a header with the key [key] and the value [value] to
    the response [t].

    If a header with the same key is already persent, a new header is appended to the list
    of headers regardless. If you want to add the header only if an header with the same
    key could not be found, you can use {!add_header_unless_exists}.

    See also {!add_headers} to add multiple headers. *)
val add_header : string * string -> t -> t

(** {3 [add_header_or_replace]} *)

(** [add_header_or_replace (key, value) t] adds a header with the key [key] and the value
    [value] to the response [t].

    If a header with the same key already exist, its value is replaced by [value]. If you
    want to add the header only if it doesn't already exist, you can use
    {!add_header_unless_exists}.

    See also {!add_headers_or_replace} to add multiple headers. *)
val add_header_or_replace : string * string -> t -> t

(** {3 [add_header_unless_exists]} *)

(** [add_header_unless_exists (key, value) t] adds a header with the key [key] and the
    value [value] to the response [t] if an header with the same key does not already
    exist.

    If a header with the same key already exist, the response remains unmodified. If you
    want to add the header regardless of whether the header is already present, you can
    use {!add_header}.

    See also {!add_headers_unless_exists} to add multiple headers. *)
val add_header_unless_exists : string * string -> t -> t

(** {3 [add_headers]} *)

(** [add_headers headers response] adds the headers [headers] to the response [t].

    The headers are added regardless of whether a header with the same key is already
    present. If you want to add the header only if an header with the same key could not
    be found, you can use {!add_headers_unless_exists}.

    See also {!add_header} to add a single header. *)
val add_headers : (string * string) list -> t -> t

(** {3 [add_headers_or_replace]} *)

(** [add_headers_or_replace (key, value) t] adds a headers [headers] to the response [t].

    If a header with the same key already exist, its value is replaced by [value]. If you
    want to add the header only if it doesn't already exist, you can use
    {!add_headers_unless_exists}.

    See also {!add_header_or_replace} to add a single header. *)
val add_headers_or_replace : (string * string) list -> t -> t

(** {3 [add_headers_unless_exists]} *)

(** [add_headers_unless_exists headers response] adds the headers [headers] to the
    response [t] if an header with the same key does not already exist.

    If a header with the same key already exist, the header is will not be added to the
    response. If you want to add the header regardless of whether the header is already
    present, you can use {!add_headers}.

    See also {!add_header_unless_exists} to add a single header. *)
val add_headers_unless_exists : (string * string) list -> t -> t

(** {3 [remove_header]} *)

(** [remove_header (key, value) t] removes all the headers with the key [key] from the
    response [t].

    If no header with the key [key] exist, the response remains unmodified. *)
val remove_header : string -> t -> t

(** {2 Specific Headers} *)

(** {3 [content_type]} *)

(** [content_type response] returns the value of the header [Content-Type] of the response
    [response]. *)
val content_type : t -> string option

(** {3 [set_content_type]} *)

(** [set_content_type content_type response] returns a copy of [response] with the value
    of the header [Content-Type] set to [content_type]. *)
val set_content_type : string -> t -> t

(** {3 [etag]} *)

(** [etag response] returns the value of the header [ETag] of the response [response]. *)
val etag : t -> string option

(** {3 [set_etag]} *)

(** [set_etag etag response] returns a copy of [response] with the value of the header
    [ETag] set to [etag]. *)
val set_etag : string -> t -> t

(** {3 [location]} *)

(** [location response] returns the value of the header [Location] of the response
    [response]. *)
val location : t -> string option

(** {3 [set_location]} *)

(** [set_location location response] returns a copy of [response] with the value of the
    header [Location] set to [location]. *)
val set_location : string -> t -> t

(** {3 [cache_control]} *)

(** [cache_control response] returns the value of the header [Cache-Control] of the
    response [response]. *)
val cache_control : t -> string option

(** {3 [set_cache_control]} *)

(** [set_cache_control cache_control response] returns a copy of [response] with the value
    of the header [Cache-Control] set to [cache_control]. *)
val set_cache_control : string -> t -> t

(** {3 [cookie]} *)

(** [cookie ?signed_with key t] returns the value of the cookie with key [key] in the
    [Set-Cookie] header of the response [t].

    If [signed_with] is provided, the cookies will be unsigned with the given Signer and
    only a cookie with a valid signature will be returned.

    If the response does not contain a valid [Set-Cookie] or if no cookie with the key
    [key] exist, [None] will be returned. *)
val cookie : ?signed_with:Cookie.Signer.t -> string -> t -> Cookie.t option

(** {3 [cookies]} *)

(** [cookies ?signed_with t] returns all the value of the cookies in the [Set-Cookie]
    header of the response [t].

    If [signed_with] is provided, the cookies will be unsigned with the given Signer and
    only the cookies with a valid signature will be returned.

    If the response does not contain a valid [Set-Cookie], [None] will be returned. *)
val cookies : ?signed_with:Cookie.Signer.t -> t -> Cookie.t list

(** {3 [add_cookie]} *)

(** [add_cookie ?sign_with ?expires ?scope ?same_site ?secure ?http_only value t] adds a
    cookie with value [value] to the response [t].

    If a cookie with the same key already exists, its value will be replaced with the new
    value of [value].

    If [sign_with] is provided, the cookie will be signed with the given Signer. *)
val add_cookie
  :  ?sign_with:Cookie.Signer.t
  -> ?expires:Cookie.expires
  -> ?scope:Uri.t
  -> ?same_site:Cookie.same_site
  -> ?secure:bool
  -> ?http_only:bool
  -> Cookie.value
  -> t
  -> t

(** {3 [add_cookie_or_replace]} *)

(** [add_cookie_or_replace ?sign_with ?expires ?scope ?same_site ?secure ?http_only value
    t] adds a cookie with value [value] to the response [t]. If a cookie with the same key
    already exists, its value will be replaced with the new value of [value]. If
    [sign_with] is provided, the cookie will be signed with the given Signer. *)
val add_cookie_or_replace
  :  ?sign_with:Cookie.Signer.t
  -> ?expires:Cookie.expires
  -> ?scope:Uri.t
  -> ?same_site:Cookie.same_site
  -> ?secure:bool
  -> ?http_only:bool
  -> Cookie.value
  -> t
  -> t

(** {3 [add_cookie_unless_exists]} *)

(** [add_cookie_unless_exists ?sign_with ?expires ?scope ?same_site ?secure ?http_only
    value t] adds a cookie with value [value] to the response [t].

    If a cookie with the same key already exists, it will remain untouched.

    If [sign_with] is provided, the cookie will be signed with the given Signer. *)
val add_cookie_unless_exists
  :  ?sign_with:Cookie.Signer.t
  -> ?expires:Cookie.expires
  -> ?scope:Uri.t
  -> ?same_site:Cookie.same_site
  -> ?secure:bool
  -> ?http_only:bool
  -> Cookie.value
  -> t
  -> t

(** {3 [remove_cookie]} *)

(** [remove_cookie key t] removes the cookie of key [key] from the [Set-Cookie] header of
    the response [t]. *)
val remove_cookie : string -> t -> t

(** {1 Utilities} *)

(** {3 [sexp_of_t]} *)

(** [sexp_of_t t] converts the response [t] to an s-expression *)
val sexp_of_t : t -> Sexplib0.Sexp.t

(** {3 [pp]} *)

(** [pp] formats the response [t] as an s-expression *)
val pp : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]

(** {3 [pp_hum]} *)

(** [pp_hum] formats the response [t] as a standard HTTP response *)
val pp_hum : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]
