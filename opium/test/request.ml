open Alcotest
open Opium
open Opium_testing

let test_case n = test_case n `Quick

let run_quick n l =
  Alcotest.run
    n
    (ListLabels.map l ~f:(fun (n, l) ->
         n, ListLabels.map l ~f:(fun (n, el) -> Alcotest.test_case n `Quick el)))
;;

let signer =
  Cookie.Signer.make "6qWiqeLJqZC/UrpcTLIcWOS/35SrCPzWskO/bDkIXBGH9fCXrDphsBj4afqigTKe"
;;

let signer_2 =
  Cookie.Signer.make "Qp0d+6wRcos7rsuEPxGWNlaKRERh7GYrzMrG8DB3aqrFkFN69TFBrF0n0TbYUq9t"
;;

let () =
  run_quick
    "Request"
    [ ( "cookie"
      , [ ( "returns the cookie with the matching key"
          , fun () ->
              let request = Request.get "/" |> Request.add_cookie ("cookie", "value") in
              let cookie_value = Request.cookie "cookie" request |> Option.get in
              check string "same values" "value" cookie_value )
        ; ( "returns the cookie with the matching key and same signature"
          , fun () ->
              let request =
                Request.get "/" |> Request.add_cookie ~sign_with:signer ("cookie", "value")
              in
              let cookie_value =
                Request.cookie ~signed_with:signer "cookie" request |> Option.get
              in
              check string "same values" "value" cookie_value )
        ; ( "does not return a cookie if the signatures don't match"
          , fun () ->
              let request =
                Request.get "/" |> Request.add_cookie ~sign_with:signer ("cookie", "value")
              in
              let cookie_value = Request.cookie ~signed_with:signer_2 "cookie" request in
              check (option string) "cookie is None" None cookie_value )
        ; ( "does not return a cookie if the request does not have a Cookie header"
          , fun () ->
              let request = Request.get "/" in
              let cookie_value = Request.cookie "cookie" request in
              check (option string) "cookie is None" None cookie_value )
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
                cookies )
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
                cookies )
        ] )
    ; ( "add_cookie"
      , [ ( "adds a cookie to the request"
          , fun () ->
              let request = Request.get "/" |> Request.add_cookie ("cookie", "value") in
              check_request
                (Request.get "/" ~headers:(Headers.of_list [ "Cookie", "cookie=value" ]))
                request )
        ; ( "replaces the value of an existing cookie"
          , fun () ->
              let request =
                Request.get "/"
                |> Request.add_cookie ("cookie", "value")
                |> Request.add_cookie ("cookie", "value2")
              in
              check_request
                (Request.get "/" ~headers:(Headers.of_list [ "Cookie", "cookie=value2" ]))
                request )
        ] )
    ; ( "add_cookie_unless_exists"
      , [ ( "adds a cookie to the request"
          , fun () ->
              let request =
                Request.get "/" |> Request.add_cookie_unless_exists ("cookie", "value")
              in
              check_request
                (Request.get "/" ~headers:(Headers.of_list [ "Cookie", "cookie=value" ]))
                request )
        ; ( "does not add a cookie to the request if the same key exists"
          , fun () ->
              let request =
                Request.get "/"
                |> Request.add_cookie ("cookie", "value")
                |> Request.add_cookie_unless_exists ("cookie", "value2")
              in
              check_request
                (Request.get "/" ~headers:(Headers.of_list [ "Cookie", "cookie=value" ]))
                request )
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
                request )
        ] )
    ]
;;
