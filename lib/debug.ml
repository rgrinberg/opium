open Core.Std
open Async.Std

open Rock

let exn_ e = Log.Global.error "%s" (Exn.to_string e)
let m handler req =
  try_with (fun () -> handler req) >>= function
  | Ok v -> return v
  | Error _exn ->
    exn_ _exn;
    let body = sprintf "<pre>%s</pre>" (Exn.to_string _exn)
               |> Pipe_extra.singleton in
    return @@ Response.create ~code:`Internal_server_error ~body
