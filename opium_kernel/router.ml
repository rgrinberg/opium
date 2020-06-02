type 'a t = (Route.t * 'a) Queue.t array

let int_of_meth = function
  | `GET -> 0
  | `HEAD -> 1
  | `POST -> 2
  | `PUT -> 3
  | `DELETE -> 4
  | `CONNECT -> 5
  | `OPTIONS -> 6
  | `TRACE -> 7
;;

let create () = Array.init 8 (fun _ -> Queue.create ())
let get t meth = t.(int_of_meth meth)
let add t ~route ~meth ~action = Queue.push (route, action) t.(int_of_meth meth)

(** finds matching endpoint and returns it with the parsed list of parameters *)
let matching_endpoint endpoints meth uri =
  let opt_map f = function
    | None -> None
    | Some t -> Some (f t)
  in
  let find_map (type res) q ~f =
    let module M = struct
      exception E of res
    end
    in
    try
      Queue.iter
        (fun x ->
          match f x with
          | None -> ()
          | Some y -> raise_notrace (M.E y))
        q;
      None
    with
    | M.E res -> Some res
  in
  let endpoints = get endpoints meth in
  endpoints
  |> find_map ~f:(fun ep -> uri |> Route.match_url (fst ep) |> opt_map (fun p -> ep, p))
;;

module Env = struct
  let key : Route.matches Hmap0.key =
    Hmap0.Key.create ("path_params", Route.sexp_of_matches)
  ;;
end

(* not param_exn since if the endpoint was selected it's likely that the
   parameter is already there *)
let param req param =
  let { Route.params; _ } = Hmap0.find_exn Env.key req.Rock.Request.env in
  List.assoc param params
;;

let splat req =
  Hmap0.find_exn Env.key req.Rock.Request.env |> fun route -> route.Route.splat
;;

(* takes a list of endpoints and a default handler. calls an endpoint if a match
   is found. otherwise calls the handler *)
let m endpoints =
  let filter default req =
    match matching_endpoint endpoints req.Rock.Request.meth req.Rock.Request.target with
    | None -> default req
    | Some (endpoint, params) ->
      let env_with_params = Hmap0.add Env.key params req.Rock.Request.env in
      (snd endpoint) { req with Rock.Request.env = env_with_params }
  in
  Rock.Middleware.create ~name:"Router" ~filter
;;
