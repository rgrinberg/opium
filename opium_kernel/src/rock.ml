module Body = Body
module Status = Status
module Version = Version
module Headers = Headers
module Method = Method

module Service = struct
  type ('req, 'res) t = 'req -> 'res Lwt.t

  let id req = Lwt.return req
end

module Filter = struct
  type ('req, 'rep, 'req_, 'rep_) t = ('req, 'rep) Service.t -> ('req_, 'rep_) Service.t
  type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t

  let ( >>> ) f1 f2 s = s |> f1 |> f2
  let apply_all filters service = ListLabels.fold_left filters ~init:service ~f:( |> )
end

module Pp = struct
  open Sexplib0
  open Sexp_conv

  let sexp_of_version version =
    Sexp.(
      List
        [ Atom "version"
        ; List [ Atom "major"; sexp_of_int version.Version.major ]
        ; List [ Atom "minor"; sexp_of_int version.minor ]
        ])
  ;;

  let sexp_of_target target = Sexp.(List [ Atom "target"; sexp_of_string target ])
  let sexp_of_headers headers = Sexp.(List [ Atom "headers"; Headers.sexp_of_t headers ])
  let sexp_of_meth meth = Sexp.(List [ Atom "method"; Method.sexp_of_t meth ])
  let sexp_of_body body = Sexp.(List [ Atom "body"; Body.sexp_of_t body ])
  let sexp_of_env env = Sexp.(List [ Atom "env"; Hmap0.sexp_of_t env ])
  let sexp_of_status status = Sexp.(List [ Atom "status"; Status.sexp_of_t status ])

  let sexp_of_reason reason =
    Sexp.(List [ Atom "reason"; sexp_of_option sexp_of_string reason ])
  ;;
end

module Request = struct
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
    | None -> Lwt.return (Error (Printf.sprintf "Please provide a %s." key))
    | Some value -> Lwt.return (Ok value)
  ;;

  let urlencoded key t =
    let open Lwt.Syntax in
    let* body = t.body |> Body.copy |> Body.to_string in
    urlencoded' body key
  ;;

  let urlencoded2 key1 key2 t =
    let open Lwt_result.Syntax in
    let* body = t.body |> Body.copy |> Body.to_string |> Lwt_result.ok in
    let* value1 = urlencoded' body key1 in
    let+ value2 = urlencoded' body key2 in
    value1, value2
  ;;

  let urlencoded3 key1 key2 key3 t =
    let open Lwt_result.Syntax in
    let* body = t.body |> Body.copy |> Body.to_string |> Lwt_result.ok in
    let* value1 = urlencoded' body key1 in
    let* value2 = urlencoded' body key2 in
    let+ value3 = urlencoded' body key3 in
    value1, value2, value3
  ;;

  let sexp_of_t t =
    Sexplib0.Sexp.(
      List
        [ Pp.sexp_of_version t.version
        ; Pp.sexp_of_target t.target
        ; Pp.sexp_of_headers t.headers
        ; Pp.sexp_of_meth t.meth
        ; Pp.sexp_of_body t.body
        ; Pp.sexp_of_env t.env
        ])
  ;;

  let http_string_of_t t =
    Printf.sprintf
      "%s %s HTTP/%s\n%s\n\n%s\n"
      (Method.to_string t.meth)
      t.target
      (Version.to_string t.version)
      (Headers.to_string t.headers)
      (Body.string_of_t t.body)
  ;;

  let pp_hum fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
  let pp_http fmt t = Format.fprintf fmt "%s\n%!" (http_string_of_t t)
end

module Response = struct
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
    | None -> Lwt.return (Error (Printf.sprintf "Please provide a %s." key))
    | Some value -> Lwt.return (Ok value)
  ;;

  let urlencoded key t =
    let open Lwt.Syntax in
    let* body = t.body |> Body.copy |> Body.to_string in
    urlencoded' body key
  ;;

  let urlencoded2 key1 key2 t =
    let open Lwt_result.Syntax in
    let* body = t.body |> Body.copy |> Body.to_string |> Lwt_result.ok in
    let* value1 = urlencoded' body key1 in
    let+ value2 = urlencoded' body key2 in
    value1, value2
  ;;

  let urlencoded3 key1 key2 key3 t =
    let open Lwt_result.Syntax in
    let* body = t.body |> Body.copy |> Body.to_string |> Lwt_result.ok in
    let* value1 = urlencoded' body key1 in
    let* value2 = urlencoded' body key2 in
    let+ value3 = urlencoded' body key3 in
    value1, value2, value3
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

  let of_string ?version ?status ?reason ?headers ?env body =
    of_string' ?version ?status ?reason ?env ?headers body
  ;;

  let of_html ?version ?status ?reason ?headers ?env body =
    of_string' ~content_type:"text/html" ?version ?status ?reason ?env ?headers body
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

  let sexp_of_t { version; status; reason; headers; body; env } =
    Sexplib0.Sexp.(
      List
        [ Pp.sexp_of_version version
        ; Pp.sexp_of_status status
        ; Pp.sexp_of_reason reason
        ; Pp.sexp_of_headers headers
        ; Pp.sexp_of_body body
        ; Pp.sexp_of_env env
        ])
  ;;

  let http_string_of_t t =
    Printf.sprintf
      "HTTP/%s %s %s\n%s\n\n%s\n"
      (Version.to_string t.version)
      (Status.to_string t.status)
      (Option.value ~default:"" t.reason)
      (Headers.to_string t.headers)
      (Body.string_of_t t.body)
  ;;

  let pp_hum fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
  let pp_http fmt t = Format.fprintf fmt "%s\n%!" (http_string_of_t t)
end

module Handler = struct
  type t = (Request.t, Response.t) Service.t
end

module Middleware = struct
  type t =
    { filter : (Request.t, Response.t) Filter.simple
    ; name : string
    }

  let create ~filter ~name = { filter; name }
  let apply { filter; _ } handler = filter handler
end

module App = struct
  type t =
    { middlewares : Middleware.t list
    ; handler : Handler.t
    }

  let append_middleware t m = { t with middlewares = t.middlewares @ [ m ] }
  let create ?(middlewares = []) ~handler () = { middlewares; handler }
end

exception Halt of Response.t

let halt response = raise (Halt response)
