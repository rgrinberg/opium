open Import

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
let request_origin request = Request.header "Origin" request

let request_vary request =
  match Request.header "Vary" request with
  | None -> []
  | Some s -> String.split_on_char ~sep:',' s
;;

let allowed_origin origins request =
  let request_origin = request_origin request in
  match request_origin with
  | Some request_origin when List.exists ~f:(String.equal request_origin) origins ->
    Some request_origin
  | _ -> if List.exists ~f:(String.equal "*") origins then Some "*" else None
;;

let vary_headers allowed_origin hs =
  let vary_header = request_vary hs in
  match allowed_origin, vary_header with
  | Some "*", _ -> []
  | None, _ -> []
  | _, [] -> [ "Vary", "Origin" ]
  | _, headers -> [ "Vary", "Origin" :: headers |> String.concat ~sep:"," ]
;;

let cors_headers ~origins ~credentials ~expose request =
  let allowed_origin = allowed_origin origins request in
  let vary_headers = vary_headers allowed_origin request in
  [ "Access-Control-Allow-Origin", allowed_origin |> Option.value ~default:""
  ; "Access-Control-Expose-Headers", String.concat ~sep:"," expose
  ; "Access-Control-Allow-Credentials", Bool.to_string credentials
  ]
  @ vary_headers
;;

let allowed_headers ~headers request =
  let value =
    match headers with
    | [ "*" ] ->
      Request.header "Access-Control-Request-Headers" request |> Option.value ~default:""
    | headers -> String.concat ~sep:"," headers
  in
  [ "Access-Control-Allow-Headers", value ]
;;

let options_cors_headers ~max_age ~headers ~methods request =
  let methods = List.map methods ~f:Method.to_string in
  [ "Access-Control-Max-Age", string_of_int max_age
  ; "Access-Control-Allow-Methods", String.concat ~sep:"," methods
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
  Rock.Middleware.create ~name:"Allow CORS" ~filter
;;
