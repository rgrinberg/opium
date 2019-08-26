open Opium.Std

let hello = get "/" (fun _ -> `String "Hello World" |> respond')

let () = App.empty |> hello |> App.run_command |> ignore
