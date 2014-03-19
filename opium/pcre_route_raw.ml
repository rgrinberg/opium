open Core.Std
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

let of_string path = path |> pcre_of_route |> Pcre.regexp

let match_url t s = 
  let rex = t in
  if not (Pcre.pmatch ~rex s) then None
  else Some (get_named_matches ~rex s)

(* TODO: this is dumb and buggy *)
let sexp_of_t t = Sexp.of_string "<pcre>"
let t_of_sexp s = s |> String.t_of_sexp |> of_string
