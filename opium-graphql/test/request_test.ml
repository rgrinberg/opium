open Lwt.Infix

let schema =
  Graphql_lwt.Schema.(
    schema
      [ field
          "hello"
          ~typ:(non_null string)
          ~args:Arg.[ arg "name" ~typ:string ]
          ~resolve:(fun _ () -> function
            | None -> "world"
            | Some name -> name)
      ])
;;

let response_check = Alcotest.of_pp Opium.Response.pp_hum

let check_body actual expected =
  Opium.Body.to_string actual >|= fun body -> Alcotest.(check string) "body" body expected
;;

let default_uri = "/"
let json_content_type = Opium.Headers.of_list [ "Content-Type", "application/json" ]
let graphql_content_type = Opium.Headers.of_list [ "Content-Type", "application/graphql" ]

let default_response_body =
  Yojson.Basic.to_string (`Assoc [ "data", `Assoc [ "hello", `String "world" ] ])
;;

let test_case ~req ~rsp =
  Opium_graphql.execute_request schema () req
  >|= fun rsp' -> Alcotest.check response_check "response" rsp' rsp
;;

let suite =
  [ ( "POST with empty body"
    , `Quick
    , fun () ->
        test_case
          ~req:(Opium.Request.make default_uri `POST)
          ~rsp:
            (Opium.Response.of_plain_text
               ~status:`Bad_request
               "Must provide query string") )
  ; ( "POST with json body"
    , `Quick
    , fun () ->
        let body =
          Opium.Body.of_string
            (Yojson.Basic.to_string (`Assoc [ "query", `String "{ hello }" ]))
        in
        test_case
          ~req:(Opium.Request.make ~headers:json_content_type ~body default_uri `POST)
          ~rsp:(Opium.Response.of_plain_text ~status:`OK default_response_body) )
  ; ( "POST with graphql body"
    , `Quick
    , fun () ->
        let body = Opium.Body.of_string "{ hello }" in
        test_case
          ~req:(Opium.Request.make ~headers:graphql_content_type ~body default_uri `POST)
          ~rsp:(Opium.Response.of_plain_text ~status:`OK default_response_body) )
  ; ( "GET with empty query string"
    , `Quick
    , fun () ->
        test_case
          ~req:(Opium.Request.make default_uri `GET)
          ~rsp:
            (Opium.Response.of_plain_text
               ~status:`Bad_request
               "Must provide query string") )
  ; ( "GET with query"
    , `Quick
    , fun () ->
        let query = "{ hello }" in
        let query = Some [ "query", [ query ] ] in
        let uri = Uri.with_uri ~query (Uri.of_string default_uri) in
        test_case
          ~req:(Opium.Request.make (Uri.to_string uri) `GET)
          ~rsp:(Opium.Response.of_plain_text ~status:`OK default_response_body) )
  ; ( "operation name in JSON body"
    , `Quick
    , fun () ->
        let body =
          Opium.Body.of_string
            (Yojson.Basic.to_string
               (`Assoc
                 [ ( "query"
                   , `String
                       "query A { hello(name: \"world\") } query B { hello(name: \
                        \"fail\") }" )
                 ; "operationName", `String "A"
                 ]))
        in
        test_case
          ~req:(Opium.Request.make ~headers:json_content_type ~body default_uri `POST)
          ~rsp:(Opium.Response.of_plain_text ~status:`OK default_response_body) )
  ; ( "operation name in query string"
    , `Quick
    , fun () ->
        let body =
          Opium.Body.of_string
            (Yojson.Basic.to_string
               (`Assoc
                 [ ( "query"
                   , `String
                       "query A { hello(name: \"world\") } query B { hello(name: \
                        \"fail\") }" )
                 ]))
        in
        let query = Some [ "operationName", [ "A" ] ] in
        let uri = Uri.with_uri ~query (Uri.of_string default_uri) in
        test_case
          ~req:
            (Opium.Request.make
               ~headers:json_content_type
               ~body
               (Uri.to_string uri)
               `POST)
          ~rsp:(Opium.Response.of_plain_text ~status:`OK default_response_body) )
  ; ( "variables in JSON body"
    , `Quick
    , fun () ->
        let body =
          Opium.Body.of_string
            (Yojson.Basic.to_string
               (`Assoc
                 [ "query", `String "query A($name: String!) { hello(name: $name) }"
                 ; "variables", `Assoc [ "name", `String "world" ]
                 ]))
        in
        test_case
          ~req:(Opium.Request.make ~headers:json_content_type ~body default_uri `POST)
          ~rsp:(Opium.Response.of_plain_text ~status:`OK default_response_body) )
  ; ( "variables in query string"
    , `Quick
    , fun () ->
        let body =
          Opium.Body.of_string
            (Yojson.Basic.to_string
               (`Assoc
                 [ "query", `String "query A($name: String!) { hello(name: $name) }" ]))
        in
        let query =
          Some [ "operationName", [ "A" ]; "variables", [ "{\"name\":\"world\"}" ] ]
        in
        let uri = Uri.with_uri ~query (Uri.of_string default_uri) in
        test_case
          ~req:
            (Opium.Request.make
               ~headers:json_content_type
               ~body
               (Uri.to_string uri)
               `POST)
          ~rsp:(Opium.Response.of_plain_text ~status:`OK default_response_body) )
  ]
;;

let () = Lwt_main.run @@ Alcotest_lwt.run "opium-graphql" [ "request", suite ]
