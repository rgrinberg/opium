open Core.Std
open Async.Std
open Opium.Std

let print_param = get "/hello/:name" begin fun req ->
  `String ("Hello " ^ param req "name") |> respond'
end

let _ = start ~port:3000 [print_param]
