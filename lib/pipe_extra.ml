open Core.Std
open Async.Std

let singleton x = Pipe.of_list [x]
