type t =
  { version : Version.t
  ; status : Status.t
  ; reason : string option
  ; headers : Headers.t
  ; body : Body.t
  }

let make
    ?(version = { Version.major = 1; minor = 1 })
    ?(status = `OK)
    ?reason
    ?(headers = Headers.empty)
    ?(body = Body.empty)
    ()
  =
  { version; status; reason; headers; body }
;;

let redirect_to
    ?(status : Status.redirection = `Found)
    ?version
    ?reason
    ?(headers = Headers.empty)
    location
  =
  let headers = Headers.add_unless_exists headers "Location" location in
  make ?version ~status:(status :> Status.t) ?reason ~headers ()
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
  ListLabels.fold_left hs ~init:t ~f:(fun acc el -> add_header_or_replace el acc)
;;

let add_headers_unless_exists hs t =
  { t with headers = Headers.add_list_unless_exists t.headers hs }
;;

let remove_header key t = { t with headers = Headers.remove t.headers key }

let of_string'
    ?(content_type = "text/plain")
    ?version
    ?status
    ?reason
    ?(headers = Headers.empty)
    body
  =
  let headers = Headers.add_unless_exists headers "Content-Type" content_type in
  make ?version ?status ?reason ~headers ~body:(Body.of_string body) ()
;;

let of_plain_text ?version ?status ?reason ?headers body =
  of_string' ?version ?status ?reason ?headers body
;;

let of_html ?version ?status ?reason ?(headers = Headers.empty) ?indent body =
  let body = Format.asprintf "%a" (Tyxml_html.pp ?indent ()) body in
  let headers = Headers.add_unless_exists headers "Connection" "Keep-Alive" in
  of_string'
    ~content_type:"text/html; charset=utf-8"
    ?version
    ?status
    ?reason
    ~headers
    body
;;

let of_xml ?version ?status ?reason ?(headers = Headers.empty) ?indent body =
  let body = Format.asprintf "%a" (Tyxml.Xml.pp ?indent ()) body in
  of_string'
    ~content_type:"application/xml charset=utf-8"
    ?version
    ?status
    ?reason
    ~headers
    body
;;

let of_svg ?version ?status ?reason ?(headers = Headers.empty) ?indent body =
  let body = Format.asprintf "%a" (Tyxml.Svg.pp ?indent ()) body in
  let headers = Headers.add_unless_exists headers "Connection" "Keep-Alive" in
  of_string' ~content_type:"image/svg+xml" ?version ?status ?reason ~headers body
;;

let of_json ?version ?status ?reason ?headers body =
  of_string'
    ~content_type:"application/json"
    ?version
    ?status
    ?reason
    ?headers
    (body |> Yojson.Safe.to_string)
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

let sexp_of_t { version; status; reason; headers; body } =
  let open Sexplib0.Sexp_conv in
  let open Sexplib0.Sexp in
  List
    [ List [ Atom "version"; Version.sexp_of_t version ]
    ; List [ Atom "status"; Status.sexp_of_t status ]
    ; List [ Atom "reason"; sexp_of_option sexp_of_string reason ]
    ; List [ Atom "headers"; Headers.sexp_of_t headers ]
    ; List [ Atom "body"; Body.sexp_of_t body ]
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

let pp fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
let pp_hum fmt t = Format.fprintf fmt "%s\n%!" (http_string_of_t t)
