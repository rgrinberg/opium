open Opium

let index_handler _request = View.index |> Response.of_html |> Lwt.return
let _ = App.empty |> App.get "/" index_handler |> App.run_command
