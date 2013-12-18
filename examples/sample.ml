open Core.Std
open Async.Std
open Opium.Std

let e1 = get "/version" (fun req -> respond (`String "testing"))

let e2 = get "/hello/:name" (fun req -> 
    let name = param req "name" in
    respond @@ `String ("hello " ^ name))

let e3 = get "/xxx/:x/:y/?" begin fun req ->
    let x = "x" |> param req |> Int.of_string in
    let y = "y" |> param req |> Int.of_string in
    let sum = Float.of_int (x + y) in
    respond @@ `Json (Cow.Json.Float sum)
  end

let e4 = put "/hello/:x/from/:y" begin fun req ->
    let (x,y) = (param req "x", param req "y") in
    let msg = sprintf "Hello %s! from %s." x y in
    respond @@ `String msg
  end

let set_cookie = get "/set/:key/:value" begin fun req ->
    Log.Global.info "Setting cookie";
    let (key, value) = (param req "key", param req "value") in
    Cookie.set req key value;
    respond @@ `String (Printf.sprintf "Set %s to %s" key value)
  end

let get_cookie = get "/get/:key" begin fun req ->
    Log.Global.info "Getting cookie";
    let key = param req "key" in
    let message = sprintf "Cookie %s doesn't exist" key in
    let value = Option.value_exn ~message (Cookie.get req ~key) in
    respond @@ `String (sprintf "Cookie %s is: %s" key value) 
  end

(* exceptions should be nicely formatted *)
let throws = get "/yyy" (fun req ->
    Log.Global.info "Crashing...";
    List.hd_exn [])

let _ = start [e1; e2; e3; e4; get_cookie; set_cookie; throws]
