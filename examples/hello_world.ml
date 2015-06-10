open Core_kernel.Std
open Opium.Std

type person = {
  name: string;
  age: int;
}

let json_of_person { name ; age } =
  let open Ezjsonm in
  dict [ "name", (string name)
       ; "age", (int age) ]

let print_param = put "/hello/:name" begin fun req ->
  `String ("Hello " ^ param req "name") |> respond'
end

let print_person = get "/person/:name/:age" begin fun req ->
  let person = {
    name = param req "name";
    age = "age" |> param req |> Int.of_string;
  } in
  `Json (person |> json_of_person |> Ezjsonm.wrap) |> respond'
end

let _ =
  App.empty
  |> print_param
  |> print_person
  |> Runtime.run_command
