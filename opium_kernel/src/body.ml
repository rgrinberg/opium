type content =
  [ `Empty
  | `String of string
  | `Bigstring of Bigstringaf.t
  | (* TODO: switch to a iovec based stream *)
    `Stream of string Lwt_stream.t
  ]

type t =
  { length : Int64.t option
  ; content : content
  }

let length t = t.length

let escape_html s =
  let b = Buffer.create 42 in
  for i = 0 to String.length s - 1 do
    match s.[i] with
    | ('&' | '<' | '>' | '\'' | '"') as c -> Printf.bprintf b "&#%d;" (int_of_char c)
    | c -> Buffer.add_char b c
  done;
  Buffer.contents b
;;

let sexp_of_content content =
  let open Sexplib0.Sexp_conv in
  match content with
  | `Empty -> sexp_of_string ""
  | `String s -> sexp_of_string (escape_html s)
  | `Bigstring b -> sexp_of_string (escape_html (Bigstringaf.to_string b))
  | `Stream s -> sexp_of_opaque s
;;

let sexp_of_t { length; content } =
  let open Sexplib0 in
  let len = Sexp_conv.sexp_of_option Sexp_conv.sexp_of_int64 in
  Sexp.(
    List
      [ List [ Atom "length"; len length ]
      ; List [ Atom "content"; sexp_of_content content ]
      ])
;;

let drain { content; _ } =
  match content with
  | `Stream stream -> Lwt_stream.junk_while (fun _ -> true) stream
  | _ -> Lwt.return_unit
;;

let to_string { content; _ } =
  let open Lwt.Syntax in
  match content with
  | `Stream content ->
    let buf = Buffer.create 1024 in
    let+ () = Lwt_stream.iter (fun s -> Buffer.add_string buf s) content in
    Buffer.contents buf
  | `String s -> Lwt.return s
  | `Bigstring b -> Lwt.return (Bigstringaf.to_string b)
  | `Empty -> Lwt.return ""
;;

let to_stream { content; _ } =
  match content with
  | `Empty -> Lwt_stream.of_list []
  | `String s -> Lwt_stream.of_list [ s ]
  | `Bigstring b -> Lwt_stream.of_list [ Bigstringaf.to_string b ]
  | `Stream s -> s
;;

let len x = Some (Int64.of_int x)
let of_string s = { content = `String s; length = len (String.length s) }
let of_bigstring b = { content = `Bigstring b; length = len (Bigstringaf.length b) }
let empty = { content = `Empty; length = Some 0L }
let of_stream ?length s = { content = `Stream s; length }

let copy t =
  match t.content with
  | `Empty -> t
  | `String _ -> t
  | `Bigstring _ -> t
  | `Stream stream -> { t with content = `Stream (Lwt_stream.clone stream) }
;;

let pp fmt t = Sexplib0.Sexp.pp_hum fmt (sexp_of_t t)

let pp_hum fmt t =
  Format.fprintf
    fmt
    "%s"
    (match t.content with
    | `Empty -> ""
    | `String s -> s
    | `Bigstring b -> Bigstringaf.to_string b
    | `Stream _ -> "<stream>")
;;
