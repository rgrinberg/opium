open Core.Std

type path_segment =
  | Match of string
  | Param of string
  | Splat
  | FullSplat
  | Slash
with sexp

type t = path_segment list with sexp

let parse_param s =
  if s = "/" then Slash
  else if s = "*" then Splat
  else
    match String.chop_prefix s ~prefix:":" with
    | Some s -> Param s
    | None -> Match s

let of_list = List.map ~f:parse_param

let of_string path =
  path
  |> String.split ~on:'/'
  |> List.map ~f:(fun x -> if x = "" then "/" else x)
  |> of_list

let rec match_url t url params =
  match t, url with
  | [], [] -> Some params
  | FullSplat::[], _ -> Some params
  | FullSplat::_, _ -> invalid_arg "** cannot occur outside last spot"
  | (Match x)::t, y::url when x = y -> match_url t url params
  | Slash::t, ""::url
  | Splat::t, _::url -> match_url t url params
  | (Match _)::_, _
  | Slash::_, _ -> None
  | (Param name)::t, value::url -> match_url t url ((name, value)::params)
  | _::_, []
  | [], _::_ -> None

let match_url t url =
  (* assert (url.[0] = '/'); *)
  let path = url |> String.split ~on:'/' in
  match_url t path []
