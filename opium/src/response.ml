open Import
include Rock.Response

let redirect_to
    ?(status : Status.redirection = `Found)
    ?version
    ?reason
    ?(headers = Headers.empty)
    ?env
    location
  =
  let headers = Headers.add_unless_exists headers "Location" location in
  make ?version ~status:(status :> Status.t) ?reason ~headers ?env ()
;;

let header header t = Headers.get t.headers header
let headers header t = Headers.get_multi t.headers header
let add_header (k, v) t = { t with headers = Headers.add t.headers k v }

let add_header_or_replace (k, v) t =
  { t with
    headers =
      (if Headers.mem t.headers k
      then Headers.replace t.headers k v
      else Headers.add t.headers k v)
  }
;;

let add_header_unless_exists (k, v) t =
  { t with headers = Headers.add_unless_exists t.headers k v }
;;

let add_headers hs t = { t with headers = Headers.add_list t.headers hs }

let add_headers_or_replace hs t =
  List.fold_left hs ~init:t ~f:(fun acc el -> add_header_or_replace el acc)
;;

let add_headers_unless_exists hs t =
  { t with headers = Headers.add_list_unless_exists t.headers hs }
;;

let remove_header key t = { t with headers = Headers.remove t.headers key }

let cookie ?signed_with key t =
  headers "Set-Cookie" t
  |> List.find_map ~f:(fun v ->
         match Cookie.of_set_cookie_header ?signed_with ("Set-Cookie", v) with
         | Some (Cookie.{ value = k, _; _ } as c) when String.equal k key -> Some c
         | _ -> None)
;;

let cookies ?signed_with t =
  headers "Set-Cookie" t
  |> List.filter_map ~f:(fun v ->
         Cookie.of_set_cookie_header ?signed_with ("Set-Cookie", v))
;;

let add_cookie ?sign_with ?expires ?scope ?same_site ?secure ?http_only value t =
  let cookie_header =
    Cookie.make ?sign_with ?expires ?scope ?same_site ?secure ?http_only value
    |> Cookie.to_set_cookie_header
  in
  add_header cookie_header t
;;

let add_cookie_or_replace ?sign_with ?expires ?scope ?same_site ?secure ?http_only value t
  =
  let cookie_header =
    Cookie.make ?sign_with ?expires ?scope ?same_site ?secure ?http_only value
    |> Cookie.to_set_cookie_header
  in
  let headers =
    List.replace_or_add
      ~f:(fun (k, v) _ ->
        match k, v with
        | k, v
          when String.equal (String.lowercase_ascii k) "set-cookie"
               && String.is_prefix v ~prefix:(fst value) -> true
        | _ -> false)
      cookie_header
      (Headers.to_list t.headers)
  in
  { t with headers = Headers.of_list headers }
;;

let add_cookie_unless_exists
    ?sign_with
    ?expires
    ?scope
    ?same_site
    ?secure
    ?http_only
    (k, v)
    t
  =
  let cookies = cookies t in
  if List.exists cookies ~f:(fun Cookie.{ value = cookie, _; _ } -> String.equal cookie k)
  then t
  else add_cookie ?sign_with ?expires ?scope ?same_site ?secure ?http_only (k, v) t
;;

let remove_cookie key t = add_cookie_or_replace ~expires:(`Max_age 0L) (key, "") t

let of_string'
    ?(content_type = "text/plain")
    ?version
    ?status
    ?reason
    ?env
    ?(headers = Headers.empty)
    body
  =
  let headers = Headers.add_unless_exists headers "Content-Type" content_type in
  make ?version ?status ?reason ~headers ~body:(Body.of_string body) ?env ()
;;

let of_plain_text ?version ?status ?reason ?headers ?env body =
  of_string' ?version ?status ?reason ?env ?headers body
;;

