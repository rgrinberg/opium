open Core.Std
open OUnit2

module O = Opium.Router
module Route = O.Route

let string_of_match = function
  | None -> "None"
  | Some m ->
    Sexp.to_string_hum
      (List.sexp_of_t 
         (Tuple.T2.sexp_of_t String.sexp_of_t String.sexp_of_t) m)

let simple_route1 _ =
  let r = O.Route.of_string "/test/:id" in
  assert_equal ~printer:string_of_match None
    (O.Route.match_url r "/test/blerg/123");
  assert_equal (O.Route.match_url r "/test/123") (Some [("id","123")])

let simple_route2 _ =
  let r = O.Route.of_string "/test/:format/:name" in
  let m = O.Route.match_url r "/test/json/bar" in
  match m with
  | None -> assert_failure "no matches"
  | Some s -> begin
      assert_equal (List.Assoc.find_exn s "format") "json";
      assert_equal (List.Assoc.find_exn s "name") "bar"
    end

let simple_route3 _ =
  let r = O.Route.of_string "/test/:format/:name" in
  let m = O.Route.match_url r "/test/bar" in
  match m with
  | None -> ()
  | Some _ -> assert_failure "unexpected matches"

let splat_route1 _ =
  let r = O.Route.of_string "/test/*/:id" in
  assert_equal (O.Route.match_url r "/test/splat/123") (Some [("id","123")])


let test_match_2_params _ =
  let r = O.Route.of_string "/xxx/:x/:y" in
  let m = O.Route.match_url r "/xxx/123/456" in
  match m with
  | None -> assert_failure "no match found"
  | Some m -> begin
      assert_equal (List.Assoc.find_exn m "x") "123";
      assert_equal (List.Assoc.find_exn m "y") "456"
    end

let test_match_no_param _ =
  let r = O.Route.of_string "/version" in
  let (m1, m2) = O.Route.(match_url r "/version", match_url r "/tt") in
  match (m1, m2) with
  | Some _, None -> ()
  | x, y -> assert_failure "bad match"

let test_empty_route _ =
  let r = O.Route.of_string "/" in
  let m s = 
    match O.Route.match_url r s with
    | None -> false
    | Some _ -> true
  in
  let (m1, m2) = O.Route.(m "/", m "/testing") in 
  assert_bool "match '/'" m1;
  assert_bool "not match '/testing'" (not m2)

let test_fixtures =
  "test routes" >:::
  [
    (* "test named" >:: test_named_matches; *)
    "test match no param" >:: test_match_no_param;
    "test match 1" >:: simple_route1;
    "test match 2" >:: simple_route2;
    "test match 3" >:: simple_route3;
    "splat match 1" >:: splat_route1;
    "test match 2 params" >:: test_match_2_params;
    "test empty route" >:: test_empty_route;
  ]

let _ = run_test_tt_main test_fixtures
