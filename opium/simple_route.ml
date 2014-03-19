open Core.Std

type path_segment =
  | Match of string
  | Param of string
  | Slash
with sexp

type t = path_segment list with sexp

let parse_param s =
  if s = "/"
  then Slash
  else match String.chop_prefix s ~prefix:":" with
    | Some s -> Param s
    | None -> Match s

let of_list = List.map ~f:parse_param

let of_string path =
  path
  |> String.split ~on:'/'
  |> List.map ~f:(fun x -> if x = "" then "/" else x)
  |> of_list

let match_url t url =
  (* assert (url.[0] = '/'); *)
  let path = url |> String.split ~on:'/' in
  let open Option.Monad_infix in
  try
    List.zip t path |> Option.map ~f:(fun l ->
      l |> List.filter_map ~f:(function
        | (Match x), y when x = y -> None
        | Slash, "" -> None
        | (Match _), _ | Slash, _ -> raise Exit
        | (Param name), value -> Some (name, value)))
  with Exit -> None
