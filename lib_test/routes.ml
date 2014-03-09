open Core.Std
open OUnit2
(* TODO switch to ounit 2.0 *)

module O = Opium.Router
module Route = Pcre_route_raw

let string_of_match = function
  | None -> "None"
  | Some m ->
    Sexp.to_string_hum
      (List.sexp_of_t 
         (Tuple.T2.sexp_of_t String.sexp_of_t String.sexp_of_t) m)

let test_named_matches _ =
  let pat = "/test/(?<foo>\\w+)/baz/(?<bar>\\d+)/" in
  let matches = Route.get_named_matches ~pat "/test/TEST/baz/123/" in
  assert_bool "2 matches" (List.length matches = 2);
  assert_equal (List.Assoc.find_exn matches "foo") "TEST";
  assert_equal (List.Assoc.find_exn matches "bar") "123"

let pcre_route _ =
  let r = O.Route.create "/test/:id" in
  assert_equal ~printer:string_of_match None
    (O.Route.match_url r "/test/blerg/123");
  assert_equal (O.Route.match_url r "/test/123") (Some [("id","123")])

let pcre_route2 _ =
  let r = O.Route.create "/test/:format/:name" in
  let m = O.Route.match_url r "/test/json/bar" in
  match m with
  | None -> assert_failure "no matches"
  | Some s -> begin
      assert_equal (List.Assoc.find_exn s "format") "json";
      assert_equal (List.Assoc.find_exn s "name") "bar"
    end

let pcre_route3 _ =
  let r = O.Route.create "/test/:format/:name" in
  let m = O.Route.match_url r "/test/bar" in
  match m with
  | None -> ()
  | Some _ -> assert_failure "unexpected matches"

let test_match_2_params _ =
  let r = O.Route.create "/xxx/:x/:y" in
  let m = O.Route.match_url r "/xxx/123/456" in
  match m with
  | None -> assert_failure "no match found"
  | Some m -> begin
      assert_equal (List.Assoc.find_exn m "x") "123";
      assert_equal (List.Assoc.find_exn m "y") "456"
    end

let test_fixtures =
  "test routes" >:::
  [
    "test named" >:: test_named_matches;
    "test match 1" >:: pcre_route;
    "test match 2" >:: pcre_route2;
    "test match 3" >:: pcre_route3;
    "test match 2 params" >:: test_match_2_params;
  ]

let _ = run_test_tt_main test_fixtures
