(* This module is based on https://github.com/ulrikstrid/ocaml-cookie, with some API
   modification and the support for Signed cookies.

   BSD 3-Clause License

   Copyright (c) 2020, Ulrik Strid All rights reserved.

   Redistribution and use in source and binary forms, with or without modification, are
   permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of
   conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list
   of conditions and the following disclaimer in the documentation and/or other materials
   provided with the distribution.

   3. Neither the name of the copyright holder nor the names of its contributors may be
   used to endorse or promote products derived from this software without specific prior
   written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
   THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
   STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
   THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. *)

(* Stdlib List superset for compatiblity with OCaml < 4.10.0 *)
module List = struct
  include List

  let rec find_map f = function
    | [] -> None
    | x :: l ->
      (match f x with
      | Some _ as result -> result
      | None -> find_map f l)
  ;;
end

module Signer = struct
  type t =
    { secret : string
    ; salt : string
    }

  let make ?(salt = "salt.signer") secret = { secret; salt }

  let constant_time_compare' a b init =
    let len = String.length a in
    let result = ref init in
    for i = 0 to len - 1 do
      result := !result lor Char.(compare a.[i] b.[i])
    done;
    !result = 0
  ;;

  let constant_time_compare a b =
    if String.length a <> String.length b
    then constant_time_compare' b b 1
    else constant_time_compare' a b 0
  ;;

  let derive_key t =
    Mirage_crypto.Hash.mac
      `SHA1
      ~key:(Cstruct.of_string t.secret)
      (Cstruct.of_string t.salt)
  ;;

  let get_signature t value =
    value
    |> Cstruct.of_string
    |> Mirage_crypto.Hash.mac `SHA1 ~key:(derive_key t)
    |> Cstruct.to_string
    |> Base64.encode_exn
  ;;

  let sign t data = String.concat "." [ data; get_signature t data ]

  let verified t value signature =
    if constant_time_compare signature (get_signature t value) then Some value else None
  ;;

  let unsign t data =
    match String.split_on_char '.' data |> List.rev with
    | signature :: value ->
      let value = value |> List.rev |> String.concat "." in
      verified t value signature
    | _ -> None
  ;;
end

