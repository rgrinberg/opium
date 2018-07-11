open Opium.Std

let e1 = get "/version" (fun _ -> (`String "testing") |> respond')

let e2 = get "/hello/:name" (fun req ->
  let name = param req "name" in
  `String ("hello " ^ name) |> respond')

let e3 = get "/xxx/:x/:y" begin fun req ->
  let x = "x" |> param req |> int_of_string in
  let y = "y" |> param req |> int_of_string in
  let sum = float_of_int (x + y) in
  let open Ezjsonm in
  `Json (`A [int x; int y;float sum]) |> respond'
end

let e4 = put "/hello/:x/from/:y" begin fun req ->
  let (x,y) = (param req "x", param req "y") in
  let msg = Printf.sprintf "Hello %s! from %s." x y in
  `String msg |> respond |> Lwt.return
end

let set_cookie = get "/set/:key/:value" begin fun req ->
  let (key, value) = (param req "key", param req "value") in
  `String (Printf.sprintf "Set %s to %s" key value)
  |> respond
  |> Cookie.set ~key ~data:value
  |> Lwt.return
end

let get_cookie = get "/get/:key" begin fun req ->
  Logs.info (fun f ->  f "Getting cookie");
  let key = param req "key" in
  let value =
    match Cookie.get req ~key with
    | None -> Printf.sprintf "Cookie %s doesn't exist" key
    | Some s -> s in
  `String (Printf.sprintf "Cookie %s is: %s" key value) |> respond |> Lwt.return
end

let splat_route = get "/testing/*/:p" begin fun req ->
  let p = param req "p" in
  `String (Printf.sprintf "__ %s __" p ^ (req |> splat |> String.concat ":"))
  |> respond'
end

let all_cookies = get "/cookies" begin fun req ->
  let cookies =
    req
    |> Cookie.cookies
    |> List.map (fun (k, v) -> k ^ "=" ^ v)
    |> String.concat "\n"
  in
  `String (Printf.sprintf "<pre>%s</pre>" cookies) |> respond |> Lwt.return
end

(* exceptions should be nicely formatted *)
let throws = get "/yyy" (fun _ ->
  Logs.warn (fun f -> f "Crashing...");
  failwith "expected failure!")

(* TODO: a static path will not be overriden. bug? *)
let override_static = get "/public/_tags" (fun _ ->
  (`String "overriding path") |> respond |> Lwt.return)

let app =
  App.empty
  |> e1
  |> e2
  |> e3
  |> e4
  |> get_cookie
  |> set_cookie
  |> all_cookies
  |> throws
  |> middleware Cookie.m
  |> middleware (Middleware.static ~local_path:"./" ~uri_prefix:"/public" ())
  |> splat_route

let _ =
  app |> App.run_command
