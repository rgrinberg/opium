let log_src = Logs.Src.create ~doc:"middleware for cookie-based sessions" "opium.session"

module Logs = (val Logs.src_log log_src : Logs.LOG)
module Map = Map.Make (String)

module Session = struct
  type t =
    { data : string Map.t
    ; should_set_cookie : bool
    }

  let create should_set_cookie = { data = Map.empty; should_set_cookie }

  let of_yojson yojson =
    let open Yojson.Safe.Util in
    let session_list =
      try Some (yojson |> to_assoc |> List.map (fun (k, v) -> k, to_string v)) with
      | _ -> None
    in
    session_list
    |> Option.map List.to_seq
    |> Option.map Map.of_seq
    |> Option.map (fun data -> { data; should_set_cookie = false })
  ;;

  let to_yojson { data = session; _ } =
    `Assoc (session |> Map.to_seq |> List.of_seq |> List.map (fun (k, v) -> k, `String v))
  ;;

  let of_json json =
    try of_yojson (Yojson.Safe.from_string json) with
    | _ -> None
  ;;

  let to_json session = session |> to_yojson |> Yojson.Safe.to_string

  let to_sexp session =
    let open Sexplib0.Sexp_conv in
    let open Sexplib0.Sexp in
    let data =
      session.data
      |> Map.to_seq
      |> List.of_seq
      |> sexp_of_list (sexp_of_pair sexp_of_string sexp_of_string)
    in
    List
      [ List [ Atom "data"; data ]
      ; List [ Atom "should_set_cookie"; sexp_of_bool session.should_set_cookie ]
      ]
  ;;
end

module SessionChange = struct
  type t = string option Map.t

  let empty = Map.empty

  let merge Session.{ data = session; should_set_cookie } t =
    let data =
      Map.merge
        (fun _ session change ->
          match session, change with
          | _, Some (Some change) -> Some change
          | _, Some None -> None
          | Some session, None -> Some session
          | None, None -> None)
        session
        t
    in
    Session.{ data; should_set_cookie }
  ;;

  let to_sexp t =
    t
    |> Map.to_seq
    |> List.of_seq
    |> Sexplib0.Sexp_conv.(
         sexp_of_list (sexp_of_pair sexp_of_string (sexp_of_option sexp_of_string)))
  ;;
end

module Env = struct
  let key : Session.t Context.key = Context.Key.create ("session", Session.to_sexp)

  let key_session_change : SessionChange.t Context.key =
    Context.Key.create ("session change", SessionChange.to_sexp)
  ;;
end

exception Session_not_found

let find key req =
  let session =
    try Context.find_exn Env.key req.Request.env with
    | _ ->
      Logs.err (fun m -> m "No session found");
      Logs.info (fun m -> m "Have you applied the session middleware?");
      raise @@ Session_not_found
  in
  Map.find_opt key session.data
;;

let set (key, value) resp =
  let change =
    match Context.find Env.key_session_change resp.Response.env with
    | Some change -> Map.add key value change
    | None -> SessionChange.empty |> Map.add key value
  in
  let env = resp.Response.env in
  let env = Context.add Env.key_session_change change env in
  { resp with env }
;;

let decode_session cookie_key signed_with req =
  match Request.cookie ~signed_with cookie_key req with
  | None -> Session.create true
  | Some cookie_value ->
    (match Session.of_json cookie_value with
    | None ->
      Logs.err (fun m ->
          m
            "Failed to parse value found in session cookie '%s': '%s'"
            cookie_key
            cookie_value);
      Logs.info (fun m ->
          m
            "Maybe the cookie key '%s' collides with a cookie issued by someone else. \
             Try to change the cookie key."
            cookie_key);
      Session.create true
    | Some session -> session)
;;

let persist_session current_session signed_with cookie_key resp =
  let session_change = Context.find Env.key_session_change resp.Response.env in
  let cookie =
    match current_session.Session.should_set_cookie, session_change with
    | true, Some session_change ->
      let session = SessionChange.merge current_session session_change in
      let cookie_value = Session.to_json session in
      Some (cookie_key, cookie_value)
    | true, None ->
      let cookie_value = Session.to_json (Session.create true) in
      Some (cookie_key, cookie_value)
    | false, Some session_change ->
      let session = SessionChange.merge current_session session_change in
      let cookie_value = Session.to_json session in
      Some (cookie_key, cookie_value)
    | false, None -> None
  in
  match cookie with
  | None -> resp
  | Some cookie -> Response.add_cookie_or_replace ~sign_with:signed_with cookie resp
;;

let m ?(cookie_key = "_session") signed_with =
  let open Lwt.Syntax in
  let filter handler req =
    let session = decode_session cookie_key signed_with req in
    let env = req.Request.env in
    let env = Context.add Env.key session env in
    let req = { req with env } in
    let* resp = handler req in
    Lwt.return @@ persist_session session signed_with cookie_key resp
  in
  Rock.Middleware.create ~name:"session" ~filter
;;
