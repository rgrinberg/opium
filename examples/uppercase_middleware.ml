open Core_kernel.Std
open Opium.Std

let uppercase =
  let filter handler req =
    req |> handler |> Lwt.map (fun response ->
      response
      |> Response.body
      |> Cohttp_lwt_body.map String.uppercase
      |> Field.fset Response.Fields.body response)
  in
  Rock.Middleware.create ~name:(Info.of_string "uppercaser") ~filter

let _ = App.empty
        |> middleware uppercase
        |> get "/hello" (fun req -> `String ("Hello World") |> respond')
        |> App.cmd_name "Uppercaser"
        |> App.run_command

