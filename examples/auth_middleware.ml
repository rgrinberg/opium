open Opium.Std
open Sexplib.Std

type user = {
  username: string;
  (* ... *)
} [@@deriving sexp]

(* My convention is to stick the keys inside an Env sub module. By
   not exposing this module in the mli we are preventing the user or other
   middleware from meddling with our values by not using our interface *)
module Env = struct
  (* or use type nonrec *)
  type user' = user
  let key : user' Opium.Hmap.key = Opium.Hmap.Key.create ("user",[%sexp_of: user])
end

(*
   Usually middleware gets its own module so the middleware constructor function
   is usually shortened to m. For example, [Auth.m] is obvious enough.

   The auth param (auth : username:string -> password:string -> user option)
   would represent our database model. E.g. it would do some lookup in the db
   and fetch the user.
*)
let m auth =
  let filter handler req =
    match req |> Request.headers |> Cohttp.Header.get_authorization with
    | None ->
      (* could redirect here, but we return user as an option type *)
      handler req
    | Some `Other _ ->
      (* handle other, non-basic authentication mechanisms *)
      handler req
    | Some (`Basic (username, password)) ->
      match auth ~username ~password with
      | None -> failwith "TODO: bad username/password pair"
      | Some user -> (* we have a user. let's add him to req *)
        let env = Opium.Hmap.add Env.key user (Request.env req) in
        let req = {req with Request.env = env; } in
        handler req
  in
  Rock.Middleware.create ~name:"http basic auth" ~filter

let user req = Opium.Hmap.find Env.key (Request.env req)
