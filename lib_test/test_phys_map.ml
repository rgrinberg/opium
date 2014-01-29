open OUnit2

let test_add _ =
  let x = "testing" in
  let s = Phys_map.add_exn Phys_map.empty ~key:x ~data:"bar" in
  assert_bool "exists after adding" (Phys_map.mem s ~key:x)

let test_different_mem _ =
  let x1 _ = 3 in
  let x2 _ = 3 in
  let s = Phys_map.(add_exn empty ~key:x2 ~data:"foo") in
  assert_bool "clone doesnt exist" (not @@ Phys_map.mem s ~key:x1)

let test_find _ =
  let s = "testing" in
  let m = Phys_map.(empty |> add_exn ~key:s ~data:"foobar") in
  assert_equal (Phys_map.find m ~key:s) (Some "foobar")

let test_fixtures =
  "test phys_map" >:::
  [
    "test add" >:: test_add;
    "test different" >:: test_different_mem;
    "test find" >:: test_find;
  ]


let _ = run_test_tt_main test_fixtures
