open Opium
open Sexplib0.Sexp_conv

module Auth = struct
  (* https://github.com/mirage/ocaml-cohttp/blob/35e1386dcca759bcc955c59c7e91260f765f253b/cohttp/src/auth.ml *)
  (*{{{ Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
   *
   * Permission to use, copy, modify, and distribute this software for any
   * purpose with or without fee is hereby granted, provided that the above
   * copyright notice and this permission notice appear in all copies.
   *
   * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
   *
  }}}*)

  open Sexplib0.Sexp_conv
  open Printf

  type challenge = [ `Basic of string (* realm *) ] [@@deriving sexp]

  type credential =
    [ `Basic of string * string (* username, password *)
    | `Other of string
    ]
  [@@deriving sexp]

  let string_of_credential (cred : credential) =
    match cred with
    | `Basic (user, pass) -> "Basic " ^ Base64.encode_string (sprintf "%s:%s" user pass)
    | `Other buf -> buf
  ;;

  let credential_of_string (buf : string) : credential =
    try
      let b64 = Scanf.sscanf buf "Basic %s" (fun b -> b) in
      match Stringext.split ~on:':' (Base64.decode_exn b64) ~max:2 with
      | [ user; pass ] -> `Basic (user, pass)
      | _ -> `Other buf
    with
    | _ -> `Other buf
  ;;

  let string_of_challenge (ty : challenge) =
    match ty with
    | `Basic realm -> sprintf "Basic realm=\"%s\"" realm
  ;;
end

type user = { username : string (* ... *) } [@@deriving sexp]

(* My convention is to stick the keys inside an Env sub module. By not exposing this
   module in the mli we are preventing the user or other middleware from meddling with our
   values by not using our interface *)
module Env = struct
  (* or use type nonrec *)
  type user' = user

  let key : user' Opium.Context.key = Opium.Context.Key.create ("user", [%sexp_of: user])
end

(* Usually middleware gets its own module so the middleware constructor function is
   usually shortened to m. For example, [Auth.m] is obvious enough.

   The auth param (auth : username:string -> password:string -> user option) would
   represent our database model. E.g. it would do some lookup in the db and fetch the
   user. *)
let m auth =
  let filter handler ({ Request.headers; env; _ } as req) =
    match
      Option.map Auth.credential_of_string (Httpaf.Headers.get headers "authorization")
    with
    | None ->
      (* could redirect here, but we return user as an option type *)
      handler req
    | Some (`Other _) ->
      (* handle other, non-basic authentication mechanisms *)
      handler req
    | Some (`Basic (username, password)) ->
      (match auth ~username ~password with
      | None -> failwith "TODO: bad username/password pair"
      | Some user ->
        (* we have a user. let's add him to req *)
        let env = Opium.Context.add Env.key user env in
        let req = { req with Request.env } in
        handler req)
  in
  Rock.Middleware.create ~name:"http basic auth" ~filter
;;

let user { Request.env; _ } = Opium.Context.find Env.key env
