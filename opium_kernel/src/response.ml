type t =
  { version : Version.t
  ; status : Status.t
  ; reason : string option
  ; headers : Headers.t
  ; body : Body.t
  ; env : Hmap0.t
  }

let make
    ?(version = { Version.major = 1; minor = 1 })
    ?(status = `OK)
    ?reason
    ?(headers = Headers.empty)
    ?(body = Body.empty)
    ?(env = Hmap0.empty)
    ()
  =
  { version; status; reason; headers; body; env }
;;

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

let add_header_unless_exists (k, v) t =
  { t with headers = Headers.add_unless_exists t.headers k v }
;;

let add_headers hs t = { t with headers = Headers.add_list t.headers hs }

let add_headers_unless_exists hs t =
  { t with headers = Headers.add_list_unless_exists t.headers hs }
;;

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

let of_html ?version ?status ?reason ?(headers = Headers.empty) ?env body =
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

let of_svg ?version ?status ?reason ?(headers = Headers.empty) ?env body =
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

let content_type t = header "Content-Type" t
let set_content_type s t = add_header ("Content-Type", s) t
let status t = t.status
let set_status s t = { t with status = s }

let sexp_of_t { version; status; reason; headers; body; env } =
  let open Sexplib0.Sexp_conv in
  let open Sexplib0.Sexp in
  List
    [ List [ Atom "version"; Version.sexp_of_t version ]
    ; List [ Atom "status"; Status.sexp_of_t status ]
    ; List [ Atom "reason"; sexp_of_option sexp_of_string reason ]
    ; List [ Atom "headers"; Headers.sexp_of_t headers ]
    ; List [ Atom "body"; Body.sexp_of_t body ]
    ; List [ Atom "env"; Hmap0.sexp_of_t env ]
    ]
;;

let http_string_of_t t =
  Printf.sprintf
    "HTTP/%s %s %s\n%s\n\n%s\n"
    (Version.to_string t.version)
    (Status.to_string t.status)
    (Option.value ~default:"" t.reason)
    (Headers.to_string t.headers)
    (match t.body.content with
    | `Empty -> ""
    | `String s -> s
    | `Bigstring b -> Bigstringaf.to_string b
    | `Stream _ -> "<stream>")
;;

let pp_hum fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
let pp_http fmt t = Format.fprintf fmt "%s\n%!" (http_string_of_t t)
