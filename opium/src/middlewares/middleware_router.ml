open Import

module Method_map = Map.Make (struct
  type t = Method.t

  let compare a b =
    let left = String.uppercase_ascii (Method.to_string a) in
    let right = String.uppercase_ascii (Method.to_string b) in
    String.compare left right
  ;;
end)

type 'a t = (Route.t * 'a) list Method_map.t

let empty = Method_map.empty

let get t meth =
  match Method_map.find_opt meth t with
  | None -> []
  | Some xs -> List.rev xs
;;

let add t ~route ~meth ~action =
  Method_map.update
    meth
    (function
      | None -> Some [ route, action ]
      | Some xs -> Some ((route, action) :: xs))
    t
;;

(** finds matching endpoint and returns it with the parsed list of parameters *)
let matching_endpoint endpoints meth uri =
  let endpoints = get endpoints meth in
  List.find_map endpoints ~f:(fun ep ->
      uri |> Route.match_url (fst ep) |> Option.map (fun p -> ep, p))
;;

module Env = struct
  let key : Route.matches Context.key =
    Context.Key.create ("path_params", Route.sexp_of_matches)
  ;;
end

let splat req = Context.find_exn Env.key req.Request.env |> fun route -> route.Route.splat

(* not param_exn since if the endpoint was selected it's likely that the parameter is
   already there *)
let param req param =
  let { Route.params; _ } = Context.find_exn Env.key req.Request.env in
  List.assoc param params
;;

let m endpoints =
  let filter default req =
    match matching_endpoint endpoints req.Request.meth req.Request.target with
    | None -> default req
    | Some (endpoint, params) ->
      let env_with_params = Context.add Env.key params req.Request.env in
      (snd endpoint) { req with Request.env = env_with_params }
  in
  Rock.Middleware.create ~name:"Router" ~filter
;;
