(** Re-exports simple middleware that doesn't have auxiliary
    functions *)
let static = Static_serve.m
let debug = Debug.debug
let trace = Debug.trace
