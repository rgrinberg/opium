open Opium.Std

module Person = struct
  type t =
    { name : string
    ; age : int
    }
  [@@deriving yojson]
end

let print_person =
  get "/person/:name/:age" (fun req ->
      let person =
        { Person.name = param req "name"; age = "age" |> param req |> int_of_string }
        |> Person.yojson_of_t
      in
      Lwt.return (Response.of_json person))
;;

let streaming =
  post "/hello/stream" (fun req ->
      let { Opium_kernel.Body.length; _ } = req.Request.body in
      let content = Opium_kernel.Body.to_stream req.Request.body in
      let body = Lwt_stream.map String.uppercase_ascii content in
      Response.make ~body:(Opium_kernel.Body.of_stream ?length body) () |> Lwt.return)
;;

let print_param =
  get "/hello/:name" (fun req ->
      Lwt.return (Response.of_string @@ Printf.sprintf "Hello, %s\n" (param req "name")))
;;

let _ =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Debug);
  App.empty |> streaming |> print_param |> print_person |> App.run_command
;;
