open Core.Std
open Async.Std
open Rock
module Co = Cohttp

type meth = Cohttp.Code.meth

module Method_bin = struct
  type 'a t = 'a Queue.t array
  let create () = Array.init 7 ~f:(fun _ -> Queue.create ())
  let int_of_meth = function
    | `GET     -> 0
    | `POST    -> 1
    | `PUT     -> 2
    | `DELETE  -> 3
    | `HEAD    -> 4
    | `PATCH   -> 5
    | `OPTIONS -> 6
  let add t meth value = Queue.enqueue t.(int_of_meth meth) value
  let get t meth = t.(int_of_meth meth)
end

(** Provides sinatra like param bindings *)
module Route = struct
  type t = Pcre.regexp

  let get_named_matches ?rex ?pat s =
    let rex = match rex, pat with
      | Some _, Some _ -> invalid_arg "cannot provide pat and rex"
      | None, None -> invalid_arg "must provide at least ?pat or ?rex"
      | Some r, None -> r
      | None, Some p -> Pcre.regexp p
    in
    let all_names = Pcre.names rex in
    let subs = Pcre.exec ~rex s in
    all_names |> Array.to_list |> List.map ~f:(fun name ->
        (name, Pcre.get_named_substring rex name subs))

  let pcre_of_route route =
    let compile_to_pcre s =
      Pcre.substitute ~pat:":\\w+" ~subst:(fun s ->
          Printf.sprintf "(?<%s>[^/]+)" 
            (String.chop_prefix_exn s ~prefix:":")) s
    in compile_to_pcre (route ^ "$")

  let create path = path |> pcre_of_route |> Pcre.regexp

  let match_url t s = 
    let rex = t in
    if not (Pcre.pmatch ~rex s) then None
    else Some (get_named_matches ~rex s)
end

(* an endpoint is simply an action tied to the way it's dispatched.
   like a Handler.t but also has user specified params and is
   specifying to an http method *)
type 'action endpoint = {
  meth: Co.Code.meth;
  route: Route.t;
  action: 'action;
} with fields

(** finds matching endpoint and returns it with the parsed list of parameters *)
let matching_endpoint endpoints meth uri =
  let endpoints = Method_bin.get endpoints meth in
  endpoints |> Queue.find_map ~f:(fun ep -> 
      uri |> Route.match_url ep.route |> Option.map ~f:(fun p -> (ep, p)))

module Env = struct
  type path_params = (string * string) list
  let key : path_params Univ_map.Key.t =
    Univ_map.Key.create "path_params" sexp_of_opaque
end

(* not param_exn since if the endpoint was selected it's likely that the parameter
   is already there unless the user has done some strange re fidgeting *)
let param req param =
  let params = Univ_map.find_exn (Request.env req) Env.key in
  List.Assoc.find_exn params param

(* takes a list of endpoints and a default handler. calls an endpoint
   if a match is found. otherwise calls the handler *)
let m endpoints default req =
  let url = req |> Request.uri |> Uri.to_string in
  match matching_endpoint endpoints (Request.meth req) url with
  | None -> Handler.call default req
  | Some (endpoint, params) -> begin
      let env_with_params = Univ_map.add_exn (Request.env req) Env.key params in
      Request.set_env req env_with_params;
      Handler.call endpoint.action req
      (* Handler.call endpoint.action ({req with Request.env=env_with_params}) *)
    end
