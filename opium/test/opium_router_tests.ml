open Sexplib0
module Router = Opium.Private.Router
open Router

let valid_route s =
  match Route.of_string_result s with
  | Error err -> print_endline ("[FAIL] invalid route " ^ err)
  | Ok r -> Format.printf "[PASS] valid route:%a@." Sexp.pp_hum (Route.sexp_of_t r)
;;

let%expect_test "nil route" =
  valid_route "/";
  [%expect {|
    [PASS] valid route:Nil |}]
;;

let%expect_test "literal route" =
  valid_route "/foo/bar";
  [%expect {|
    [PASS] valid route:(foo (bar Nil)) |}]
;;

let%expect_test "named parameters valid" =
  valid_route "/foo/:param/:another";
  [%expect {|
    [PASS] valid route:(foo (:param (:another Nil))) |}]
;;

let%expect_test "unnamed parameter valid" =
  valid_route "/foo/*";
  [%expect {|
    [PASS] valid route:(foo (* Nil)) |}]
;;

let%expect_test "param followed by literal" =
  valid_route "/foo/*/bar/:param/bar";
  [%expect {|
    [PASS] valid route:(foo (* (bar (:param (bar Nil))))) |}]
;;

let%expect_test "duplicate paramters" =
  valid_route "/foo/:bar/:bar/x";
  [%expect {|
    [FAIL] invalid route duplicate parameter "bar" |}]
;;

let%expect_test "splat in the middle is wrong" =
  valid_route "/foo/**/foo";
  [%expect {|
    [FAIL] invalid route double splat allowed only in the end |}]
;;

let%expect_test "splat at the end" =
  valid_route "/foo/**";
  [%expect {|
    [PASS] valid route:(foo Full_splat) |}]
;;

let test_match_url router url =
  match Router.match_url router url with
  | None -> print_endline "no match"
  | Some (_, p) ->
    Format.printf "matched with params: %a@." Sexp.pp_hum (Params.sexp_of_t p)
;;

let%expect_test "dummy router matches nothing" =
  test_match_url empty "/foo/123";
  [%expect {|
    no match |}]
;;

let%expect_test "we can add & match literal routes" =
  let url = "/foo/bar" in
  let route = Route.of_string url in
  let router = add empty route () in
  test_match_url router url;
  [%expect {|
    matched with params: ((named ()) (unnamed ())) |}]
;;

let%expect_test "we can extract parameter after match" =
  let route = Route.of_string "/foo/*/:bar" in
  let router = add empty route () in
  test_match_url router "/foo/100/baz";
  test_match_url router "/foo/100";
  test_match_url router "/foo/100/200/300";
  [%expect
    {|
    matched with params: ((named ((bar baz))) (unnamed (100)))
    no match
    no match |}]
;;

let of_routes routes =
  List.fold_left
    (fun router (route, data) -> add router (Route.of_string route) data)
    empty
    routes
;;

let of_routes' routes = routes |> List.map (fun r -> r, ()) |> of_routes

let%expect_test "ambiguity in routes" =
  of_routes' [ "/foo/baz"; "/foo/bar"; "/foo/*" ] |> ignore;
  [%expect.unreachable]
  [@@expect.uncaught_exn
    {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)

  (Failure "duplicate routes")
  Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
  Called from Stdlib__list.fold_left in file "list.ml", line 121, characters 24-34
  Called from Opium_tests__Opium_router_tests.(fun) in file "opium/test/opium_router_tests.ml", line 104, characters 2-49
  Called from Expect_test_collector.Make.Instance.exec in file "collector/expect_test_collector.ml", line 244, characters 12-19 |}]
;;

let%expect_test "ambiguity in routes 2" =
  of_routes' [ "/foo/*/bar"; "/foo/bar/*" ] |> ignore;
  [%expect.unreachable]
  [@@expect.uncaught_exn
    {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)

  (Failure "duplicate routes")
  Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
  Called from Stdlib__list.fold_left in file "list.ml", line 121, characters 24-34
  Called from Opium_tests__Opium_router_tests.(fun) in file "opium/test/opium_router_tests.ml", line 120, characters 2-43
  Called from Expect_test_collector.Make.Instance.exec in file "collector/expect_test_collector.ml", line 244, characters 12-19 |}]
;;

let test_match router url expected_value =
  match match_url router url with
  | Some (s, _) -> assert (s = expected_value)
  | None ->
    Format.printf "%a@." Sexp.pp_hum (Router.sexp_of_t Sexp_conv.sexp_of_string router)
;;

let%expect_test "nodes are matched correctly" =
  let router = of_routes [ "/foo/bar", "Wrong"; "/foo/baz", "Right" ] in
  let test = test_match router in
  test "/foo/bar" "Wrong";
  test "/foo/baz" "Right";
  [%expect {| |}]
;;

let%expect_test "full splat node matches" =
  let router = of_routes' [ "/foo/**" ] in
  let test = test_match_url router in
  test "/foo/bar";
  test "/foo/bar/foo";
  test "/foo/";
  [%expect
    {|
    matched with params: ((named ()) (unnamed ()))
    matched with params: ((named ()) (unnamed ()))
    matched with params: ((named ()) (unnamed ())) |}]
;;

let%expect_test "full splat + collision checking" =
  ignore (of_routes' [ "/foo/**"; "/*/bar" ]);
  [%expect.unreachable]
  [@@expect.uncaught_exn
    {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)

  (Failure "duplicate routes")
  Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
  Called from Stdlib__list.fold_left in file "list.ml", line 121, characters 24-34
  Called from Opium_tests__Opium_router_tests.(fun) in file "opium/test/opium_router_tests.ml", line 164, characters 9-45
  Called from Expect_test_collector.Make.Instance.exec in file "collector/expect_test_collector.ml", line 244, characters 12-19 |}]
;;

let%expect_test "two parameters" =
  let router = of_routes' [ "/test/:format/:name/:baz" ] in
  let test = test_match_url router in
  test "/test/json/bar/blah";
  [%expect
    {|
    matched with params: ((named ((baz blah) (name bar) (format json)))
                          (unnamed ())) |}]
;;
