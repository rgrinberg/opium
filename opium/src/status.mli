(* A major part of this documentation is extracted from
   {{:https://github.com/inhabitedtype/httpaf/blob/master/lib/httpaf.mli}.

   Copyright (c) 2016, Inhabited Type LLC

   All rights reserved.*)

(** Response Status Codes

    The status-code element is a three-digit integer code giving the result of the attempt
    to understand and satisfy the request.

    See {{:https://tools.ietf.org/html/rfc7231#section-6} RFC7231§6} for more details. *)

(** The 1xx (Informational) class of status code indicates an interim response for
    communicating connection status or request progress prior to completing the requested
    action and sending a final response. See
    {{:https://tools.ietf.org/html/rfc7231#section-6.2} RFC7231§6.2} for more details. *)
type informational =
  [ `Continue
  | `Switching_protocols
  ]

(** The 2xx (Successful) class of status code indicates that the client's request was
    successfully received, understood, and accepted. See
    {{:https://tools.ietf.org/html/rfc7231#section-6.3} RFC7231§6.3} for more details. *)
type successful =
  [ `OK
  | `Created
  | `Accepted
  | `Non_authoritative_information
  | `No_content
  | `Reset_content
  | `Partial_content
  ]

(** The 3xx (Redirection) class of status code indicates that further action needs to be
    taken by the user agent in order to fulfill the request. See
    {{:https://tools.ietf.org/html/rfc7231#section-6.4} RFC7231§6.4} for more details. *)
type redirection =
  [ `Multiple_choices
  | `Moved_permanently
  | `Found
  | `See_other
  | `Not_modified
  | `Use_proxy
  | `Temporary_redirect
  ]

(** The 4xx (Client Error) class of status code indicates that the client seems to have
    erred. See {{:https://tools.ietf.org/html/rfc7231#section-6.5} RFC7231§6.5} for more
    details. *)
type client_error =
  [ `Bad_request
  | `Unauthorized
  | `Payment_required
  | `Forbidden
  | `Not_found
  | `Method_not_allowed
  | `Not_acceptable
  | `Proxy_authentication_required
  | `Request_timeout
  | `Conflict
  | `Gone
  | `Length_required
  | `Precondition_failed
  | `Payload_too_large
  | `Uri_too_long
  | `Unsupported_media_type
  | `Range_not_satisfiable
  | `Expectation_failed
  | `Upgrade_required
  | `I_m_a_teapot
  | `Enhance_your_calm
  ]

(** The 5xx (Server Error) class of status code indicates that the server is aware that it
    has erred or is incapable of performing the requested method. See
    {{:https://tools.ietf.org/html/rfc7231#section-6.6} RFC7231§6.6} for more details. *)
type server_error =
  [ `Internal_server_error
  | `Not_implemented
  | `Bad_gateway
  | `Service_unavailable
  | `Gateway_timeout
  | `Http_version_not_supported
  ]

(** The status codes defined in the HTTP 1.1 RFCs *)
type standard =
  [ informational
  | successful
  | redirection
  | client_error
  | server_error
  ]

(** The standard codes along with support for custom codes. *)
type t =
  [ standard
  | `Code of int
  ]

(** [default_reason_phrase standard] is the example reason phrase provided by RFC7231 for
    the [t] status code. The RFC allows servers to use reason phrases besides these in
    responses. *)
val default_reason_phrase : t -> string

(** [long_reason_phrase standard] is an explanation of the the [t] status code. *)
val long_reason_phrase : t -> string

(** [to_code t] is the integer representation of [t]. *)
val to_code : t -> int

(** [of_code i] is the [t] representation of [i]. [of_code] raises [Failure] if [i] is not
    a positive three-digit number. *)
val of_code : int -> t

(** [unsafe_of_code i] is equivalent to [of_code i], except it accepts any positive code,
    regardless of the number of digits it has. On negative codes, it will still raise
    [Failure]. *)
val unsafe_of_code : int -> t

(** [is_informational t] is true iff [t] belongs to the Informational class of status
    codes. *)
val is_informational : t -> bool

(** [is_successful t] is true iff [t] belongs to the Successful class of status codes. *)
val is_successful : t -> bool

(** [is_redirection t] is true iff [t] belongs to the Redirection class of status codes. *)
val is_redirection : t -> bool

(** [is_client_error t] is true iff [t] belongs to the Client Error class of status codes. *)
val is_client_error : t -> bool

(** [is_server_error t] is true iff [t] belongs to the Server Error class of status codes. *)
val is_server_error : t -> bool

(** [is_error t] is true iff [t] belongs to the Client Error or Server Error class of
    status codes. *)
val is_error : t -> bool

(** {2 Utilities} *)

(** [to_string t] returns a string representation of the status [t]. *)
val to_string : t -> string

(** [of_string s] returns a status from its string representation [s]. *)
val of_string : string -> t

(** [sexp_of_t t] converts the request [t] to an s-expression *)
val sexp_of_t : t -> Sexplib0.Sexp.t

(** [pp] formats the request [t] as an s-expression *)
val pp : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]

(** [pp_hum] formats the request [t] as a standard HTTP request *)
val pp_hum : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]
