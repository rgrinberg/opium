type t =
  { version : Version.t
  ; target : string
  ; headers : Headers.t
  ; meth : Method.t
  ; body : Body.t
  ; env : Hmap0.t
  }

let make
    ?(version = { Version.major = 1; minor = 1 })
    ?(body = Body.empty)
    ?(env = Hmap0.empty)
    ?(headers = Headers.empty)
    target
    meth
  =
  { version; target; headers; meth; body; env }
;;

let of_string'
    ?(content_type = "text/plain")
    ?version
    ?env
    ?(headers = Headers.empty)
    target
    meth
    body
  =
  let headers = Headers.add_unless_exists headers "Content-Type" content_type in
  make ?version ~headers ~body:(Body.of_string body) ?env target meth
;;

let of_string ?version ?headers ?env ~body target meth =
  of_string' ?version ?env ?headers target meth body
;;

let of_json ?version ?headers ?env ~body target meth =
  of_string'
    ~content_type:"application/json"
    ?version
    ?headers
    ?env
    target
    meth
    (body |> Yojson.Safe.to_string)
;;

let of_urlencoded ?version ?headers ?env ~body target meth =
  of_string'
    ~content_type:"application/x-www-form-urlencoded"
    ?version
    ?headers
    ?env
    target
    meth
    (body |> Uri.encoded_of_query)
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

let content_type t = header "Content-Type" t
let set_content_type s t = add_header ("Content-Type", s) t

let find_in_query key query =
  query
  |> ListLabels.find_opt ~f:(fun (k, _) -> k = key)
  |> Option.map (fun (_, r) -> r)
  |> fun opt ->
  Option.bind opt (fun x ->
      try Some (List.hd x) with
      | Not_found -> None)
;;

let urlencoded' body key =
  match body |> Uri.pct_decode |> Uri.query_of_encoded |> find_in_query key with
  | None -> Lwt.return None
  | Some value -> Lwt.return (Some value)
;;

let urlencoded key t =
  let open Lwt.Syntax in
  let* body = t.body |> Body.copy |> Body.to_string in
  urlencoded' body key
;;

let urlencoded2 key1 key2 t =
  let open Lwt.Syntax in
  let* body = t.body |> Body.copy |> Body.to_string in
  let* value1 = urlencoded' body key1 in
  let+ value2 = urlencoded' body key2 in
  value1, value2
;;

let urlencoded3 key1 key2 key3 t =
  let open Lwt.Syntax in
  let* body = t.body |> Body.copy |> Body.to_string in
  let* value1 = urlencoded' body key1 in
  let* value2 = urlencoded' body key2 in
  let+ value3 = urlencoded' body key3 in
  value1, value2, value3

let param_list t =
  let { Route.params; _ } = Hmap0.find_exn Router_env.key t.env in
  params
;;

let param key t =
  let params = param_list t in
  List.assoc_opt key params
;;

let param2 key1 key2 t =
  let params = param_list t in
  let value1 = List.assoc_opt key1 params in
  let value2 = List.assoc_opt key2 params in
  match value1, value2 with
  | Some value1, Some value2 -> Some (value1, value2)
  | _ -> None
;;

let param3 key1 key2 key3 t =
  let params = param_list t in
  let value1 = List.assoc_opt key1 params in
  let value2 = List.assoc_opt key2 params in
  let value3 = List.assoc_opt key3 params in
  match value1, value2, value3 with
  | Some value1, Some value2, Some value3 -> Some (value1, value2, value3)
  | _ -> None
;;

let sexp_of_t { version; target; headers; meth; body; env } =
  let open Sexplib0.Sexp_conv in
  let open Sexplib0.Sexp in
  List
    [ List [ Atom "version"; Version.sexp_of_t version ]
    ; List [ Atom "target"; sexp_of_string target ]
    ; List [ Atom "method"; Method.sexp_of_t meth ]
    ; List [ Atom "headers"; Headers.sexp_of_t headers ]
    ; List [ Atom "body"; Body.sexp_of_t body ]
    ; List [ Atom "env"; Hmap0.sexp_of_t env ]
    ]
;;

let http_string_of_t t =
  Printf.sprintf
    "%s %s HTTP/%s\n%s\n\n%s\n"
    (Method.to_string t.meth)
    t.target
    (Version.to_string t.version)
    (Headers.to_string t.headers)
    (match t.body.content with
    | `Empty -> ""
    | `String s -> s
    | `Bigstring b -> Bigstringaf.to_string b
    | `Stream _ -> "<stream>")
;;

let pp_hum fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
let pp_http fmt t = Format.fprintf fmt "%s\n%!" (http_string_of_t t)
