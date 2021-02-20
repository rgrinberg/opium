let log_src =
  Logs.Src.create ~doc:"Opium middleware for cookie-based sessions" "opium.session"
;;

module Logs = (val Logs.src_log log_src : Logs.LOG)
module Map = Map.Make (String)

module Session = struct
  type t = string Map.t

  let empty = Map.empty

  let of_yojson yojson =
    let open Yojson.Safe.Util in
    let session_list =
      try Some (yojson |> to_assoc |> List.map (fun (k, v) -> k, to_string v)) with
      | _ -> None
    in
    session_list |> Option.map List.to_seq |> Option.map Map.of_seq
  ;;

  let to_yojson session =
    `Assoc (session |> Map.to_seq |> List.of_seq |> List.map (fun (k, v) -> k, `String v))
  ;;

  let of_json json =
    try of_yojson (Yojson.Safe.from_string json) with
    | _ -> None
  ;;

  let to_json session = session |> to_yojson |> Yojson.Safe.to_string

  let to_sexp session =
    session
    |> Map.to_seq
    |> List.of_seq
    |> Sexplib0.Sexp_conv.(sexp_of_list (sexp_of_pair sexp_of_string sexp_of_string))
  ;;
end

module Env = struct
  let key : Session.t Context.key = Context.Key.create ("session", Session.to_sexp)
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
  Map.find_opt key session
;;

let set (key, value) resp =
  let session =
    try Context.find_exn Env.key resp.Response.env with
    | _ ->
      Logs.err (fun m -> m "No session found");
      Logs.info (fun m -> m "Have you applied the session middleware?");
      raise Session_not_found
  in
  let updated_session =
    match value with
    | None -> Map.remove key session
    | Some value -> Map.add key value session
  in
  let env = resp.Response.env in
  let env = Context.add Env.key updated_session env in
  { resp with env }
;;

let persist_session signed_with cookie_key resp =
  let session = Context.find Env.key resp.Response.env in
  match session with
  | None -> (* No need to touch the session cookie *) resp
  | Some session ->
    (* The session changed, we need to persist the new session in the cookie *)
    let cookie_value = Session.to_json session in
    let cookie = cookie_key, cookie_value in
    let resp = Response.add_cookie_or_replace ~sign_with:signed_with cookie resp in
    resp
;;

let m ?(cookie_key = "_session") signed_with =
  let open Lwt.Syntax in
  let filter handler req =
    let session =
      match Request.cookie ~signed_with cookie_key req with
      | None -> Session.empty
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
                "Maybe the cookie key '%s' collides with a cookie issued by someone \
                 else. Try to change the cookie key."
                cookie_key);
          Session.empty
        | Some session -> session)
    in
    let env = req.Request.env in
    let env = Context.add Env.key session env in
    let req = { req with env } in
    let* resp = handler req in
    Lwt.return @@ persist_session signed_with cookie_key resp
  in
  Rock.Middleware.create ~name:"Session" ~filter
;;
