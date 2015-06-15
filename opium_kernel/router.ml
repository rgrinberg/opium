open Core_kernel.Std

module Co = Cohttp
module Rock = Opium_rock
open Rock

type 'a t = (Route.t * 'a) Queue.t array with sexp

let create () = Array.init 7 ~f:(fun _ -> Queue.create ())

let int_of_meth = function
  | `GET     -> 0
  | `POST    -> 1
  | `PUT     -> 2
  | `DELETE  -> 3
  | `HEAD    -> 4
  | `PATCH   -> 5
  | `OPTIONS -> 6
  | _        -> failwith "non standard http verbs not supported"

let get t meth = t.(int_of_meth meth)

let add t ~route ~meth ~action =
  Queue.enqueue t.(int_of_meth meth) (route, action)

(** finds matching endpoint and returns it with the parsed list of
    parameters *)
let matching_endpoint endpoints meth uri =
  let endpoints = get endpoints meth in
  endpoints |> Queue.find_map ~f:(fun ep ->
    uri |> Route.match_url (fst ep) |> Option.map ~f:(fun p -> (ep, p)))

module Env = struct
  let key : Route.matches Univ_map.Key.t =
    Univ_map.Key.create "path_params" <:sexp_of<Route.matches>>
end

(* not param_exn since if the endpoint was selected it's likely that
   the parameter is already there *)
let param req param =
  let { Route.params;  _ } =
    Univ_map.find_exn (Request.env req) Env.key in
  List.Assoc.find_exn params param

let splat req =
  Env.key
  |> Univ_map.find_exn (Request.env req)
  |> Route.splat

(* takes a list of endpoints and a default handler. calls an endpoint
   if a match is found. otherwise calls the handler *)
let m endpoints =
  let filter default req =
    let url = req |> Request.uri |> Uri.path in
    match matching_endpoint endpoints (Request.meth req) url with
    | None -> default req
    | Some (endpoint, params) -> begin
        let env_with_params =
          Univ_map.add_exn (Request.env req) Env.key params in
        (snd endpoint) { req with Request.env=env_with_params }
      end
  in Rock.Middleware.create ~name:(Info.of_string "Router") ~filter
