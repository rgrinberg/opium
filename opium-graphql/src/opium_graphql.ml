module Option = struct
  include Option

  let bind t ~f =
    match t with
    | None -> None
    | Some x -> f x
  ;;

  let map t ~f = bind t ~f:(fun x -> Some (f x))

  let first_some t t' =
    match t with
    | None -> t'
    | Some _ -> t
  ;;
end

module Params = struct
  type t =
    { query : string option
    ; variables : (string * Yojson.Basic.t) list option
    ; operation_name : string option
    }

  let empty = { query = None; variables = None; operation_name = None }

  let of_uri_exn uri =
    let variables =
      Uri.get_query_param uri "variables"
      |> Option.map ~f:Yojson.Basic.from_string
      |> Option.map ~f:Yojson.Basic.Util.to_assoc
    in
    { query = Uri.get_query_param uri "query"
    ; variables
    ; operation_name = Uri.get_query_param uri "operationName"
    }
  ;;

  let of_json_body_exn body =
    if body = ""
    then empty
    else (
      let json = Yojson.Basic.from_string body in
      { query = Yojson.Basic.Util.(json |> member "query" |> to_option to_string)
      ; variables = Yojson.Basic.Util.(json |> member "variables" |> to_option to_assoc)
      ; operation_name =
          Yojson.Basic.Util.(json |> member "operationName" |> to_option to_string)
      })
  ;;

  let of_graphql_body body =
    { query = Some body; variables = None; operation_name = None }
  ;;

  let merge t t' =
    { query = Option.first_some t.query t'.query
    ; variables = Option.first_some t.variables t'.variables
    ; operation_name = Option.first_some t.operation_name t'.operation_name
    }
  ;;

  let post_params_exn req body =
    let headers = req.Opium.Request.headers in
    match Httpaf.Headers.get headers "Content-Type" with
    | Some "application/graphql" -> of_graphql_body body
    | Some "application/json" -> of_json_body_exn body
    | _ -> empty
  ;;

  let of_req_exn req body =
    let get_params = req.Opium.Request.target |> Uri.of_string |> of_uri_exn in
    let post_params = post_params_exn req body in
    merge get_params post_params
  ;;

  let extract req body =
    try
      let params = of_req_exn req body in
      match params.query with
      | Some query ->
        Ok
          ( query
          , (params.variables :> (string * Graphql_parser.const_value) list option)
          , params.operation_name )
      | None -> Error "Must provide query string"
    with
    | Yojson.Json_error msg -> Error msg
  ;;
end

module Schema = Graphql_lwt.Schema

let ( >>= ) = Lwt.( >>= )

let respond_string ~status ~body () =
  Lwt.return (Opium.Response.of_plain_text ~status body)
;;

let execute_query ctx schema variables operation_name query =
  match Graphql_parser.parse query with
  | Ok doc -> Schema.execute schema ctx ?variables ?operation_name doc
  | Error e -> Lwt.return (Error (`String e))
;;

let execute_request schema ctx req =
  Opium.Body.to_string req.Opium.Request.body
  >>= fun body_string ->
  match Params.extract req body_string with
  | Error err -> respond_string ~status:`Bad_request ~body:err ()
  | Ok (query, variables, operation_name) ->
    execute_query ctx schema variables operation_name query
    >>= (function
    | Ok (`Response data) ->
      let body = Yojson.Basic.to_string data in
      respond_string ~status:`OK ~body ()
    | Ok (`Stream stream) ->
      Graphql_lwt.Schema.Io.Stream.close stream;
      let body = "Subscriptions are only supported via websocket transport" in
      respond_string ~status:`Bad_request ~body ()
    | Error err ->
      let body = Yojson.Basic.to_string err in
      respond_string ~status:`Bad_request ~body ())
;;

let make_handler ?(make_context = fun _req -> ()) schema req =
  match req.Opium.Request.meth with
  | `GET ->
    if Httpaf.Headers.get req.Opium.Request.headers "Connection" = Some "Upgrade"
       && Httpaf.Headers.get req.Opium.Request.headers "Upgrade" = Some "websocket"
    then
      (* TODO: Add subscription support when there is a good solution for websockets with
         Httpaf *)
      respond_string
        ~status:`Internal_server_error
        ~body:"Subscriptions are not supported (yet)"
        ()
    else execute_request schema (make_context req) req
  | `POST -> execute_request schema (make_context req) req
  | _ -> respond_string ~status:`Not_found ~body:"" ()
;;

let graphiql_etag =
  Asset.read "graphiql.html"
  |> Option.get
  |> Cstruct.of_string
  |> Mirage_crypto.Hash.digest `MD5
  |> Cstruct.to_string
  |> Base64.encode_exn
;;

let graphiql_handler ~graphql_endpoint req =
  let accept_html =
    match Httpaf.Headers.get req.Opium.Request.headers "accept" with
    | None -> false
    | Some s -> List.mem "text/html" (String.split_on_char ',' s)
  in
  let h =
    Opium.Handler.serve
      ~etag:graphiql_etag
      ~mime_type:"text/html; charset=utf-8"
      (fun () ->
        match Asset.read "graphiql.html" with
        | None -> Lwt.return_error `Internal_server_error
        | Some body ->
          let regexp = Str.regexp_string "%%GRAPHQL_API%%" in
          let body = Str.global_replace regexp graphql_endpoint body in
          Lwt.return_ok (Opium.Body.of_string body))
  in
  if accept_html
  then h req
  else respond_string ~status:`Bad_request ~body:"Clients must accept text/html" ()
;;
