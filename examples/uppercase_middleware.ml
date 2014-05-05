open Core.Std
open Async.Std
open Opium.Std

let uppercase =
  let filter handler req =
    handler req >>| fun response ->
    response
    |> Response.body
    |> Cohttp_async.Body.to_pipe
    |> Pipe.map ~f:String.uppercase
    |> Cohttp_async.Body.of_pipe
    |> Field.fset Response.Fields.body response
  in
  Rock.Middleware.create ~name:(Info.of_string "uppercaser") ~filter

let _ = App.empty
        |> middleware uppercase
        |> get "/hello" (fun req -> `String ("Hello World") |> respond')
        |> App.cmd_name "Uppercaser"
        |> App.command
        |> Command.run