module Date = struct
  let int_of_month month =
    String.lowercase_ascii month
    |> function
    | "jan" -> 1
    | "feb" -> 2
    | "mar" -> 3
    | "apr" -> 4
    | "may" -> 5
    | "jun" -> 6
    | "jul" -> 7
    | "aug" -> 8
    | "sep" -> 9
    | "oct" -> 10
    | "nov" -> 11
    | "dec" -> 12
    | _ -> 1
  ;;

  let month_of_int = function
    | 1 -> "Jan"
    | 2 -> "Feb"
    | 3 -> "Mar"
    | 4 -> "Apr"
    | 5 -> "May"
    | 6 -> "Jun"
    | 7 -> "Jul"
    | 8 -> "Aug"
    | 9 -> "Sep"
    | 10 -> "Oct"
    | 11 -> "Nov"
    | 12 -> "Dec"
    | _ -> "Jan"
  ;;

  type time_zone =
    | GMT
    | UTC

  let time_zone_of_string = function
    | "GMT" -> GMT
    | "UTC" -> UTC
    | _ -> UTC
  ;;

  let int_of_time_zone = function
    | GMT -> 0
    | UTC -> 0
  ;;

  (* Fri, 07 Aug 2007 08:04:19 GMT *)
  let parse str =
    let len = String.length str in
    if len = 29
    then (
      let day = String.sub str 5 2 |> int_of_string in
      let month = String.sub str 8 3 |> int_of_month in
      let year = String.sub str 12 4 |> int_of_string in
      let hour = String.sub str 17 2 |> int_of_string in
      let minute = String.sub str 20 2 |> int_of_string in
      let second = String.sub str 23 2 |> int_of_string in
      let time_zone = String.sub str 26 3 |> time_zone_of_string |> int_of_time_zone in
      let date = year, month, day in
      let time = (hour, minute, second), time_zone in
      Ok (date, time))
    else Error `Malformed
  ;;

  type weekday =
    [ `Fri
    | `Mon
    | `Sat
    | `Sun
    | `Thu
    | `Tue
    | `Wed
    ]

  let string_of_weekday : weekday -> string = function
    | `Mon -> "Mon"
    | `Tue -> "Tue"
    | `Wed -> "Wed"
    | `Thu -> "Thu"
    | `Fri -> "Fri"
    | `Sat -> "Sat"
    | `Sun -> "Sun"
  ;;

  let zero_pad ~len str =
    let pad = len - String.length str in
    if pad > 0
    then List.init (pad + 1) (fun i -> if i = pad then str else "0") |> String.concat ""
    else str
  ;;

  (* Fri, 07 Aug 2007 08:04:19 GMT *)
  let serialize date_time =
    let ptime = Ptime.of_date_time date_time |> Option.get in
    let weekday = Ptime.weekday ptime |> string_of_weekday in
    let (year, month, day), ((hour, minute, second), _) = date_time in
    Printf.sprintf
      "%s, %s %s %s %s:%s:%s UTC"
      weekday
      (day |> string_of_int |> zero_pad ~len:2)
      (month_of_int month)
      (year |> string_of_int)
      (hour |> string_of_int |> zero_pad ~len:2)
      (minute |> string_of_int |> zero_pad ~len:2)
      (second |> string_of_int |> zero_pad ~len:2)
  ;;
end

module Cookie_map = struct
  include Map.Make (struct
    type t = int * string

    let compare (c1, s1) (c2, s2) = if String.equal s1 s2 then 0 else Int.compare c1 c2
  end)

  let filter_value (fn : 'a -> bool) (map : 'a t) = filter (fun _key v -> fn v) map
end

module Attributes = struct
  module String_map = struct
    include Map.Make (String)

    let key_exists ~key map = exists (fun k _ -> k = key) map
  end

  let force_set v _ = Some v

  let keep_numbers s =
    Astring.String.filter
      (fun c ->
        let code = Char.code c in
        if code = 45 || (code >= 48 && code <= 57) then true else false)
      s
  ;;

  let is_invalid_char c = c = ';' || c = '"'
  let is_valid_char c = not (is_invalid_char c)

  let set_attributes amap attr =
    match attr with
    | [] | [ ""; _ ] | [ "" ] | "" :: _ | "version" :: _ -> amap
    | [ key ] when String.lowercase_ascii key |> String.trim = "httponly" ->
      String_map.update "http_only" (force_set "") amap
    | key :: _ when String.lowercase_ascii key |> String.trim = "httponly" ->
      String_map.update "http_only" (force_set "") amap
    | [ key ] when String.lowercase_ascii key |> String.trim = "secure" ->
      String_map.update "secure" (force_set "") amap
    | key :: _ when String.lowercase_ascii key |> String.trim = "secure" ->
      String_map.update "secure" (force_set "") amap
    | key :: value when String.lowercase_ascii key |> String.trim = "path" ->
      String_map.update
        "path"
        (force_set
           (String.concat "" value |> String.trim |> Astring.String.filter is_valid_char))
        amap
    | key :: value when String.lowercase_ascii key |> String.trim = "domain" ->
      let domain =
        value
        |> String.concat ""
        |> String.trim
        |> Astring.String.drop ~max:1 ~sat:(( = ) '.')
        |> String.lowercase_ascii
      in
      if domain = ""
         || Astring.String.is_suffix domain ~affix:"."
         || Astring.String.is_prefix domain ~affix:"."
      then amap
      else String_map.update "domain" (force_set domain) amap
    | key :: value when String.lowercase_ascii key |> String.trim = "expires" ->
      let expires = String.concat "" value |> String.trim in
      String_map.update "expires" (force_set expires) amap
    | [ key; value ] when String.lowercase_ascii key = "max-age" ->
      String_map.update "max-age" (force_set (keep_numbers value)) amap
    | _ -> amap
  ;;

  let list_to_map attrs =
    let amap : string String_map.t = String_map.empty in
    attrs |> List.map (String.split_on_char '=') |> List.fold_left set_attributes amap
  ;;
end

type header = string * string

type expires =
  [ `Session
  | `Max_age of int64
  | `Date of Ptime.t
  ]

let expires_of_tuple (key, value) =
  String.lowercase_ascii key
  |> function
  | "max-age" -> Some (`Max_age (Int64.of_string value))
  | "expires" ->
    Date.parse value
    |> Result.to_option
    |> (fun o -> Option.bind o Ptime.of_date_time)
    |> Option.map (fun e -> `Date e)
  | _ -> None
