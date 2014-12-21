open Core_kernel.Std
open Opium.Std
open Cow

let html_msg msg = <:html<
<html>
  <head>
    <title>Message</title>
  </head>
  <body>
    $str:msg$
  </body>
</html>
>>

let hello = get "/" (fun req ->
  `Html (html_msg "Hello World" |> Cow.Html.to_string) 
  |> respond')

let _ =
  App.empty
  |> hello
  |> App.run_command