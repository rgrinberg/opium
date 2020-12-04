module Challenge = struct
  type t = Basic of string

  let t_of_sexp =
    let open Sexplib0.Sexp in
    function
    | List [ Atom "basic"; Atom s ] -> Basic s
    | _ -> failwith "invalid challenge sexp"
  ;;

  let sexp_of_t =
    let open Sexplib0.Sexp in
    function
    | Basic s -> List [ Atom "basic"; Atom s ]
  ;;
end

module Credential = struct
  type t =
    | Basic of string * string (* username, password *)
    | Other of string

  let t_of_sexp =
    let open Sexplib0.Sexp in
    function
    | List [ Atom "basic"; Atom u; Atom p ] -> Basic (u, p)
    | _ -> failwith "invalid credential sexp"
  ;;

  let sexp_of_t =
    let open Sexplib0.Sexp in
    function
    | Basic (u, p) -> List [ Atom "basic"; Atom u; Atom p ]
    | Other s -> List [ Atom "other"; Atom s ]
  ;;
end

let string_of_credential (cred : Credential.t) =
  match cred with
  | Basic (user, pass) ->
    "Basic " ^ Base64.encode_string (Printf.sprintf "%s:%s" user pass)
  | Other buf -> buf
;;

let credential_of_string (buf : string) : Credential.t =
  try
    let b64 = Scanf.sscanf buf "Basic %s" (fun b -> b) in
    match Stringext.split ~on:':' (Base64.decode_exn b64) ~max:2 with
    | [ user; pass ] -> Basic (user, pass)
    | _ -> Other buf
  with
  | _ -> Other buf
;;

let string_of_challenge = function
  | Challenge.Basic realm -> Printf.sprintf "Basic realm=\"%s\"" realm
;;
