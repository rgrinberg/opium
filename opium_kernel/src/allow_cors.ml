(** A middleware that adds Cross-Origin Resource Sharing (CORS) header to the
    responses. *)

open Rock

let default_origin = [ "*" ]
let default_credentials = true
let default_max_age = 1_728_000

let default_headers =
  [ "Authorization"
  ; "Content-Type"
  ; "Accept"
  ; "Origin"
  ; "User-Agent"
  ; "DNT"
  ; "Cache-Control"
  ; "X-Mx-ReqToken"
  ; "Keep-Alive"
  ; "X-Requested-With"
  ; "If-Modified-Since"
  ; "X-CSRF-Token"
  ]
;;

let default_expose = []
let default_methods = [ `GET; `POST; `PUT; `DELETE; `OPTIONS; `Other "PATCH" ]
let default_send_preflight_response = true
let request_origin request = Request.header "origin" request

let request_vary request =
  match Request.header "vary" request with
  | None -> []
  | Some s -> String.split_on_char ',' s
;;

let allowed_origin origins request =
  let request_origin = request_origin request in
  match request_origin with
  | Some request_origin when List.exists (String.equal request_origin) origins ->
    Some request_origin
  | _ -> if List.exists (String.equal "*") origins then Some "*" else None
;;

let vary_headers allowed_origin hs =
  let vary_header = request_vary hs in
  match allowed_origin, vary_header with
  | Some "*", _ -> []
  | None, _ -> []
  | _, [] -> [ "vary", "Origin" ]
  | _, headers -> [ "vary", "Origin" :: headers |> String.concat "," ]
;;

let cors_headers ~origins ~credentials ~expose request =
  let allowed_origin = allowed_origin origins request in
  let vary_headers = vary_headers allowed_origin request in
  [ "access-control-allow-origin", allowed_origin |> Option.value ~default:""
  ; "access-control-expose-headers", String.concat "," expose
  ; "access-control-allow-credentials", Bool.to_string credentials
  ]
  @ vary_headers
;;

let allowed_headers ~headers request =
  let value =
    match headers with
    | [ "*" ] ->
      Request.header "access-control-request-headers" request |> Option.value ~default:""
    | headers -> String.concat "," headers
  in
  [ "access-control-allow-headers", value ]
;;

let options_cors_headers ~max_age ~headers ~methods request =
  let methods = ListLabels.map methods ~f:Method.to_string in
  [ "access-control-max-age", string_of_int max_age
  ; "access-control-allow-methods", String.concat "," methods
  ]
  @ allowed_headers ~headers request
;;

let m
    ?(origins = default_origin)
    ?(credentials = default_credentials)
    ?(max_age = default_max_age)
    ?(headers = default_headers)
    ?(expose = default_expose)
    ?(methods = default_methods)
    ?(send_preflight_response = default_send_preflight_response)
    ()
  =
  let open Lwt.Syntax in
  let filter handler req =
    let+ response = handler req in
    let hs = cors_headers ~origins ~credentials ~expose req in
    let hs =
      if req.Request.meth = `OPTIONS
      then hs @ options_cors_headers ~max_age ~headers ~methods req
      else hs
    in
    match send_preflight_response, req.Request.meth with
    | true, `OPTIONS -> Response.make ~status:`No_content ~headers:(Headers.of_list hs) ()
    | _ ->
      { response with
        headers = Headers.add_list response.Response.headers (hs |> List.rev)
      }
  in
  Middleware.create ~name:"Allow CORS" ~filter
;;
