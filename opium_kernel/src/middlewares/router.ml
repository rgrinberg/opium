(** [Router] is a middleware that route the request to an handler depending on the URI of
    the request.

    The middleware [Router.m] takes a list of endpoints and a default handler. It will
    call the handler if a match is found in the given list of endpoint, and will fallback
    to the default handler otherwise.

    The routes can use pattern patching to match multiple endpoints.

    A URI segment preceded with a colon ":" will match any string and will insert the
    value of the segment in the environment of the request.

    For instance, a router defined with:

    {[
      let router =
        Router.create
          ()
          Router.add
          router
          ~action:Handler.hello_world
          ~meth:`GET
          ~route:"/hello/:name"
      ;;
    ]}

    will match any URI that matches "/hello/" followed by a string. This value of the last
    segment will be inserted in the request environment with the key "name", and the
    request will be handled by handler defined in [Handler.hello_world].

    Another way to use pattern matching is to use the wildchar "*" character. The URI
    segment using "*" will match any URI segment, but will not insert the value of the
    segment in the request enviroment.

    For instance, a router defined with:

    {[
      let router =
        Router.create
          ()
          Router.add
          router
          ~action:Handler.hello_world
          ~meth:`GET
          ~route:"/*/hello"
      ;;
    ]}

    will redirect any URI containing two segments with the last segment containing "hello"
    to the handler defined in [Handler.hello_world]. *)

open Core

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

(* not param_exn since if the endpoint was selected it's likely that the parameter is
   already there *)
let param req param =
  let { Route.params; _ } = Hmap0.find_exn Env.key req.Rock.Request.env in
  List.assoc param params
;;

let splat req =
  Hmap0.find_exn Env.key req.Rock.Request.env |> fun route -> route.Route.splat
;;

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
