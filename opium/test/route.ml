open Sexplib0
module Router = Opium.Private.Router

module Route = struct
  include Opium.Route

  module Matches = struct
    type t =
      { params : (string * string) list
      ; splat : string list
      }

    let equal = ( = )

    let pp fmt { params; splat } =
      let sexp =
        Router.Params.make ~named:params ~unnamed:splat |> Router.Params.sexp_of_t
      in
      Sexp.pp_hum fmt sexp
    ;;

    let of_params params =
      let splat = Router.Params.unnamed params in
      let params = List.rev (Router.Params.all_named params) in
      { params; splat }
    ;;
  end

  let match_url r u =
    let router = Router.add Router.empty r () in
    match Router.match_url router u with
    | None -> None
    | Some ((), params) -> Some (Matches.of_params params)
  ;;

  include Matches
end

let slist t = Alcotest.slist t compare
let params = slist Alcotest.(pair string string)
let matches_t : Route.Matches.t Alcotest.testable = (module Route.Matches)

let match_get_params route url =
  match Route.match_url route url with
  | None -> None
  | Some p -> Some p.params
;;

let string_of_match = function
  | None -> "None"
  | Some m ->
    let open Sexp_conv in
    Sexp.to_string_hum (sexp_of_list (sexp_of_pair sexp_of_string sexp_of_string) m)
;;

let simple_route1 () =
  let r = Route.of_string "/test/:id" in
  Alcotest.(check (option params) "no match" None (match_get_params r "/test/blerg/123"));
  Alcotest.(
    check (option params) "match" (match_get_params r "/test/123") (Some [ "id", "123" ]))
;;

let simple_route2 () =
  let r = Route.of_string "/test/:format/:name" in
  let m = match_get_params r "/test/json/bar" in
  Alcotest.(check (option params) "" m (Some [ "format", "json"; "name", "bar" ]))
;;

let simple_route3 () =
  let r = Route.of_string "/test/:format/:name" in
  let m = Route.match_url r "/test/bar" in
  Alcotest.(check (option matches_t) "unexpected match" None m)
;;

let route_no_slash () =
  let r = Route.of_string "/xxx/:title" in
  let m = Route.match_url r "/xxx/../" in
  Alcotest.(check (option matches_t) "unexpected match" None m)
;;

let splat_route1 () =
  let r = Route.of_string "/test/*/:id" in
  let matches = Route.match_url r "/test/splat/123" in
  Alcotest.(
    check
      (option matches_t)
      "matches"
      (Some { Route.params = [ "id", "123" ]; splat = [ "splat" ] })
      matches)
;;

let splat_route2 () =
  let r = Route.of_string "/*" in
  let m = Route.match_url r "/abc/123" in
  Alcotest.(check (option matches_t) "unexpected match" None m)
;;

let splat_route3 () =
  let r = Route.of_string "/*/*/*" in
  let matches = Route.match_url r "/test/splat/123" in
  Alcotest.(
    check
      (option matches_t)
      "matches"
      (Some { Route.params = []; splat = [ "test"; "splat"; "123" ] })
      matches)
;;

let test_match_2_params () =
  let r = Route.of_string "/xxx/:x/:y" in
  let m = match_get_params r "/xxx/123/456" in
  Alcotest.(check (option params) "" (Some [ "x", "123"; "y", "456" ]) m)
;;

let test_match_no_param () =
  let r = Route.of_string "/version" in
  let m1, m2 = Route.(match_url r "/version", match_url r "/tt") in
  match m1, m2 with
  | Some _, None -> ()
  | _, _ -> Alcotest.fail "bad match"
;;

let test_empty_route () =
  let r = Route.of_string "/" in
  let m s =
    match Route.match_url r s with
    | None -> false
    | Some _ -> true
  in
  let m1, m2 = m "/", m "/testing" in
  Alcotest.(check bool "match '/'" true m1);
  Alcotest.(check bool "not match '/testing'" false m2)
;;

let printer x = x
let str_t s = s |> Route.of_string |> Route.to_string
let string_convert_1 () = Alcotest.(check string "" "/" (str_t "/"))
let string_convert_2 () = Alcotest.(check string "" "/one/:two" (str_t "/one/:two"))

let string_convert_3 () =
  Alcotest.(check string "" "/one/two/*/three" (str_t "/one/two/*/three"))
;;

let escape_param_1 () =
  let r = Route.of_string "/:pp/*" in
  let matches = Route.match_url r "/%23/%23a" in
  Alcotest.(
    check
      (option matches_t)
      "matches"
      (Some { Route.params = [ "pp", "#" ]; splat = [ "#a" ] })
      matches)
;;

let empty_route () =
  let r = Route.of_string "" in
  Alcotest.(
    check
      (option matches_t)
      ""
      (Some { Route.params = []; splat = [] })
      (Route.match_url r ""))
;;

let test_double_splat () =
  let r = Route.of_string "/**" in
  let matching_urls =
    [ "/test", [ "test" ]; "/", []; "/user/123/foo/bar", [ "user"; "123"; "foo"; "bar" ] ]
  in
  matching_urls
  |> List.iter (fun (u, splat) ->
         Alcotest.(
           check
             (option matches_t)
             "matches"
             (Some { Route.params = []; splat })
             (Route.match_url r u)))
;;

let test_double_splat_escape () =
  let r = Route.of_string "/**" in
  let matches = Route.match_url r "/%23/%23a" in
  Alcotest.(
    check
      (option matches_t)
      "matches"
      (Some { Route.params = []; splat = [ "#"; "#a" ] })
      matches)
;;

let test_query_params_dont_impact_match () =
  let r2 = Route.of_string "/foo/:message" in
  Alcotest.(
    check (option params) "" (match_get_params r2 "/foo/bar") (Some [ "message", "bar" ]));
  Alcotest.(
    check
      (option params)
      ""
      (match_get_params r2 "/foo/bar?key=12")
      (Some [ "message", "bar" ]))
;;

let () =
  Alcotest.run
    "Route"
    [ ( "match"
      , [ "test match no param", `Quick, test_match_no_param
        ; "test match 1", `Quick, simple_route1
        ; "test match 2", `Quick, simple_route2
        ; "test match 3", `Quick, simple_route3
        ; "test match 2 params", `Quick, test_match_2_params
        ] )
    ; ( "splat"
      , [ "splat match 1", `Quick, splat_route1
        ; "splat match 2", `Quick, splat_route2
        ; "splat match 3", `Quick, splat_route3
        ; "test double splat", `Quick, test_double_splat
        ] )
    ; ( "conversion"
      , [ "test string conversion 1", `Quick, string_convert_1
        ; "test string conversion 2", `Quick, string_convert_2
        ; "test string conversion 3", `Quick, string_convert_3
        ] )
    ; ( "empty"
      , [ "test empty route", `Quick, test_empty_route
        ; "empty route", `Quick, empty_route
        ] )
    ; "escape", [ "test escape param", `Quick, escape_param_1 ]
    ; ( "query params"
      , [ ( "test query params dont impact match"
          , `Quick
          , test_query_params_dont_impact_match )
        ; "test double splat escape", `Quick, test_double_splat_escape
        ] )
    ]
;;
