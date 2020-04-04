open Lwt.Infix

type content =
  [ `Empty
  | `String of string
  | `Bigstring of Bigstringaf.t
  | (* TODO: switch to a iovec based stream *)
    `Stream of string Lwt_stream.t ]

type t = {length: Int64.t option; content: content}

let drain {content; _} =
  match content with
  | `Stream stream -> Lwt_stream.junk_while (fun _ -> true) stream
  | _ -> Lwt.return_unit

let to_string {content; _} =
  match content with
  | `Stream content ->
      let buf = Buffer.create 1024 in
      Lwt_stream.iter (fun s -> Buffer.add_string buf s) content
      >|= fun () -> Buffer.contents buf
  | `String s -> Lwt.return s
  | `Bigstring b -> Lwt.return (Bigstringaf.to_string b)
  | `Empty -> Lwt.return ""

let to_stream {content; _} =
  match content with
  | `Empty -> Lwt_stream.of_list []
  | `String s -> Lwt_stream.of_list [s]
  | `Bigstring b -> Lwt_stream.of_list [Bigstringaf.to_string b]
  | `Stream s -> s

let len x = Some (Int64.of_int x)

let of_string s = {content= `String s; length= len (String.length s)}

let of_bigstring b = {content= `Bigstring b; length= len (Bigstringaf.length b)}

let empty = {content= `Empty; length= Some 0L}

let of_stream ?length s = {content= `Stream s; length}
