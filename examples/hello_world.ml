open Opium.Std

type person = {name: string; age: int}

let json_of_person {name; age} =
  let open Ezjsonm in
  dict [("name", string name); ("age", int age)]

let print_param =
  put "/hello/:name" (fun req ->
      Logs.info (fun m -> m "Request body: %s\n" (Rock.Body.to_string req.body)) ;
      `String ("Hello " ^ param req "name") |> respond')

let print_person =
  get "/person/:name/:age" (fun req ->
      let person =
        {name= param req "name"; age= "age" |> param req |> int_of_string}
      in
      `Json (person |> json_of_person) |> respond')

let _ =
  Logs.set_reporter (Logs_fmt.reporter ()) ;
  Logs.set_level (Some Logs.Debug) ;
  App.empty |> print_param |> print_person |> App.run_command
