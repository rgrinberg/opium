open Core.Std
open Async.Std
open Opium.Std
open Cow

let param = Router.param

let e1 = get "/version" (fun req -> Response.respond (`String "testing"))

let e2 = get "/hello/:name" (fun req -> 
    let name = param req "name" in
    Response.respond @@ `String ("hello " ^ name))

let e3 = get "/xxx/:x/:y/?" begin fun req ->
    let x = "x" |> param req |> Int.of_string in
    let y = "y" |> param req |> Int.of_string in
    let sum = Float.of_int (x + y) in
    Response.respond @@ `Json (Json.Float sum)
  end

let e4 = put "/hello/:x/from/:y" begin fun req ->
  let (x,y) = (param req "x", param req "y") in
  let msg = sprintf "Hello %s! from %s." x y in
  Response.respond @@ `String msg
end

(* test debug *)
let throws = get "/yyy" (fun req -> List.hd_exn [])

let _ = start [e1; e2; e3; e4; throws]
