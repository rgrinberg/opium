open Core_kernel.Std
open Opium_misc
module Co = Cohttp
module Rock = Opium_rock

let keyc =
  object
    method encode = Fn.compose (Uri.pct_encode ~component:`Query_key) B64.encode
    method decode = Fn.compose B64.decode Uri.pct_decode
  end

(* work around since cohttp doesn't support = in values *)
let valc = keyc

module Env = struct
  type cookie = (string * string) list
  let key : cookie Univ_map.Key.t =
    Univ_map.Key.create "cookie" <:sexp_of<(string * string) list>>
end

let current_cookies env record =
  Option.value ~default:[] (Univ_map.find (Field.get env record) Env.key)

let cookies_raw req = req
                      |> Rock.Request.request
                      |> Co.Request.headers
                      |> Co.Cookie.Cookie_hdr.extract

let cookies req = req
                  |> cookies_raw
                  |> List.filter_map ~f:(fun (k,v) ->
                    (* ignore bad cookies *)
                    Option.try_with (fun () -> (keyc#decode k, valc#decode v)))

let get req ~key =
  let cookie1 =
    let env = current_cookies Rock.Request.Fields.env req in
    List.find_map env ~f:(fun (k,v) -> if k = key then Some v else None)
  in
  match cookie1 with
  | Some cookie -> Some cookie
  | None ->
    let cookies = cookies_raw req in
    let encoded_key = keyc#encode key in
    cookies
    |> List.find_map
         ~f:(fun (k,v) ->
           if k = encoded_key then Some (valc#decode v) else None)

let set_cookies resp cookies =
  let env = Rock.Response.env resp in
  let current_cookies = current_cookies Rock.Response.Fields.env resp in
  (* WRONG cookies cannot just be concatenated *)
  let all_cookies = current_cookies @ cookies in
  { resp with Rock.Response.env=(Univ_map.set env Env.key all_cookies) }

let set resp ~key ~data = set_cookies resp [(key, data)]

let m =             (* TODO: "optimize" *)
  let filter handler req =
    handler req >>| fun response ->
    let cookie_headers =
      let module Cookie = Co.Cookie.Set_cookie_hdr in
      let f (k,v) =
        (keyc#encode k, valc#encode v)
        |> Cookie.make ~path:"/" 
        |> Cookie.serialize
      in current_cookies Rock.Response.Fields.env response |> List.map ~f in
    let old_headers = Rock.Response.headers response in
    { response with Rock.Response.headers=(
       List.fold_left cookie_headers ~init:old_headers
         ~f:(fun headers (k,v) -> Co.Header.add headers k v))
    } 
  in Rock.Middleware.create ~filter ~name:(Info.of_string "Cookie")
