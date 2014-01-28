open OUnit2

let test_add _ =
  let x = "testing" in
  let s = Phys_map.add Phys_map.empty ~key:x ~data:"bar" in
  assert_bool "exists after adding" (Phys_map.mem s ~key:x)

let test_different_mem _ =
  let x1 _ = 3 in
  let x2 _ = 3 in
  let s = Phys_map.add Phys_map.empty ~key:x2 ~data:"foo" in
  assert_bool "clone doesnt exist" (not @@ Phys_map.mem s ~key:x1)
              
let test_fixtures =
  "test phys_map" >:::
    [
      "test add" >:: test_add;
      "test different" >:: test_different_mem;
    ]


let _ = run_test_tt_main test_fixtures
