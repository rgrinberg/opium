open Opium

module Person = struct
  type t =
    { name : string
    ; age : int
    }

  let yojson_of_t t = `Assoc [ "name", `String t.name; "age", `Int t.age ]

  let t_of_yojson yojson =
    match yojson with
    | `Assoc [ ("name", `String name); ("age", `Int age) ] -> { name; age }
    | _ -> failwith "invalid person json"
  ;;
end

let print_person_handler req =
  let name = Router.param req "name" in
  let age = Router.param req "age" |> int_of_string in
  let person = { Person.name; age } |> Person.yojson_of_t in
  Lwt.return (Response.of_json person)
;;

let update_person_handler req =
  let open Lwt.Syntax in
  let+ json = Request.to_json_exn req in
  let person = Person.t_of_yojson json in
  Logs.info (fun m -> m "Received person: %s" person.Person.name);
  Response.of_json (`Assoc [ "message", `String "Person saved" ])
;;

let streaming_handler req =
  let length = Body.length req.Request.body in
  let content = Body.to_stream req.Request.body in
  let body = Lwt_stream.map String.uppercase_ascii content in
  Response.make ~body:(Body.of_stream ?length body) () |> Lwt.return
;;

let print_param_handler req =
  Printf.sprintf "Hello, %s\n" (Router.param req "name")
  |> Response.of_plain_text
  |> Lwt.return
;;

let _ =
  App.empty
  |> App.post "/hello/stream" streaming_handler
  |> App.get "/hello/:name" print_param_handler
  |> App.get "/person/:name/:age" print_person_handler
  |> App.patch "/person" update_person_handler
  |> App.run_command
;;
