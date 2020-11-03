open Opium

let request = Alcotest.of_pp Request.pp_hum
let response = Alcotest.of_pp Response.pp_hum

let with_service ?middlewares ?handler f =
  let handler =
    Option.value handler ~default:(fun _req -> Lwt.return @@ Response.make ())
  in
  let middlewares = Option.value middlewares ~default:[] in
  let app = Rock.App.create ~middlewares ~handler () in
  let { Rock.App.middlewares; handler } = app in
  let filters = ListLabels.map ~f:(fun m -> m.Rock.Middleware.filter) middlewares in
  let service = Rock.Filter.apply_all filters handler in
  f service
;;

let check_response ?headers ?status res =
  let expected = Response.make ?status ?headers:(Option.map Headers.of_list headers) () in
  Alcotest.(check response) "same response" expected res
;;

let test_regular_request () =
  let open Lwt.Syntax in
  let+ res =
    with_service ~middlewares:[ Middleware.allow_cors () ] (fun service ->
        let req = Request.make "/" `GET in
        service req)
  in
  check_response
    ~headers:
      [ "access-control-allow-origin", "*"
      ; "access-control-expose-headers", ""
      ; "access-control-allow-credentials", "true"
      ]
    res
;;

let test_overwrite_origin () =
  let open Lwt.Syntax in
  let+ res =
    with_service
      ~middlewares:[ Middleware.allow_cors ~origins:[ "http://example.com" ] () ]
      (fun service ->
        let req =
          Request.make
            "/"
            `GET
            ~headers:(Headers.of_list [ "origin", "http://example.com" ])
        in
        service req)
  in
  check_response
    ~headers:
      [ "access-control-allow-origin", "http://example.com"
      ; "access-control-expose-headers", ""
      ; "access-control-allow-credentials", "true"
      ; "vary", "Origin"
      ]
    res
;;

let test_return_204_for_options () =
  let open Lwt.Syntax in
  let+ res =
    with_service ~middlewares:[ Middleware.allow_cors () ] (fun service ->
        let req = Request.make "/" `OPTIONS in
        service req)
  in
  check_response
    ~status:`No_content
    ~headers:
      [ "access-control-allow-origin", "*"
      ; "access-control-expose-headers", ""
      ; "access-control-allow-credentials", "true"
      ; "access-control-max-age", "1728000"
      ; "access-control-allow-methods", "GET,POST,PUT,DELETE,OPTIONS,PATCH"
      ; ( "access-control-allow-headers"
        , "Authorization,Content-Type,Accept,Origin,User-Agent,DNT,Cache-Control,X-Mx-ReqToken,Keep-Alive,X-Requested-With,If-Modified-Since,X-CSRF-Token"
        )
      ]
    res
;;

let test_allow_request_headers () =
  let open Lwt.Syntax in
  let+ res =
    with_service
      ~middlewares:[ Middleware.allow_cors ~headers:[ "*" ] () ]
      (fun service ->
        let req =
          Request.make
            "/"
            `OPTIONS
            ~headers:
              (Headers.of_list [ "access-control-request-headers", "header-1,header-2" ])
        in
        service req)
  in
  check_response
    ~status:`No_content
    ~headers:
      [ "access-control-allow-origin", "*"
      ; "access-control-expose-headers", ""
      ; "access-control-allow-credentials", "true"
      ; "access-control-max-age", "1728000"
      ; "access-control-allow-methods", "GET,POST,PUT,DELETE,OPTIONS,PATCH"
      ; "access-control-allow-headers", "header-1,header-2"
      ]
    res
;;

let () =
  Lwt_main.run
  @@ Alcotest_lwt.run
       "Middleware :: Allow CORS"
       [ ( "headers"
         , [ "Regular request returns correct headers", `Quick, test_regular_request
           ; "Overwrites origin header", `Quick, test_overwrite_origin
           ; "Allow incoming request headers", `Quick, test_allow_request_headers
           ; ( "Returns No Content for OPTIONS requests"
             , `Quick
             , test_return_204_for_options )
           ] )
       ]
;;
