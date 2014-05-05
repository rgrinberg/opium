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
  else if s = "**" then FullSplat
  else
    match String.chop_prefix s ~prefix:":" with
    | Some s -> Param s
    | None -> Match s

let of_list l = 
  let last_i = List.length l - 1 in
  l |> List.mapi ~f:(fun i s -> 
    match parse_param s with
    | FullSplat when i = last_i -> invalid_arg "** is only allowed at the end"
    | x -> x)

let of_string path =
  let re = Humane_re.Str.regexp "/" in
  let tokens = Humane_re.Str.split_delim re path in
  tokens
  |> List.map ~f:(function | `Text s | `Delim s -> s)
  |> of_list

let to_string l =
  l |> List.map ~f:(function
    | Match s -> s
    | Param s -> ":" ^ s
    | Splat -> "*"
    | FullSplat -> "**"
    | Slash -> "")
  |> String.concat ~sep:"/"

let rec match_url t url params =
  match t, url with
  | [], []
  | FullSplat::[], _ -> Some params
  | FullSplat::_, _ -> assert false
  | (Match x)::t, y::url when x = y -> match_url t url params
  | Slash::t, ""::url
  | Splat::t, _::url -> match_url t url params
  | (Param name)::t, value::url -> match_url t url ((name, value)::params)
  | (Match _)::_, _
  | Slash::_, _
  | _::_, []
  | [], _::_ -> None

let match_url t url =
  assert (url.[0] = '/');
  let path = url |> String.split ~on:'/' in
  match_url t path []
