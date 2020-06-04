(** [Error_handler] creates error HTML pages for standard HTTP errors.

    Any exception thrown by the handler will be caught and will be converted to a response
    with the status Internal Server Error (HTTP code 500).

    {4 Overriding Error}

    To override an error, a [custom_handler] can be passed. The following example override
    the handling of the "Forbidden" error.

    {[
      let custom_handler = function
        | `Forbidden -> Some (Response.of_string "Denied!")
        | _ -> None
      ;;

      let error_handler = Middleware.error_handler ~custom_handler ()
    ]} *)

open Core.Rock

let log_src = Logs.Src.create "opium.server"

let rec short_reason_of_status status =
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
    | status -> short_reason_of_status status)
  | _ -> ""
;;

let rec long_reason_of_status status =
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
    | status -> long_reason_of_status status)
  | _ -> ""
;;

let m ?custom_handler ?(name = "Error Handler") ~make_response () =
  let filter handler req =
    let open Lwt.Infix in
    Lwt.catch
      (fun () -> handler req)
      (fun exn ->
        Logs.err ~src:log_src (fun f -> f "%s" (Printexc.to_string exn));
        Lwt.return @@ Response.make ~status:`Internal_server_error ())
    >|= fun response ->
    match response.body.content, Httpaf.Status.is_error response.status with
    | `Empty, true ->
      (match Option.bind custom_handler (fun f -> f response.status) with
      | Some r -> r
      | None ->
        let code = Httpaf.Status.to_code response.status in
        let error = short_reason_of_status response.status in
        let message = long_reason_of_status response.status in
        make_response code error message)
    | _ -> response
  in
  Middleware.create ~name ~filter
;;

module Html = struct
  let style =
    {|/*! normalize.css v8.0.1 | MIT License | github.com/necolas/normalize.css */html{line-height:1.15;-webkit-text-size-adjust:100%}body,h2{margin:0}html{font-family:system-ui,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica Neue,Arial,Noto Sans,sans-serif,Apple Color Emoji,Segoe UI Emoji,Segoe UI Symbol,Noto Color Emoji;line-height:1.5}*,:after,:before{box-sizing:border-box;border:0 solid #e2e8f0}h2{font-size:inherit;font-weight:inherit}.font-semibold{font-weight:600}.text-2xl{font-size:1.5rem}.leading-8{line-height:2rem}.mx-auto{margin-left:auto;margin-right:auto}.mt-0{margin-top:0}.mb-4{margin-bottom:1rem}.py-4{padding-top:1rem;padding-bottom:1rem}.px-4{padding-left:1rem;padding-right:1rem}.text-gray-600{--text-opacity:1;color:#718096;color:rgba(113,128,150,var(--text-opacity))}.text-gray-900{--text-opacity:1;color:#1a202c;color:rgba(26,32,44,var(--text-opacity))}.antialiased{-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale}@media (min-width:640px){.sm\:text-3xl{font-size:1.875rem}.sm\:leading-9{line-height:2.25rem}.sm\:px-6{padding-left:1.5rem;padding-right:1.5rem}.sm\:py-8{padding-top:2rem;padding-bottom:2rem}}@media (min-width:1024px){.lg\:px-8{padding-left:2rem;padding-right:2rem}}|}
  ;;

  let format_error error code message =
    Format.asprintf
      {|
<!doctype html>
<html lang="en">

<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <title>%s</title>
  <style>
    %s
  </style>
</head>

<body class="antialiased">
  <div class="py-4 sm:py-8">
    <div class="max-w-8xl mx-auto px-4 sm:px-6 lg:px-8">
      <h2 class="text-2xl leading-8 font-semibold font-display text-gray-900 sm:text-3xl sm:leading-9">
        %d %s
      </h2>
      <div class="mt-0 mb-4 text-gray-600">
        %s
      </div>
    </div>
  </div>
</body>

</html>
    |}
      error
      style
      code
      error
      message
  ;;

  let m ?custom_handler () =
    m
      ?custom_handler
      ~name:"HTML Error Handler"
      ~make_response:(fun code error message ->
        format_error error code message |> Response.of_html)
      ()
  ;;
end

module Json = struct
  module Error = struct
    type t =
      { status : int
      ; error : string
      ; message : string
      }

    let to_yojson { status; error; message } =
      `Assoc [ "status", `Int status; "error", `String error; "message", `String message ]
    ;;
  end

  let m ?custom_handler () =
    m
      ?custom_handler
      ~name:"JSON Error Handler"
      ~make_response:(fun status error message ->
        let error = Error.{ status; error; message } |> Error.to_yojson in
        Response.of_json error)
      ()
  ;;
end
