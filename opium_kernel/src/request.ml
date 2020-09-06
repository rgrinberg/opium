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

let of_plain_text ?version ?headers ?env ~body target meth =
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

let to_urlencoded t =
  let open Lwt.Syntax in
  let* body = t.body |> Body.copy |> Body.to_string in
  body |> Uri.query_of_encoded |> Lwt.return
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

let urlencoded key t =
  let open Lwt.Syntax in
  let* query = to_urlencoded t in
  Lwt.return @@ find_in_query key query
;;

let urlencoded_exn key t =
  let open Lwt.Syntax in
  let+ o = urlencoded key t in
  Option.get o
;;

let urlencoded2 key1 key2 t =
  let open Lwt.Syntax in
  let* query = to_urlencoded t in
  let value1 = find_in_query key1 query in
  let value2 = find_in_query key2 query in
  match value1, value2 with
  | Some value1, Some value2 -> Lwt.return @@ Some (value1, value2)
  | _ -> Lwt.return None
;;

let urlencoded3 key1 key2 key3 t =
  let open Lwt.Syntax in
  let* query = to_urlencoded t in
  let value1 = find_in_query key1 query in
  let value2 = find_in_query key2 query in
  let value3 = find_in_query key3 query in
  match value1, value2, value3 with
  | Some value1, Some value2, Some value3 -> Lwt.return @@ Some (value1, value2, value3)
  | _ -> Lwt.return None
;;

let urlencoded4 key1 key2 key3 key4 t =
  let open Lwt.Syntax in
  let* query = to_urlencoded t in
  let value1 = find_in_query key1 query in
  let value2 = find_in_query key2 query in
  let value3 = find_in_query key3 query in
  let value4 = find_in_query key4 query in
  match value1, value2, value3, value4 with
  | Some value1, Some value2, Some value3, Some value4 ->
    Lwt.return @@ Some (value1, value2, value3, value4)
  | _ -> Lwt.return None
;;

let urlencoded5 key1 key2 key3 key4 key5 t =
  let open Lwt.Syntax in
  let* query = to_urlencoded t in
  let value1 = find_in_query key1 query in
  let value2 = find_in_query key2 query in
  let value3 = find_in_query key3 query in
  let value4 = find_in_query key4 query in
  let value5 = find_in_query key5 query in
  match value1, value2, value3, value4, value5 with
  | Some value1, Some value2, Some value3, Some value4, Some value5 ->
    Lwt.return @@ Some (value1, value2, value3, value4, value5)
  | _ -> Lwt.return None
;;

let query_list t = t.target |> Uri.of_string |> Uri.query
let query key t = query_list t |> find_in_query key
let query_exn key t = query key t |> Option.get

let query2 key1 key2 t =
  let query = query_list t in
  let value1 = find_in_query key1 query in
  let value2 = find_in_query key2 query in
  match value1, value2 with
  | Some value1, Some value2 -> Some (value1, value2)
  | _ -> None
;;

let query3 key1 key2 key3 t =
  let query = query_list t in
  let value1 = find_in_query key1 query in
  let value2 = find_in_query key2 query in
  let value3 = find_in_query key3 query in
  match value1, value2, value3 with
  | Some value1, Some value2, Some value3 -> Some (value1, value2, value3)
  | _ -> None
;;

let query4 key1 key2 key3 key4 t =
  let query = query_list t in
  let value1 = find_in_query key1 query in
  let value2 = find_in_query key2 query in
  let value3 = find_in_query key3 query in
  let value4 = find_in_query key4 query in
  match value1, value2, value3, value4 with
  | Some value1, Some value2, Some value3, Some value4 ->
    Some (value1, value2, value3, value4)
  | _ -> None
;;

let query5 key1 key2 key3 key4 key5 t =
  let query = query_list t in
  let value1 = find_in_query key1 query in
  let value2 = find_in_query key2 query in
  let value3 = find_in_query key3 query in
  let value4 = find_in_query key4 query in
  let value5 = find_in_query key5 query in
  match value1, value2, value3, value4, value5 with
  | Some value1, Some value2, Some value3, Some value4, Some value5 ->
    Some (value1, value2, value3, value4, value5)
  | _ -> None
;;

let param_list t =
  let { Route.params; _ } = Hmap0.find_exn Router_env.key t.env in
  params
;;

let param key t =
  let params = param_list t in
  List.assoc_opt key params
;;

let param_exn key t = param key t |> Option.get

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

let param4 key1 key2 key3 key4 t =
  let params = param_list t in
  let value1 = List.assoc_opt key1 params in
  let value2 = List.assoc_opt key2 params in
  let value3 = List.assoc_opt key3 params in
  let value4 = List.assoc_opt key4 params in
  match value1, value2, value3, value4 with
  | Some value1, Some value2, Some value3, Some value4 ->
    Some (value1, value2, value3, value4)
  | _ -> None
;;

let param5 key1 key2 key3 key4 key5 t =
  let params = param_list t in
  let value1 = List.assoc_opt key1 params in
  let value2 = List.assoc_opt key2 params in
  let value3 = List.assoc_opt key3 params in
  let value4 = List.assoc_opt key4 params in
  let value5 = List.assoc_opt key5 params in
  match value1, value2, value3, value4, value5 with
  | Some value1, Some value2, Some value3, Some value4, Some value5 ->
    Some (value1, value2, value3, value4, value5)
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
    "%s %s %s\n%s\n\n%s\n"
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

let pp fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
let pp_hum fmt t = Format.fprintf fmt "%s\n%!" (http_string_of_t t)
