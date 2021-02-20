open Alcotest_lwt
open Lwt.Syntax

let signer = Opium.Cookie.Signer.make "secret"

let unsigned_session_cookie _ () =
  let middleware = Opium.Middleware.cookie_session signer in
  let req =
    Opium.Request.get ""
    (* default empty session with default test secret *)
    |> Opium.Request.add_cookie ("_session", "{}")
  in
  let handler _ =
    (* We don't set any session values *)
    Lwt.return @@ Opium.Response.of_plain_text ""
  in
  let* response = Rock.Middleware.apply middleware handler req in
  let cookie = Opium.Response.cookies response |> List.hd in
  let cookie_value = cookie.Opium.Cookie.value in
  (* Unsigned cookie fails silently, new session is started *)
  Alcotest.(
    check
      (pair string string)
      "responds with empty cookie"
      ("_session", "{}.byiLJwVqMzg39fb251SaoN+19fo=")
      cookie_value);
  Lwt.return ()
;;

let invalid_session_cookie_signature _ () =
  let middleware = Opium.Middleware.cookie_session signer in
  let req =
    Opium.Request.get ""
    (* default empty session with default test secret *)
    |> Opium.Request.add_cookie ("_session", "{}.ayiLJwVqMzg39fb251SaoN+19fo=")
  in
  let handler _ =
    (* We don't set any session values *)
    Lwt.return @@ Opium.Response.of_plain_text ""
  in
  let* response = Rock.Middleware.apply middleware handler req in
  let cookie = Opium.Response.cookies response |> List.hd in
  let cookie_value = cookie.Opium.Cookie.value in
  (* Invalid signature fails silently, new session is started *)
  Alcotest.(
    check
      (pair string string)
      "responds with empty cookie"
      ("_session", "{}.byiLJwVqMzg39fb251SaoN+19fo=")
      cookie_value);
  Lwt.return ()
;;

let invalid_session_cookie_value _ () =
  let middleware = Opium.Middleware.cookie_session signer in
  let req =
    Opium.Request.get ""
    (* default empty session with default test secret *)
    |> Opium.Request.add_cookie
         ("_session", "invalid content.byiLJwVqMzg39fb251SaoN+19fo=")
  in
  let handler _ =
    (* We don't set any session values *)
    Lwt.return @@ Opium.Response.of_plain_text ""
  in
  let* response = Rock.Middleware.apply middleware handler req in
  let cookie = Opium.Response.cookies response |> List.hd in
  let cookie_value = cookie.Opium.Cookie.value in
  (* Invalid cookie value fails silently, new session is started *)
  Alcotest.(
    check
      (pair string string)
      "responds with empty cookie"
      ("_session", "{}.byiLJwVqMzg39fb251SaoN+19fo=")
      cookie_value);
  Lwt.return ()
;;

let no_empty_cookie_set_if_already_present _ () =
  let middleware = Opium.Middleware.cookie_session signer in
  let req =
    Opium.Request.get ""
    (* default empty session with default test secret *)
    |> Opium.Request.add_cookie ("_session", "{}.byiLJwVqMzg39fb251SaoN+19fo=")
  in
  let handler _ =
    (* We don't set any session values *)
    Lwt.return @@ Opium.Response.of_plain_text ""
  in
  let* response = Rock.Middleware.apply middleware handler req in
  let cookies = Opium.Response.cookies response in
  Alcotest.(check int "responds without cookie" 0 (List.length cookies));
  Lwt.return ()
;;

let empty_cookie_set _ () =
  let middleware = Opium.Middleware.cookie_session signer in
  let req = Opium.Request.get "" in
  let handler _ =
    (* We don't set any session values *)
    Lwt.return @@ Opium.Response.of_plain_text ""
  in
  let* response = Rock.Middleware.apply middleware handler req in
  let cookies = Opium.Response.cookies response in
  Alcotest.(check int "responds with one cookie" 1 (List.length cookies));
  let cookie = Opium.Response.cookie "_session" response |> Option.get in
  Alcotest.(
    check
      (pair string string)
      "has empty content"
      (* default empty session with default test secret *)
      ("_session", "{}.byiLJwVqMzg39fb251SaoN+19fo=")
      cookie.Opium.Cookie.value);
  Lwt.return ()
;;

let cookie_set _ () =
  let middleware = Opium.Middleware.cookie_session signer in
  let req = Opium.Request.get "" in
  let handler _ =
    let resp = Opium.Response.of_plain_text "" in
    Lwt.return @@ Opium.Session.set ("foo", Some "bar") resp
  in
  let* response = Rock.Middleware.apply middleware handler req in
  let cookie = Opium.Response.cookies response |> List.hd in
  let cookie_value = cookie.Opium.Cookie.value in
  Alcotest.(
    check
      (pair string string)
      "persists session values"
      ("_session", {|{"foo":"bar"}.jE75kXj9sbZp6tP7oJLhrp9c/+w=|})
      cookie_value);
  Lwt.return ()
;;

let session_persisted_across_requests _ () =
  let middleware = Opium.Middleware.cookie_session signer in
  let req = Opium.Request.get "" in
  let handler _ =
    let resp = Opium.Response.of_plain_text "" in
    Lwt.return @@ Opium.Session.set ("foo", Some "bar") resp
  in
  let* response = Rock.Middleware.apply middleware handler req in
  let cookies = Opium.Response.cookies response in
  Alcotest.(check int "responds with exactly one cookie" 1 (List.length cookies));
  let cookie = Opium.Response.cookie "_session" response |> Option.get in
  let cookie_value = cookie.Opium.Cookie.value in
  Alcotest.(
    check
      (pair string string)
      "persists session values"
      ("_session", {|{"foo":"bar"}.jE75kXj9sbZp6tP7oJLhrp9c/+w=|})
      cookie_value);
  let req = Opium.Request.get "" |> Opium.Request.add_cookie cookie.Opium.Cookie.value in
  let handler req =
    let session_value = Opium.Session.find "foo" req in
    Alcotest.(check (option string) "has session value" (Some "bar") session_value);
    let resp =
      Opium.Response.of_plain_text ""
      |> Opium.Session.set ("foo", None)
      |> Opium.Session.set ("fooz", Some "other")
    in
    Lwt.return resp
  in
  let* response = Rock.Middleware.apply middleware handler req in
  let cookies = Opium.Response.cookies response in
  Alcotest.(check int "responds with exactly one cookie" 1 (List.length cookies));
  let cookie = Opium.Response.cookie "_session" response |> Option.get in
  let cookie_value = cookie.Opium.Cookie.value in
  Alcotest.(
    check
      (pair string string)
      "persists session values"
      ("_session", {|{"fooz":"other"}.VRJU0/vmwzPLrDU0zulQ7MojZUU=|})
      cookie_value);
  let req = Opium.Request.get "" |> Opium.Request.add_cookie cookie.Opium.Cookie.value in
  let handler req =
    Alcotest.(
      check
        (option string)
        "has deleted session value"
        None
        (Opium.Session.find "foo" req));
    Alcotest.(
      check
        (option string)
        "has set session value"
        (Some "other")
        (Opium.Session.find "fooz" req));
    Lwt.return @@ Opium.Response.of_plain_text ""
  in
  let* _ = Rock.Middleware.apply middleware handler req in
  Lwt.return ()
;;

let suite =
  [ ( "session"
    , [ test_case "unsigned session cookie" `Quick unsigned_session_cookie
      ; test_case
          "invalid session cookie signature"
          `Quick
          invalid_session_cookie_signature
      ; test_case "invalid session cookie value" `Quick invalid_session_cookie_value
      ; test_case
          "no empty cookie set if already present"
          `Quick
          no_empty_cookie_set_if_already_present
      ; test_case "empty cookie set" `Quick empty_cookie_set
      ; test_case "cookie set" `Quick cookie_set
      ; test_case
          "session persisted across requests"
          `Quick
          session_persisted_across_requests
      ] )
  ]
;;

let () = Lwt_main.run (Alcotest_lwt.run "session" suite)
