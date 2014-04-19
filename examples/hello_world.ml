open Core.Std
open Async.Std
open Cow
open Opium.Std

module Person = struct
  (* this hack is needed because cow is relying on functions shadowed
     by core *)
  open Caml
  type t = {
    name: string;
    age: int; } with json
end

let print_param = put "/hello/:name" begin fun req ->
  `String ("Hello " ^ param req "name") |> respond'
end

let print_person = get "/person/:name/:age" begin fun req ->
  let person = {
    Person.name = param req "name";
    age = "age" |> param req |> Int.of_string;
  } in
  `Json (Person.json_of_t person) |> respond'
end

let _ =
  App.empty
  |> print_param
  |> print_person
  |> App.command
  |> Command.run