let of_html ?version ?status ?reason ?(headers = Headers.empty) ?env ?indent body =
  let body = Format.asprintf "%a" (Tyxml_html.pp ?indent ()) body in
  let headers = Headers.add_unless_exists headers "Connection" "Keep-Alive" in
  of_string'
    ~content_type:"text/html; charset=utf-8"
    ?version
    ?status
    ?reason
    ?env
    ~headers
    body
;;

let of_xml ?version ?status ?reason ?(headers = Headers.empty) ?env ?indent body =
  let body = Format.asprintf "%a" (Tyxml.Xml.pp ?indent ()) body in
  of_string'
    ~content_type:"application/xml charset=utf-8"
    ?version
    ?status
    ?reason
    ?env
    ~headers
    body
;;

let of_svg ?version ?status ?reason ?(headers = Headers.empty) ?env ?indent body =
  let body = Format.asprintf "%a" (Tyxml.Svg.pp ?indent ()) body in
  let headers = Headers.add_unless_exists headers "Connection" "Keep-Alive" in
  of_string' ~content_type:"image/svg+xml" ?version ?status ?reason ?env ~headers body
;;

let of_json ?version ?status ?reason ?headers ?env body =
  of_string'
    ~content_type:"application/json"
    ?version
    ?status
    ?reason
    ?headers
    ?env
    (body |> Yojson.Safe.to_string)
;;

let of_file ?version ?reason ?headers ?env ?mime fname =
  let open Lwt.Syntax in
  let* body = Body.of_file fname in
  match body with
  | None ->
    let res =
      make ?version ~status:(`Not_found :> Httpaf.Status.t) ?reason ?headers ?env ()
    in
    Lwt.return res
  | Some body ->
    let mime_type =
      match mime with
      | Some mime_type -> mime_type
      | None -> Magic_mime.lookup fname
    in
    let headers = Option.value ~default:Headers.empty headers in
    let headers = Httpaf.Headers.add_unless_exists headers "Content-Type" mime_type in
    let res = make ?version ~status:`OK ?reason ~headers ?env ~body () in
    Lwt.return res
;;

let status t = t.status
let set_status s t = { t with status = s }
let content_type t = header "Content-Type" t
let set_content_type s t = add_header_or_replace ("Content-Type", s) t
let etag t = header "ETag" t
let set_etag s t = add_header_or_replace ("ETag", s) t
let location t = header "Location" t
let set_location s t = add_header_or_replace ("Location", s) t
let cache_control t = header "Cache-Control" t
let set_cache_control s t = add_header_or_replace ("Cache-Control", s) t

let to_json_exn t =
  let open Lwt.Syntax in
  let* body = t.body |> Body.copy |> Body.to_string in
  Lwt.return @@ Yojson.Safe.from_string body
;;

let to_json t =
  let open Lwt.Syntax in
  Lwt.catch
    (fun () ->
      let+ json = to_json_exn t in
      Some json)
    (function
      | _ -> Lwt.return None)
;;

let to_plain_text t = Body.copy t.body |> Body.to_string

let sexp_of_t { version; status; reason; headers; body; env } =
  let open Sexp_conv in
  let open Sexp in
  List
    [ List [ Atom "version"; Version.sexp_of_t version ]
    ; List [ Atom "status"; Status.sexp_of_t status ]
    ; List [ Atom "reason"; sexp_of_option sexp_of_string reason ]
    ; List [ Atom "headers"; Headers.sexp_of_t headers ]
    ; List [ Atom "body"; Body.sexp_of_t body ]
    ; List [ Atom "env"; Context.sexp_of_t env ]
    ]
;;

let http_string_of_t t =
  Format.asprintf
    "%a %a %s\n%a\n%a"
    Version.pp_hum
    t.version
    Status.pp_hum
    t.status
    (Option.value ~default:"" t.reason)
    Headers.pp_hum
    t.headers
    Body.pp_hum
    t.body
;;

let pp fmt t = Sexp.pp_hum fmt (sexp_of_t t)
let pp_hum fmt t = Format.fprintf fmt "%s@." (http_string_of_t t)
