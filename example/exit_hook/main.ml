(* How to clean up and exit an opium app *)

open Opium

let hello_handler _ = Lwt.return @@ Response.of_plain_text "Hello World\n"

let () =
  let app = App.empty |> App.get "/" hello_handler |> App.run_command' in
  match app with
  | `Ok app ->
    Lwt_main.at_exit (fun () -> Lwt.return (print_endline "Bye!"));
    let s = Lwt.join [ app; Lwt_unix.sleep 2.0 |> Lwt.map (fun _ -> Lwt.cancel app) ] in
    ignore (Lwt_main.run s)
  | `Error -> exit 1
  | `Not_running -> exit 0
;;
