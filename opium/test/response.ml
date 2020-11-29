open Alcotest
open Opium

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

let response = Alcotest.of_pp Opium.Response.pp
let cookie = Alcotest.of_pp Opium.Cookie.pp

let check_cookie ?msg expected t =
  let message =
    match msg with
    | Some msg -> msg
    | None -> "cookies are equal"
  in
  Alcotest.check cookie message expected t
;;

let check_response ?msg expected t =
  let message =
    match msg with
    | Some msg -> msg
    | None -> "responses are equal"
  in
  Alcotest.check response message expected t
;;

let () =
  run_quick
    "Response"
    [ ( "cookie"
      , [ ( "returns the cookie with the matching key"
          , fun () ->
              let response =
                Response.make () |> Response.add_cookie ("cookie", "value")
              in
              let cookie_value = Response.cookie "cookie" response |> Option.get in
              check_cookie (Cookie.make ("cookie", "value")) cookie_value )
        ; ( "returns the cookie with the matching key and same signature"
          , fun () ->
              let response =
                Response.make ()
                |> Response.add_cookie ~sign_with:signer ("cookie", "value")
              in
              let cookie_value =
                Response.cookie ~signed_with:signer "cookie" response |> Option.get
              in
              check_cookie (Cookie.make ("cookie", "value")) cookie_value )
        ; ( "does not return a cookie if the signatures don't match"
          , fun () ->
              let response =
                Response.make ()
                |> Response.add_cookie ~sign_with:signer ("cookie", "value")
              in
              let cookie_value =
                Response.cookie ~signed_with:signer_2 "cookie" response
              in
              check (option cookie) "cookie is None" None cookie_value )
        ; ( "does not return a cookie if the response does not have a Cookie header"
          , fun () ->
              let response = Response.make () in
              let cookie_value = Response.cookie "cookie" response in
              check (option cookie) "cookie is None" None cookie_value )
        ] )
    ; ( "cookies"
      , [ ( "returns all the cookies of the response"
          , fun () ->
              let response =
                Response.make ()
                |> Response.add_cookie ("cookie", "value")
                |> Response.add_cookie ~sign_with:signer ("signed_cookie", "value2")
                |> Response.add_cookie ("cookie2", "value3")
              in
              let cookies = Response.cookies response in
              check
                (list cookie)
                "cookies are the same"
                [ Cookie.make ("cookie", "value")
                ; Cookie.make ("signed_cookie", "value2.duQApNVJrAZ2a/dMYQUN3zzSBrk=")
                ; Cookie.make ("cookie2", "value3")
                ]
                cookies )
        ; ( "does not return the cookies with invalid signatures"
          , fun () ->
              let response =
                Response.make ()
                |> Response.add_cookie ("cookie", "value")
                |> Response.add_cookie ~sign_with:signer ("signed_cookie", "value2")
                |> Response.add_cookie ~sign_with:signer_2 ("cookie2", "value3")
              in
              let cookies = Response.cookies ~signed_with:signer response in
              check
                (list cookie)
                "cookies are the same"
                [ Cookie.make ("signed_cookie", "value2") ]
                cookies )
        ] )
    ; ( "add_cookie"
      , [ ( "adds a cookie to the response"
          , fun () ->
              let response =
                Response.make () |> Response.add_cookie ("cookie", "value")
              in
              check_response
                (Response.make
                   ()
                   ~headers:(Headers.of_list [ "Set-Cookie", "cookie=value" ]))
                response )
        ; ( "does not replace the value of an existing cookie"
          , fun () ->
              let response =
                Response.make ()
                |> Response.add_cookie ("cookie", "value")
                |> Response.add_cookie ("cookie", "value2")
              in
              check_response
                (Response.make
                   ()
                   ~headers:
                     (Headers.of_list
                        [ "Set-Cookie", "cookie=value"; "Set-Cookie", "cookie=value2" ]))
                response )
        ] )
    ; ( "add_cookie_or_replace"
      , [ ( "adds a cookie to the response"
          , fun () ->
              let response =
                Response.make () |> Response.add_cookie_or_replace ("cookie", "value")
              in
              check_response
                (Response.make
                   ()
                   ~headers:(Headers.of_list [ "Set-Cookie", "cookie=value" ]))
                response )
        ; ( "replaces the value of an existing cookie"
          , fun () ->
              let response =
                Response.make ()
                |> Response.add_cookie_or_replace ("cookie", "value")
                |> Response.add_cookie_or_replace ("cookie", "value2")
              in
              check_response
                (Response.make
                   ()
                   ~headers:(Headers.of_list [ "Set-Cookie", "cookie=value2" ]))
                response )
        ] )
    ; ( "add_cookie_unless_exists"
      , [ ( "adds a cookie to the response"
          , fun () ->
              let response =
                Response.make () |> Response.add_cookie_unless_exists ("cookie", "value")
              in
              check_response
                (Response.make
                   ()
                   ~headers:(Headers.of_list [ "Set-Cookie", "cookie=value" ]))
                response )
        ; ( "does not add a cookie to the response if the same key exists"
          , fun () ->
              let response =
                Response.make ()
                |> Response.add_cookie ("cookie", "value")
                |> Response.add_cookie_unless_exists ("cookie", "value2")
              in
              check_response
                (Response.make
                   ()
                   ~headers:(Headers.of_list [ "Set-Cookie", "cookie=value" ]))
                response )
        ] )
    ; ( "remove_cookie"
      , [ ( "removes a cookie from the response"
          , fun () ->
              let response =
                Response.make ()
                |> Response.add_cookie ("cookie", "value")
                |> Response.add_cookie ("cookie2", "value2")
                |> Response.remove_cookie "cookie2"
              in
              check_response
                (Response.make
                   ()
                   ~headers:
                     (Headers.of_list
                        [ "Set-Cookie", "cookie=value"
                        ; "Set-Cookie", "cookie2=; Max-Age=0"
                        ]))
                response )
        ] )
    ]
;;
