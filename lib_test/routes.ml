open Opium_misc
open Sexplib
open Sexplib.Std
open OUnit

module Route = Opium_kernel.Route

let match_get_params route url =
  url |> Route.match_url route |> Option.map ~f:Route.params

let string_of_match = function
  | None -> "None"
  | Some m ->
    Sexp.to_string_hum
      (List.sexp_of_t
         (sexp_of_pair sexp_of_string sexp_of_string) m)

let simple_route1 _ =
  let r = Route.of_string "/test/:id" in
  assert_equal ~printer:string_of_match None
    (match_get_params r "/test/blerg/123");
  assert_equal (match_get_params r "/test/123") (Some [("id","123")])

let simple_route2 _ =
  let r = Route.of_string "/test/:format/:name" in
  let m = match_get_params r "/test/json/bar" in
  match m with
  | None -> assert_failure "no matches"
  | Some s -> begin
      assert_equal (List.assoc "format" s) "json";
      assert_equal (List.assoc "name" s) "bar"
    end

let simple_route3 _ =
  let r = Route.of_string "/test/:format/:name" in
  let m = Route.match_url r "/test/bar" in
  match m with
  | None -> ()
  | Some _ -> assert_failure "unexpected matches"

let splat_route1 _ =
  let r = Route.of_string "/test/*/:id" in
  let matches = Route.match_url r "/test/splat/123" in
  match matches with
  | Some matches ->
    assert_equal (Route.params matches) [("id","123")];
    assert_equal (Route.splat matches) ["splat"]
  | None -> assert_failure "No matches for splat"

let splat_route2 _ =
  let r = Route.of_string "/*" in
  match Route.match_url r "/abc/123" with
  | None -> ()
  | Some _ -> assert_failure "splat matches an extra path"

let test_match_2_params _ =
  let r = Route.of_string "/xxx/:x/:y" in
  let m = match_get_params r "/xxx/123/456" in
  match m with
  | None -> assert_failure "no match found"
  | Some m -> begin
      assert_equal (List.assoc "x" m) "123";
      assert_equal (List.assoc "y" m) "456"
    end

let test_match_no_param _ =
  let r = Route.of_string "/version" in
  let (m1, m2) = Route.(match_url r "/version", match_url r "/tt") in
  match (m1, m2) with
  | Some _, None -> ()
  | x, y -> assert_failure "bad match"

let test_empty_route _ =
  let r = Route.of_string "/" in
  let m s =
    match Route.match_url r s with
    | None -> false
    | Some _ -> true
  in
  let (m1, m2) = Route.(m "/", m "/testing") in
  assert_bool "match '/'" m1;
  assert_bool "not match '/testing'" (not m2)

let printer x = x

let str_t s = s |> Route.of_string |> Route.to_string

let string_convert_1 _ =
  assert_equal ~printer "/" (str_t "/")

let string_convert_2 _ =
  assert_equal ~printer "/one/:two" (str_t "/one/:two")

let string_convert_3 _ =
  assert_equal ~printer "/one/two/*/three" (str_t "/one/two/*/three")

let escape_param_1 _ =
  let r = Route.of_string "/:pp/*" in
  match Route.match_url r "/%23/%23a" with
  | None -> assert_failure "should match route"
  | Some p ->
    begin
      assert_equal (Route.params p) [("pp", "#")];
      assert_equal (Route.splat p) ["#a"]
    end

let empty_route _ =
  let r = Route.of_string "" in
  match Route.match_url r "" with
  | None -> assert_failure "empty should match empty"
  | Some _ -> ()

let test_double_splat _ =
  let r = Route.of_string "/**" in
  let matching_urls = [ "/test"; "/"; "/user/123/foo/bar" ] in
  matching_urls |> List.iter ~f:(fun u ->
    match Route.match_url r u with
    | None -> assert_failure ("Failed to match " ^ u)
    | Some _ -> ())

let test_fixtures =
  "test routes" >:::
  [ "test match no param"      >:: test_match_no_param
  ; "test match 1"             >:: simple_route1
  ; "test match 2"             >:: simple_route2
  ; "test match 3"             >:: simple_route3
  ; "splat match 1"            >:: splat_route1
  ; "splat match 2"            >:: splat_route2
  ; "test match 2 params"      >:: test_match_2_params
  ; "test empty route"         >:: test_empty_route
  ; "test string conversion 1" >:: string_convert_1
  ; "test string conversion 2" >:: string_convert_2
  ; "test string conversion 3" >:: string_convert_3
  ; "test escape param"        >:: escape_param_1
  ; "empty route"              >:: empty_route
  ; "test double splat"        >:: test_double_splat
  ]

let _ = run_test_tt_main test_fixtures
