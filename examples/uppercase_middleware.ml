open Opium.Std

let uppercase =
  let filter handler req =
    req |> handler |> Lwt.map (fun response ->
      response
      |> Response.body
      |> Cohttp_lwt.Body.map String.uppercase_ascii
      |> (fun b->{response with Response.body=b; }))
  in
  Rock.Middleware.create ~name:"uppercaser" ~filter

let _ = App.empty
        |> middleware uppercase
        |> get "/hello" (fun _ -> `String ("Hello World") |> respond')
        |> App.cmd_name "Uppercaser"
        |> App.run_command

