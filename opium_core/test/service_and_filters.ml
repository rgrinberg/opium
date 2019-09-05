open Lwt.Infix
open Opium_core

let simple_filters _ () =
  let my_service : (int, string) Service.t =
   fun req -> Lwt.return (string_of_int req)
  in
  let math_filter : int -> (int, string) Filter.simple =
   fun num_to_add service req -> service (req + num_to_add)
  in
  let add_two_filter = math_filter 2 in
  let add_three_filter = math_filter 3 in
  let apply_all =
    Filter.apply_all [add_two_filter; add_three_filter] my_service
  in
  apply_all 5 >|= Alcotest.(check string) "add 5" "10"

let () =
  Alcotest.run "Test Morph"
    [ ( "Can apply simple filters"
      , [Alcotest_lwt.test_case "simple math filters" `Quick simple_filters] )
    ]
