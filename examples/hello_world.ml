open Opium.Std

type person = {name: string; age: int}

let json_of_person {name; age} =
  let open Ezjsonm in
  dict [("name", string name); ("age", int age)]

let print_param =
  put "/hello/:name" (fun req ->
      `String ("Hello " ^ param req "name") |> respond')

let streaming =
  let open Lwt.Infix in
  get "/hello/stream" (fun _req ->
      (* [create_stream] returns a push function that can be used to push new
         content onto the stream. [f] is function that expects to receive a
         promise that gets resolved when the user decides that they have pushed
         all their content onto the stream. When the promise forwarded to [f]
         gets resolved, the stream will be closed. *)
      let f, push = App.create_stream () in
      let timers =
        List.map
          (fun t ->
            Lwt_unix.sleep t
            >|= fun () -> push (Printf.sprintf "Hello after %f seconds\n" t))
          [1.; 2.; 3.]
      in
      f (Lwt.join timers))

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
