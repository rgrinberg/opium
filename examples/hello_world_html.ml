open Opium.Std

(* let html_msg msg = <:html< *)
(* <html> *)
(*   <head> *)
(*     <title>Message</title> *)
(*   </head> *)
(*   <body> *)
(*     $str:msg$ *)
(*   </body> *)
(* </html> *)
(* >> *)

(* let hello = get "/" (fun req -> *)
(*   `Html ("Hello World" |> html_msg |> Html.to_string) *)
(*   |> respond') *)

let _ =
  App.empty
  (* |> hello *)
  |> App.run_command
