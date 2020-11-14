open Import

type path_segment =
  | Match of string
  | Param of string
  | Splat
  | FullSplat
  | Slash

type matches =
  { params : (string * string) list
  ; splat : string list
  }

let sexp_of_matches { params; splat } =
  let splat' = Sexp_conv.sexp_of_list Sexp_conv.sexp_of_string splat in
  let sexp_of_param (a, b) = Sexp_conv.sexp_of_list Sexp_conv.sexp_of_string [ a; b ] in
  Sexp.List
    [ List [ Atom "params"; Sexp_conv.sexp_of_list sexp_of_param params ]
    ; List [ Atom "splat"; splat' ]
    ]
;;

type t = path_segment list

let parse_param s =
  if s = "/"
  then Slash
  else if s = "*"
  then Splat
  else if s = "**"
  then FullSplat
  else (
    try Scanf.sscanf s ":%s" (fun s -> Param s) with
    | Scanf.Scan_failure _ -> Match s)
;;

let of_list l =
  let last_i = List.length l - 1 in
  l
  |> List.mapi ~f:(fun i s ->
         match parse_param s with
         | FullSplat when i <> last_i -> invalid_arg "** is only allowed at the end"
         | x -> x)
;;

let split_slash_delim =
  let re = '/' |> Re.char |> Re.compile in
  fun path ->
    path
    |> Re.split_full re
    |> List.map ~f:(function
           | `Text s -> `Text s
           | `Delim _ -> `Delim)
;;

let split_slash path =
  path
  |> split_slash_delim
  |> List.map ~f:(function
         | `Text s -> s
         | `Delim -> "/")
;;

let of_string path = path |> split_slash |> of_list

let to_string l =
  let r =
    l
    |> List.filter_map ~f:(function
           | Match s -> Some s
           | Param s -> Some (":" ^ s)
           | Splat -> Some "*"
           | FullSplat -> Some "**"
           | Slash -> None)
    |> String.concat ~sep:"/"
  in
  "/" ^ r
;;

let rec match_url t url ({ params; splat } as matches) =
  match t, url with
  | [], [] | [ FullSplat ], _ -> Some matches
  | FullSplat :: _, _ -> assert false (* splat can't be last *)
  | Match x :: t, `Text y :: url when x = y -> match_url t url matches
  | Slash :: t, `Delim :: url -> match_url t url matches
  | Splat :: t, `Text s :: url ->
    match_url t url { matches with splat = Uri.pct_decode s :: splat }
  | Param name :: t, `Text p :: url ->
    match_url t url { matches with params = (name, Uri.pct_decode p) :: params }
  | Splat :: _, `Delim :: _
  | Param _ :: _, `Delim :: _
  | Match _ :: _, _
  | Slash :: _, _
  | _ :: _, []
  | [], _ :: _ -> None
;;

let match_url t url =
  let path =
    match String.index_opt url '?' with
    | None -> url
    | Some i -> String.sub url ~pos:0 ~len:i
  in
  let path = path |> split_slash_delim in
  match_url t path { params = []; splat = [] }
;;
