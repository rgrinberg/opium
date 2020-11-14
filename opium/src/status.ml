open Import
include Httpaf.Status

let rec default_reason_phrase status =
  match status with
  | #Httpaf.Status.standard as status -> Httpaf.Status.default_reason_phrase status
  | `Code n when n >= 400 && n <= 599 ->
    (match Httpaf.Status.of_code n with
    | `Code 421 -> "Misdirected Request"
    | `Code 422 -> "Unprocessable Entity"
    | `Code 423 -> "Locked"
    | `Code 424 -> "Failed Dependency"
    | `Code 428 -> "Precondition Required"
    | `Code 429 -> "Too Many Requests"
    | `Code 431 -> "Request Header Fields Too Large"
    | `Code 444 -> "Connection Closed Without Response"
    | `Code 451 -> "Unavailable For Legal Reasons"
    | `Code 499 -> "Client Closed Request"
    | `Code 506 -> "Variant Also Negotiates"
    | `Code 507 -> "Insufficient Storage"
    | `Code 508 -> "Loop Detected"
    | `Code 510 -> "Not Extended"
    | `Code 511 -> "Network Authentication Required"
    | `Code _ -> "Unknown Error"
    | status -> default_reason_phrase status)
  | _ -> ""
;;

let rec long_reason_phrase status =
  match status with
  (* Client error *)
  | `Bad_request ->
    "The server cannot or will not process the request due to something that is \
     perceived to be a client error (e.g., malformed request syntax, invalid request \
     message framing, or deceptive request routing)."
  | `Unauthorized ->
    "The request has not been applied because it lacks valid authentication credentials \
     for the target resource."
  | `Payment_required -> "Reserved for future use."
  | `Forbidden -> "The server understood the request but refuses to authorize it."
  | `Not_found ->
    "The origin server did not find a current representation for the target resource or \
     is not willing to disclose that one exists."
  | `Method_not_allowed ->
    "The method received in the request-line is known by the origin server but not \
     supported by the target resource."
  | `Not_acceptable ->
    "The target resource does not have a current representation that would be acceptable \
     to the user agent, according to the proactive negotiation header fields received in \
     the request, and the server is unwilling to supply a default representation."
  | `Proxy_authentication_required ->
    "Similar to 401 Unauthorized, but it indicates that the client needs to authenticate \
     itself in order to use a proxy."
  | `Request_timeout ->
    "The server did not receive a complete request message within the time that it was \
     prepared to wait."
  | `Conflict ->
    "The request could not be completed due to a conflict with the current state of the \
     target resource. This code is used in situations where the user might be able to \
     resolve the conflict and resubmit the request."
  | `Gone ->
    "The target resource is no longer available at the origin server and that this \
     condition is likely to be permanent."
  | `Length_required ->
    "The server refuses to accept the request without a defined Content-Length."
  | `Precondition_failed ->
    "One or more conditions given in the request header fields evaluated to false when \
     tested on the server."
  | `Payload_too_large ->
    "The server is refusing to process a request because the request payload is larger \
     than the server is willing or able to process."
  | `Uri_too_long ->
    "The server is refusing to service the request because the request-target is longer \
     than the server is willing to interpret."
  | `Unsupported_media_type ->
    "The origin server is refusing to service the request because the payload is in a \
     format not supported by this method on the target resource."
  | `Range_not_satisfiable ->
    "None of the ranges in the request's Range header field overlap the current extent \
     of the selected resource or that the set of ranges requested has been rejected due \
     to invalid ranges or an excessive request of small or overlapping ranges."
  | `Expectation_failed ->
    "The expectation given in the request's Expect header field could not be met by at \
     least one of the inbound servers."
  | `I_m_a_teapot ->
    "Any attempt to brew coffee with a teapot should result in the error code \"418 I'm \
     a teapot\". The resulting entity body MAY be short and stout."
  | `Enhance_your_calm ->
    "The user has sent too many requests in a given amount of time (\"rate limiting\")."
  | `Upgrade_required ->
    "The server refuses to perform the request using the current protocol but might be \
     willing to do so after the client upgrades to a different protocol."
  | `Code 421 ->
    "The request was directed at a server that is not able to produce a response. This \
     can be sent by a server that is not configured to produce responses for the \
     combination of scheme and authority that are included in the request URI."
  | `Code 422 ->
    "The server understands the content type of the request entity (hence a 415 \
     Unsupported Media Type status code is inappropriate), and the syntax of the request \
     entity is correct (thus a 400 Bad Request status code is inappropriate) but was \
     unable to process the contained instructions."
  | `Code 423 -> "The source or destination resource of a method is locked."
  | `Code 424 ->
    "The method could not be performed on the resource because the requested action \
     depended on another action and that action failed."
  | `Code 428 -> "The origin server requires the request to be conditional."
  | `Code 429 ->
    "The user has sent too many requests in a given amount of time (\"rate limiting\")."
  | `Code 431 ->
    "The server is unwilling to process the request because its header fields are too \
     large. The request MAY be resubmitted after reducing the size of the request header \
     fields."
  | `Code 451 ->
    "The server is denying access to the resource as a consequence of a legal demand."
  (* Server error *)
  | `Internal_server_error ->
    "The server encountered an unexpected condition that prevented it from fulfilling \
     the request."
  | `Not_implemented ->
    "The server does not support the functionality required to fulfill the request."
  | `Bad_gateway ->
    "The server, while acting as a gateway or proxy, received an invalid response from \
     an inbound server it accessed while attempting to fulfill the request."
  | `Service_unavailable ->
    "The server is currently unable to handle the request due to a temporary overload or \
     scheduled maintenance, which will likely be alleviated after some delay."
  | `Gateway_timeout ->
    "The server, while acting as a gateway or proxy, did not receive a timely response \
     from an upstream server it needed to access in order to complete the request."
  | `Http_version_not_supported ->
    "The server does not support, or refuses to support, the major version of HTTP that \
     was used in the request message."
  | `Code 506 ->
    "The server has an internal configuration error: the chosen variant resource is \
     configured to engage in transparent content negotiation itself, and is therefore \
     not a proper end point in the negotiation process."
  | `Code 507 ->
    "The method could not be performed on the resource because the server is unable to \
     store the representation needed to successfully complete the request."
  | `Code 508 ->
    "The server terminated an operation because it encountered an infinite loop while \
     processing a request with \"Depth: infinity\". This status indicates that the \
     entire operation failed."
  | `Code 510 ->
    "The policy for accessing the resource has not been met in the request. The server \
     should send back all the information necessary for the client to issue an extended \
     request."
  | `Code 511 -> "The client needs to authenticate to gain network access."
  | `Code n when n >= 400 && n <= 599 ->
    (match Httpaf.Status.of_code n with
    | `Code _ -> "The response returned an non-standard HTTP error code."
    | status -> long_reason_phrase status)
  | _ -> ""
;;

let sexp_of_t status =
  let open Sexp_conv in
  sexp_of_int (to_code status)
;;

let pp fmt t = Sexp.pp_hum fmt (sexp_of_t t)
let pp_hum fmt t = Format.fprintf fmt "%s" (to_string t)
