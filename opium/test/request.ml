open Alcotest
open Alcotest_lwt
open Opium
open Lwt.Syntax

let test_case n f = test_case n `Quick (fun _switch () -> f ())

let run_quick n l =
  Lwt_main.run
  @@ Alcotest_lwt.run
       n
       (ListLabels.map l ~f:(fun (n, l) ->
            n, ListLabels.map l ~f:(fun (n, el) -> test_case n el)))
;;

let signer =
  Cookie.Signer.make "6qWiqeLJqZC/UrpcTLIcWOS/35SrCPzWskO/bDkIXBGH9fCXrDphsBj4afqigTKe"
;;

let signer_2 =
  Cookie.Signer.make "Qp0d+6wRcos7rsuEPxGWNlaKRERh7GYrzMrG8DB3aqrFkFN69TFBrF0n0TbYUq9t"
;;

let check_request ?msg expected t =
  let message =
    match msg with
    | Some msg -> msg
    | None -> "requests are equal"
  in
  Alcotest.check (Alcotest.of_pp Opium.Request.pp) message expected t
;;

let () =
  run_quick
    "Request"
    [ ( "urlencoded_list"
      , [ ( "returns the list of urlencoded values matching key"
          , fun () ->
              let request =
                Request.of_urlencoded
                  ~body:
                    [ "key1", [ "value1-1" ]
                    ; "key2", [ "value2-1" ]
                    ; "key2", [ "value2-2" ]
                    ]
                  "/"
                  `GET
              in
              let* value1 = Request.urlencoded_list "key1" request in
              let+ value2 = Request.urlencoded_list "key2" request in
              check (list string) "same values" [ "value1-1" ] value1;
              check (list string) "same values" [ "value2-1"; "value2-2" ] value2 )
        ] )
    ; ( "cookie"
      , [ ( "returns the cookie with the matching key"
          , fun () ->
              let request = Request.get "/" |> Request.add_cookie ("cookie", "value") in
              let cookie_value = Request.cookie "cookie" request |> Option.get in
              check string "same values" "value" cookie_value;
              Lwt.return () )
        ; ( "returns the cookie with the matching key and same signature"
          , fun () ->
              let request =
                Request.get "/" |> Request.add_cookie ~sign_with:signer ("cookie", "value")
              in
              let cookie_value =
                Request.cookie ~signed_with:signer "cookie" request |> Option.get
              in
              check string "same values" "value" cookie_value;
              Lwt.return () )
        ; ( "does not return a cookie if the signatures don't match"
          , fun () ->
              let request =
                Request.get "/" |> Request.add_cookie ~sign_with:signer ("cookie", "value")
              in
              let cookie_value = Request.cookie ~signed_with:signer_2 "cookie" request in
              check (option string) "cookie is None" None cookie_value;
              Lwt.return () )
        ; ( "does not return a cookie if the request does not have a Cookie header"
          , fun () ->
              let request = Request.get "/" in
              let cookie_value = Request.cookie "cookie" request in
              check (option string) "cookie is None" None cookie_value;
              Lwt.return () )
        ] )
    ; ( "cookies"
      , [ ( "returns all the cookies of the request"
          , fun () ->
              let request =
                Request.get "/"
                |> Request.add_cookie ("cookie", "value")
                |> Request.add_cookie ~sign_with:signer ("signed_cookie", "value2")
                |> Request.add_cookie ("cookie2", "value3")
              in
              let cookies = Request.cookies request in
              check
                (list (pair string string))
                "cookies are the same"
                [ "cookie", "value"
                ; "signed_cookie", "value2.duQApNVJrAZ2a/dMYQUN3zzSBrk="
                ; "cookie2", "value3"
                ]
                cookies;
              Lwt.return () )
        ; ( "does not return the cookies with invalid signatures"
          , fun () ->
              let request =
                Request.get "/"
                |> Request.add_cookie ("cookie", "value")
                |> Request.add_cookie ~sign_with:signer ("signed_cookie", "value2")
                |> Request.add_cookie ~sign_with:signer_2 ("cookie2", "value3")
              in
              let cookies = Request.cookies ~signed_with:signer request in
              check
                (list (pair string string))
                "cookies are the same"
                [ "signed_cookie", "value2" ]
                cookies;
              Lwt.return () )
        ] )
    ; ( "add_cookie"
      , [ ( "adds a cookie to the request"
          , fun () ->
              let request = Request.get "/" |> Request.add_cookie ("cookie", "value") in
              check_request
                (Request.get "/" ~headers:(Headers.of_list [ "Cookie", "cookie=value" ]))
                request;
              Lwt.return () )
        ; ( "replaces the value of an existing cookie"
          , fun () ->
              let request =
                Request.get "/"
                |> Request.add_cookie ("cookie", "value")
                |> Request.add_cookie ("cookie", "value2")
              in
              check_request
                (Request.get "/" ~headers:(Headers.of_list [ "Cookie", "cookie=value2" ]))
                request;
              Lwt.return () )
        ] )
    ; ( "add_cookie_unless_exists"
      , [ ( "adds a cookie to the request"
          , fun () ->
              let request =
                Request.get "/" |> Request.add_cookie_unless_exists ("cookie", "value")
              in
              check_request
                (Request.get "/" ~headers:(Headers.of_list [ "Cookie", "cookie=value" ]))
                request;
              Lwt.return () )
        ; ( "does not add a cookie to the request if the same key exists"
          , fun () ->
              let request =
                Request.get "/"
                |> Request.add_cookie ("cookie", "value")
                |> Request.add_cookie_unless_exists ("cookie", "value2")
              in
              check_request
                (Request.get "/" ~headers:(Headers.of_list [ "Cookie", "cookie=value" ]))
                request;
              Lwt.return () )
        ] )
    ; ( "remove_cookie"
      , [ ( "removes a cookie from the request"
          , fun () ->
              let request =
                Request.get "/"
                |> Request.add_cookie ("cookie", "value")
                |> Request.add_cookie ("cookie2", "value2")
                |> Request.remove_cookie "cookie2"
              in
              check_request
                (Request.get "/" ~headers:(Headers.of_list [ "Cookie", "cookie=value" ]))
                request;
              Lwt.return () )
        ] )
    ]
;;
