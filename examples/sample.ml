open Opium.Std

let e1 = get "/version" (fun _ -> `String "testing" |> respond')

let e2 =
  get "/hello/:name" (fun req ->
      let name = param req "name" in
      `String ("hello " ^ name) |> respond')

let e3 =
  get "/xxx/:x/:y" (fun req ->
      let x = "x" |> param req |> int_of_string in
      let y = "y" |> param req |> int_of_string in
      let sum = float_of_int (x + y) in
      let open Ezjsonm in
      `Json (`A [int x; int y; float sum]) |> respond')

let e4 =
  put "/hello/:x/from/:y" (fun req ->
      let x, y = (param req "x", param req "y") in
      let msg = Printf.sprintf "Hello %s! from %s." x y in
      `String msg |> respond |> Lwt.return)

let splat_route =
  get "/testing/*/:p" (fun req ->
      let p = param req "p" in
      `String (Printf.sprintf "__ %s __" p ^ (req |> splat |> String.concat ":"))
      |> respond')

(* exceptions should be nicely formatted *)
let throws =
  get "/yyy" (fun _ ->
      Logs.warn (fun f -> f "Crashing...") ;
      failwith "expected failure!")

(* TODO: a static path will not be overriden. bug? *)
let override_static =
  get "/public/_tags" (fun _ ->
      `String "overriding path" |> respond |> Lwt.return)

let app =
  App.empty |> e1 |> e2 |> e3 |> e4 |> throws |> middleware Cookie.m
  |> middleware (Middleware.static ~local_path:"./" ~uri_prefix:"/public" ())
  |> splat_route

let _ = app |> App.run_command
