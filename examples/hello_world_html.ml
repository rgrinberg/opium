open Core.Std
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

let hello = get "/"
    (fun req -> 
    	`Html (html_msg "Hello World") 
    	|> respond')

let () =
  App.empty
  |> hello
  |> App.command
  |> Command.run