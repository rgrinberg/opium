open Opium.Std
open Lwt.Syntax

module Person = struct
  type t =
    { name : string
    ; age : int
    }
  [@@deriving yojson]
end

let print_person =
  get "/person/:name/:age" (fun req ->
      let name = Request.param "name" req |> Option.get in
      let age = Request.param "age" req |> Option.get |> int_of_string in
      let person = { Person.name; age } |> Person.yojson_of_t in
      Lwt.return (Response.of_json person))
;;

let update_person =
  patch "/person" (fun req ->
      let+ json = Request.json req in
      let person = Person.t_of_yojson json in
      Logs.info (fun m -> m "Received person: %s" person.Person.name);
      Response.of_json (`Assoc [ "message", `String "Person saved" ]))
;;

let streaming =
  post "/hello/stream" (fun req ->
      let { Body.length; _ } = req.Request.body in
      let content = Body.to_stream req.Request.body in
      let body = Lwt_stream.map String.uppercase_ascii content in
      Response.make ~body:(Body.of_stream ?length body) () |> Lwt.return)
;;

let print_param =
  get "/hello/:name" (fun req ->
      Lwt.return
        (Response.of_plain_text @@ Printf.sprintf "Hello, %s\n" (Request.param req "name")))
;;

let _ =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Debug);
  App.empty
  |> streaming
  |> print_param
  |> print_person
  |> update_person
  |> App.run_command
;;
