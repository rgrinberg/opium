open Import

module Route = struct
  open Printf

  type t =
    | Nil
    | Full_splat
    | Literal of string * t
    | Param of string option * t

  let equal = ( = )

  let to_string t =
    let rec loop acc = function
      | Nil -> acc
      | Full_splat -> "**" :: acc
      | Literal (s, rest) -> loop (s :: acc) rest
      | Param (s, rest) ->
        let s = Option.value s ~default:"*" in
        loop (s :: acc) rest
    in
    loop [] t |> List.rev |> String.concat ~sep:"/"
  ;;

  let rec sexp_of_t (t : t) : Sexp.t =
    match t with
    | Nil -> Atom "Nil"
    | Full_splat -> Atom "Full_splat"
    | Literal (x, y) -> List [ Atom x; sexp_of_t y ]
    | Param (x, y) ->
      let x : Sexp.t =
        match x with
        | Some x -> Atom (":" ^ x)
        | None -> Atom "*"
      in
      List [ x; sexp_of_t y ]
  ;;

  exception E of string

  let rec parse_tokens params tokens =
    match tokens with
    | [ "**" ] -> Full_splat
    | [] | [ "" ] -> Nil
    | token :: tokens ->
      if token = ""
      then raise (E "Double '/' not allowed")
      else if token = "*"
      then Param (None, parse_tokens params tokens)
      else if token = "**"
      then raise (E (sprintf "double splat allowed only in the end"))
      else if token.[0] = ':'
      then (
        let name =
          let len = String.length token in
          if len > 1
          then String.sub token ~pos:1 ~len:(len - 1)
          else raise (E "Named paramter is missing a name")
        in
        let params =
          if List.mem name ~set:params
          then raise (E (sprintf "duplicate parameter %S" name))
          else name :: params
        in
        Param (Some name, parse_tokens params tokens))
      else Literal (token, parse_tokens params tokens)
  ;;

  let of_string s =
    let tokens = String.split_on_char ~sep:'/' s in
    match tokens with
    | "" :: tokens -> parse_tokens [] tokens
    | _ -> raise (E "route must start with /")
  ;;

  let of_string_result s =
    match of_string s with
    | exception E s -> Error s
    | s -> Ok s
  ;;
end

module Params = struct
  type t =
    { named : (string * string) list
    ; unnamed : string list
    }

  let make ~named ~unnamed = { named; unnamed }
  let all_named t = t.named

  let sexp_of_t { named; unnamed } =
    let open Sexp_conv in
    Sexp.List
      [ List
          [ Atom "named"
          ; sexp_of_list (sexp_of_pair sexp_of_string sexp_of_string) named
          ]
      ; List [ Atom "unnamed"; sexp_of_list sexp_of_string unnamed ]
      ]
  ;;

  let equal = ( = )
  let pp fmt t = Sexp.pp_hum fmt (sexp_of_t t)
  let named t name = List.assoc name t.named
  let unnamed t = t.unnamed
  let empty = { named = []; unnamed = [] }

  let create route captured =
    let rec loop acc (route : Route.t) captured =
      match route, captured with
      | Full_splat, [] -> acc
      | Nil, [] -> acc
      | Literal (_, route), _ -> loop acc route captured
      | Param (None, route), p :: captured ->
        let acc = { acc with unnamed = p :: acc.unnamed } in
        loop acc route captured
      | Param (Some name, route), p :: captured ->
        let acc = { acc with named = (name, p) :: acc.named } in
        loop acc route captured
      | Full_splat, _ :: _ -> assert false
      | Param (_, _), [] -> assert false
      | Nil, _ :: _ -> assert false
    in
    let res = loop empty route captured in
    { res with unnamed = List.rev res.unnamed }
  ;;
end

module Smap = Map.Make (String)

type 'a t =
  | Accept of ('a * Route.t)
  | Node of
      { data : ('a * Route.t) option
      ; literal : 'a t Smap.t
      ; param : 'a t option
      }

let sexp_of_smap f smap : Sexp.t =
  List (Smap.bindings smap |> List.map ~f:(fun (k, v) -> Sexp.List [ Atom k; f v ]))
;;

let rec sexp_of_t f t =
  let open Sexp_conv in
  match t with
  | Accept (a, r) -> (sexp_of_pair f Route.sexp_of_t) (a, r)
  | Node { data; literal; param } ->
    Sexp.List
      [ List [ Atom "data"; sexp_of_option (sexp_of_pair f Route.sexp_of_t) data ]
      ; List [ Atom "literal"; sexp_of_smap (sexp_of_t f) literal ]
      ; List [ Atom "param"; sexp_of_option (sexp_of_t f) param ]
      ]
;;

let empty_with data = Node { data; literal = Smap.empty; param = None }
let empty = empty_with None

let match_url t url =
  let tokens = String.split_on_char ~sep:'/' url in
  match tokens with
  | "" :: tokens ->
    let accept a route captured =
      let params = Params.create route captured in
      Some (a, params)
    in
    let rec loop t captured tokens =
      match t with
      | Accept (a, route) -> accept a route captured
      | Node t ->
        (match tokens with
        | [ "" ] | [] ->
          (match t.data with
          | None -> None
          | Some (a, route) -> accept a route captured)
        | s :: tokens ->
          let param =
            match t.param with
            | None -> None
            | Some node -> loop node (s :: captured) tokens
          in
          (match param with
          | Some _ -> param
          | None ->
            (match Smap.find_opt s t.literal with
            | None -> None
            | Some node -> (loop [@tailcall]) node captured tokens)))
    in
    loop t [] tokens
  | _ -> None
;;

let match_route t route =
  let rec loop t (route : Route.t) =
    match t with
    | Accept (a, r) -> [ a, r ]
    | Node t ->
      (match route with
      | Full_splat -> assert false
      | Nil ->
        (match t.data with
        | None -> []
        | Some (a, r) -> [ a, r ])
      | Literal (lit, route) ->
        let by_param = by_param t.param route in
        let by_literal =
          match Smap.find_opt lit t.literal with
          | None -> []
          | Some node -> loop node route
        in
        by_param @ by_literal
      | Param (_, route) ->
        let by_param = by_param t.param route in
        let by_literal =
          Smap.fold (fun _ node acc -> loop node route :: acc) t.literal []
        in
        List.concat (by_param :: by_literal))
  and by_param param route =
    match param with
    | None -> []
    | Some node -> loop node route
  in
  match loop t route with
  | [] -> Ok ()
  | routes -> Error routes
;;

let add_no_check t orig_route a =
  let rec loop t (route : Route.t) =
    match t with
    | Accept (_, _) -> assert false
    | Node t ->
      (match route with
      | Full_splat -> Accept (a, orig_route)
      | Nil -> empty_with (Some (a, orig_route))
      | Literal (lit, route) ->
        let literal =
          let node = Smap.find_opt lit t.literal |> Option.value ~default:empty in
          Smap.add lit (loop node route) t.literal
        in
        Node { t with literal }
      | Param (_, route) ->
        let param =
          let node = Option.value t.param ~default:empty in
          loop node route
        in
        Node { t with param = Some param })
  in
  loop t orig_route
;;

let update t r ~f =
  match match_route t r with
  | Error [ (a, r') ] ->
    if Route.equal r r'
    then add_no_check t r (f (Some a))
    else failwith "duplicate routes"
  | Ok () -> add_no_check t r (f None)
  | Error ([] | _ :: _ :: _) -> failwith "duplicate routes"
;;

let add t route a =
  match match_route t route with
  | Error _ -> failwith "duplicate routes"
  | Ok () -> add_no_check t route a
;;
