include Rock.Body

let log_src = Logs.Src.create "opium.body.of_file"

module Log = (val Logs.src_log log_src : Logs.LOG)

exception Isnt_a_file

let of_file fname =
  let open Lwt.Syntax in
  (* TODO: allow buffer size to be configurable *)
  let bufsize = 4096 in
  Lwt.catch
    (fun () ->
      let* s = Lwt_unix.stat fname in
      let* () =
        if Unix.(s.st_kind <> S_REG) then Lwt.fail Isnt_a_file else Lwt.return_unit
      in
      let* ic =
        Lwt_io.open_file
          ~buffer:(Lwt_bytes.create bufsize)
          ~flags:[ O_RDONLY ]
          ~mode:Lwt_io.input
          fname
      in
      let+ size = Lwt_io.length ic in
      let stream =
        Lwt_stream.from (fun () ->
            Lwt.catch
              (fun () ->
                let+ b = Lwt_io.read ~count:bufsize ic in
                match b with
                | "" -> None
                | buf -> Some buf)
              (fun exn ->
                Log.warn (fun m ->
                    m "Error while reading file %s. %s" fname (Printexc.to_string exn));
                Lwt.return_none))
      in
      Lwt.on_success (Lwt_stream.closed stream) (fun () ->
          Lwt.async (fun () -> Lwt_io.close ic));
      Some (of_stream ~length:size stream))
    (fun e ->
      match e with
      | Isnt_a_file | Unix.Unix_error (Unix.ENOENT, _, _) -> Lwt.return None
      | exn ->
        Logs.err (fun m ->
            m "Unknown error while serving file %s. %s" fname (Printexc.to_string exn));
        Lwt.fail exn)
;;
