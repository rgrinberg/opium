let headers = [ "Cookie", "yummy_cookie=choco; tasty_cookie=strawberry" ]

let parse_cookies_of_headers () =
  let c1, c2 =
    match Opium.Cookie.cookies_of_headers headers with
    | [ c1; c2 ] -> c1, c2
    | _ -> failwith "Unexpected number of cookies parsed"
  in
  Alcotest.(check (pair string string) "has cookie" ("yummy_cookie", "choco") c1);
  Alcotest.(check (pair string string) "has cookie" ("tasty_cookie", "strawberry") c2);
  ()
;;

let find_cookie_in_headers () =
  let cookie = Opium.Cookie.cookie_of_headers "tasty_cookie" headers in
  Alcotest.(
    check
      (option (pair string string))
      "has cookie"
      (Some ("tasty_cookie", "strawberry"))
      cookie)
;;

let () =
  Alcotest.run
    "Cookie"
    [ ( "parse"
      , [ "test parse cookies of headers", `Quick, parse_cookies_of_headers
        ; "test find cookie in headers", `Quick, find_cookie_in_headers
        ] )
    ]
;;
