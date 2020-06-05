module Server = Httpaf_lwt_unix.Server
open Opium_kernel.Rock
open Lwt.Infix

type t =
  { prefix : string
  ; local_path : string
  }
[@@deriving fields, sexp]

let is_prefix ~prefix s =
  String.length prefix <= String.length s
  &&
  let i = ref 0 in
  while !i < String.length prefix && s.[!i] = prefix.[!i] do
    incr i
  done;
  !i = String.length prefix
;;

let chop_prefix ~prefix s =
  assert (is_prefix ~prefix s);
  String.sub s (String.length prefix) String.(length s - length prefix)
;;

let legal_path { prefix; local_path } requested =
  let p = chop_prefix requested ~prefix in
  let requested_path = Filename.concat local_path p in
  if is_prefix requested_path ~prefix:local_path then Some requested_path else None
;;

exception Isnt_a_file

let add_opt_header_unless_exists headers k v =
  match headers with
  | Some h -> Httpaf.Headers.add_unless_exists h k v
  | None -> Httpaf.Headers.of_list [ k, v ]
;;

let respond_with_file ?headers ~name () =
  (* TODO: allow buffer size to be configurable *)
  let bufsize = 4096 in
  Lwt.catch
    (fun () ->
      Lwt_unix.stat name
      >>= (fun s ->
            if Unix.(s.st_kind <> S_REG) then Lwt.fail Isnt_a_file else Lwt.return_unit)
      >>= fun () ->
      Lwt_io.open_file
        ~buffer:(Lwt_bytes.create bufsize)
        ~flags:[ O_RDONLY ]
        ~mode:Lwt_io.input
        name
      >>= fun ic ->
      Lwt_io.length ic
      >>= fun size ->
      let stream =
        Lwt_stream.from (fun () ->
            Lwt.catch
              (fun () ->
                Lwt_io.read ~count:bufsize ic
                >|= function
                | "" -> None
                | buf -> Some buf)
              (fun exn -> Lwt.return_none))
      in
      Lwt.on_success (Lwt_stream.closed stream) (fun () ->
          Lwt.async (fun () -> Lwt_io.close ic));
      let body = Opium_kernel.Body.of_stream ~length:size stream in
      let mime_type = Magic_mime.lookup name in
      let headers = add_opt_header_unless_exists headers "content-type" mime_type in
      let resp = Httpaf.Response.create ~headers `OK in
      Lwt.return (resp, body))
    (fun e ->
      match e with
      | Isnt_a_file ->
        let resp = Httpaf.Response.create `Not_found in
        Lwt.return (resp, Opium_kernel.Body.of_string "")
      | exn -> Lwt.fail exn)
;;

let public_serve
    t
    ~requested
    ~request_if_none_match
    ?etag_of_fname
    ?(headers = Httpaf.Headers.empty)
    ()
  =
  match legal_path t requested with
  | None -> Lwt.return `Not_found
  | Some legal_path ->
    let etag_quoted =
      match etag_of_fname with
      | Some f -> Some (Printf.sprintf "%S" (f legal_path))
      | None -> None
    in
    let headers =
      match etag_quoted with
      | Some etag_quoted -> Httpaf.Headers.add_unless_exists headers "etag" etag_quoted
      | None -> headers
    in
    let request_matches_etag =
      match request_if_none_match, etag_quoted with
      | Some request_etags, Some etag_quoted ->
        request_etags
        |> Stringext.split ~on:','
        |> ListLabels.exists ~f:(fun request_etag ->
               String.trim request_etag = etag_quoted)
      | _ -> false
    in
    if request_matches_etag
    then `Ok (Response.make ~status:`Not_modified ~headers ()) |> Lwt.return
    else
      respond_with_file ~headers ~name:legal_path ()
      >|= fun (resp, body) ->
      if resp.status = `Not_found then `Not_found else `Ok (Response.make ~body ())
;;

let is_prefix ~prefix s =
  (* TODO: factor out string utilities into their own module *)
  String.length prefix <= String.length s
  &&
  let i = ref 0 in
  while !i < String.length prefix && s.[!i] = prefix.[!i] do
    incr i
  done;
  !i = String.length prefix
;;

let m ~local_path ~uri_prefix ?headers ?etag_of_fname () =
  let filter handler req =
    if req.Request.meth = `GET
    then (
      let local_map = { prefix = uri_prefix; local_path } in
      let local_path = req.Request.target in
      if local_path |> is_prefix ~prefix:uri_prefix
      then (
        let request_if_none_match =
          Httpaf.Headers.get req.Request.headers "If-None-Match"
        in
        public_serve
          local_map
          ~requested:local_path
          ~request_if_none_match
          ?etag_of_fname
          ?headers
          ()
        >>= function
        | `Not_found -> handler req
        | `Ok x -> Lwt.return x)
      else handler req)
    else handler req
  in
  Opium_kernel.Rock.Middleware.create ~name:"Static Pages" ~filter
;;