;;

type same_site =
  [ `None
  | `Strict
  | `Lax
  ]

type value = string * string

type t =
  { expires : expires
  ; scope : Uri.t
  ; same_site : same_site
  ; secure : bool
  ; http_only : bool
  ; value : value
  }

let make
    ?(expires = `Session)
    ?(scope = Uri.empty)
    ?(same_site = `Lax)
    ?(secure = false)
    ?(http_only = false)
    ?sign_with
    (key, value)
  =
  let value =
    match sign_with with
    | None -> value
    | Some signer -> Signer.sign signer value
  in
  { expires; scope; same_site; secure; http_only; value = key, value }
;;

let maybe_unsign_with ?signer ?expires ?scope ?secure ?http_only (k, v) =
  match signer with
  | Some signer ->
    (match String.trim v |> Signer.unsign signer with
    | Some v -> Some (make ?expires ?scope ?secure ?http_only (String.trim k, v))
    | None -> None)
  | None -> Some (make ?expires ?scope ?secure ?http_only (String.trim k, String.trim v))
;;

let of_set_cookie_header ?signed_with ?origin:_ ((_, value) : header) =
  match Astring.String.cut ~sep:";" value with
  | None ->
    Option.bind (Astring.String.cut value ~sep:"=") (fun (k, v) ->
        if String.trim k = "" then None else maybe_unsign_with ?signer:signed_with (k, v))
  | Some (cookie, attrs) ->
    Option.bind (Astring.String.cut cookie ~sep:"=") (fun (k, v) ->
        if k = ""
        then None
        else (
          let attrs =
            String.split_on_char ';' attrs
            |> List.map String.trim
            |> Attributes.list_to_map
          in
          let expires =
            (match
               Attributes.String_map.find_opt "expires" attrs
               |> Option.map (fun v -> "expires", v)
             with
            | Some _ as opt -> opt
            | _ ->
              Attributes.String_map.find_opt "max-age" attrs
              |> Option.map (fun v -> "max-age", v))
            |> fun o -> Option.bind o (fun a -> expires_of_tuple a)
          in
          let secure = Attributes.String_map.key_exists ~key:"secure" attrs in
          let http_only = Attributes.String_map.key_exists ~key:"http_only" attrs in
          let domain : string option = Attributes.String_map.find_opt "domain" attrs in
          let path = Attributes.String_map.find_opt "path" attrs in
          let scope =
            Uri.empty
            |> fun uri ->
            Uri.with_host uri domain
            |> fun uri -> Option.map (Uri.with_path uri) path |> Option.value ~default:uri
          in
          maybe_unsign_with ?signer:signed_with ?expires ~scope ~secure ~http_only (k, v)))
;;

let to_set_cookie_header t =
  let v = Printf.sprintf "%s=%s" (fst t.value) (snd t.value) in
  let v =
    match Uri.path t.scope with
    | "" -> v
    | path -> Printf.sprintf "%s; Path=%s" v path
  in
  let v =
    match Uri.host t.scope with
    | None -> v
    | Some domain -> Printf.sprintf "%s; Domain=%s" v domain
  in
  let v =
    match t.expires with
    | `Date ptime ->
      Printf.sprintf "%s; Expires=%s" v (Ptime.to_date_time ptime |> Date.serialize)
    | `Max_age max -> Printf.sprintf "%s; Max-Age=%s" v (Int64.to_string max)
    | `Session -> v
  in
  let v = if t.secure then Printf.sprintf "%s; Secure" v else v in
  let v = if t.http_only then Printf.sprintf "%s; HttpOnly" v else v in
  "Set-Cookie", v
;;

let is_expired ?now t =
  match now with
  | None -> false
  | Some than ->
    (match t.expires with
    | `Date e -> Ptime.is_earlier ~than e
    | _ -> false)
;;

let is_not_expired ?now t = not (is_expired ?now t)

let is_too_old ?(elapsed = 0L) t =
  match t.expires with
  | `Max_age max_age -> if max_age <= elapsed then true else false
  | _ -> false
;;

let is_not_too_old ?(elapsed = 0L) t = not (is_too_old ~elapsed t)

let has_matching_domain ~scope t =
  match Uri.host scope, Uri.host t.scope with
  | Some domain, Some cookie_domain ->
    if String.contains cookie_domain '.'
       && (Astring.String.is_suffix domain ~affix:cookie_domain || domain = cookie_domain)
    then true
    else false
  | _ -> true
;;

let has_matching_path ~scope t =
  let cookie_path = Uri.path t.scope in
  if cookie_path = "/"
  then true
  else (
    let path = Uri.path scope in
    Astring.String.is_prefix ~affix:cookie_path path || cookie_path = path)
;;

let is_secure ~scope t =
  match Uri.scheme scope with
  | Some "http" -> not t.secure
  | Some "https" -> true
  | _ -> not t.secure
;;

let to_cookie_header ?now ?(elapsed = 0L) ?(scope = Uri.of_string "/") tl =
  if List.length tl = 0
  then "", ""
  else (
    let idx = ref 0 in
    let cookie_map : string Cookie_map.t =
      tl
      |> List.filter (fun c ->
             is_not_expired ?now c
             && has_matching_domain ~scope c
             && has_matching_path ~scope c
             && is_secure ~scope c)
      |> List.fold_left
           (fun m c ->
             idx := !idx + 1;
             let key, _value = c.value in
             Cookie_map.update (!idx, key) (fun _ -> Some c) m)
           Cookie_map.empty
      |> Cookie_map.filter_value (is_not_too_old ~elapsed)
      |> Cookie_map.map (fun c -> snd c.value)
    in
    if Cookie_map.is_empty cookie_map
    then "", ""
    else
      ( "Cookie"
      , Cookie_map.fold (fun (_idx, key) value l -> (key, value) :: l) cookie_map []
        |> List.rev
        |> List.map (fun (key, value) -> Printf.sprintf "%s=%s" key value)
        |> String.concat "; " ))
;;

let cookie_of_header ?signed_with cookie_key (key, value) =
  match key with
  | "Cookie" | "cookie" ->
    String.split_on_char ';' value
    |> List.map (Astring.String.cut ~sep:"=")
    |> List.find_map (function
           | Some (k, value) when String.trim k = cookie_key ->
             let value =
               match signed_with with
               | Some signer -> String.trim value |> Signer.unsign signer
               | None -> Some (String.trim value)
             in
             Option.map (fun el -> String.trim k, el) value
           | _ -> None)
  | _ -> None
;;

let cookie_of_headers ?signed_with cookie_key headers =
  let rec aux = function
    | [] -> None
    | header :: rest ->
      (match cookie_of_header ?signed_with cookie_key header with
      | Some cookie -> Some cookie
      | None -> aux rest)
  in
  aux headers
;;

let cookies_of_header ?signed_with (key, value) =
  match key with
  | "Cookie" | "cookie" ->
    String.split_on_char ';' value
    |> List.map (Astring.String.cut ~sep:"=")
    |> List.filter_map (function
           | Some (key, value) ->
             let value =
               match signed_with with
               | Some signer -> String.trim value |> Signer.unsign signer
               | None -> Some (String.trim value)
             in
             Option.map (fun el -> String.trim key, el) value
           | None -> None)
  | _ -> []
;;

let cookies_of_headers ?signed_with headers =
  ListLabels.fold_left headers ~init:[] ~f:(fun acc header ->
      let cookies = cookies_of_header ?signed_with header in
      acc @ cookies)
;;

let sexp_of_t t =
  let open Sexplib0.Sexp_conv in
  let open Sexplib0.Sexp in
  List
    [ List
        [ Atom "expires"
        ; (match t.expires with
          | `Session -> List [ Atom "session" ]
          | `Max_age a -> List [ Atom "max_age"; Atom (Int64.to_string a) ]
          | `Date d -> List [ Atom "date"; Atom (Format.asprintf "%a" Ptime.pp d) ])
        ]
    ; List [ Atom "scope"; sexp_of_string (Format.asprintf "%a" Uri.pp t.scope) ]
    ; List
        [ Atom "same_site"
        ; sexp_of_string
            (match t.same_site with
            | `None -> "none"
            | `Strict -> "strict"
            | `Lax -> "lax")
        ]
    ; List [ Atom "secure"; sexp_of_bool t.secure ]
    ; List [ Atom "http_only"; sexp_of_bool t.http_only ]
    ; List [ Atom "value"; (sexp_of_pair sexp_of_string sexp_of_string) t.value ]
    ]
;;

let pp fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)
