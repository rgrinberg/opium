open Core.Std
open Async.Std
open Opium.Std

let hello = get "/"
    (fun req -> 
    	open Cow
    	`Html (html_msg "Hello World") 
    	|> respond')

let html_msg msg = <:html<
<html>
	<head>
		<title>Message</title>
	</head>
	<body>
		&str:msg$
	</body>
</html>
>>

let () =
  App.empty
  |> hello
  |> App.command
  |> Command.run