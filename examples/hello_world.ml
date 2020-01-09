open Opium.Std

type person = {name: string; age: int}

let json_of_person {name; age} =
  let open Ezjsonm in
  dict [("name", string name); ("age", int age)]

let print_param =
  put "/hello/:name" (fun req ->
      `String ("Hello " ^ param req "name") |> respond')

let streaming =
  get "/hello/stream" (fun _req ->
      let count = ref 0 in
      let chunk = "00000000000" in
      `Streaming
        (Lwt_stream.from_direct (fun () ->
             if !count < 1000 then (
               incr count ;
               Some (chunk ^ "\n") )
             else None))
      |> respond')

let default =
  not_found (fun _req ->
      `Json Ezjsonm.(dict [("message", string "Route not found")]) |> respond')

let print_person =
  get "/person/:name/:age" (fun req ->
      let person =
        {name= param req "name"; age= "age" |> param req |> int_of_string}
      in
      `Json (person |> json_of_person) |> respond')

let _ =
  App.empty |> print_param |> print_person |> streaming |> default
  |> App.run_command
