include Opium_kernel.Middleware

module Static = struct
  let log_src =
    Logs.Src.create ~doc:"Opium middleware to server static files" "opium.static_server"
  ;;

  module Log = (val Logs.src_log log_src : Logs.LOG)

  exception Isnt_a_file

  let read ~local_path fname =
    let open Lwt.Syntax in
    (* TODO: allow buffer size to be configurable *)
    let bufsize = 4096 in
    let fname = Filename.concat local_path fname in
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
        Ok (Opium_kernel.Body.of_stream ~length:size stream))
      (fun e ->
        match e with
        | Isnt_a_file -> Lwt.return (Error `Not_found)
        | exn ->
          Logs.err (fun m ->
              m "Unknown error while serving file %s. %s" fname (Printexc.to_string exn));
          Lwt.fail exn)
  ;;

  let m ~local_path ?uri_prefix ?headers ?etag_of_fname () =
    Opium_kernel.Middleware.static
      ~read:(read ~local_path)
      ?uri_prefix
      ?headers
      ?etag_of_fname
      ()
  ;;
end

let debugger = debugger ()

let logger =
  Opium_kernel.Middleware.logger
    ~time_f:(fun f ->
      let t1 = Mtime_clock.now () in
      let x = f () in
      let t2 = Mtime_clock.now () in
      let span = Mtime.span t1 t2 in
      span, x)
    ()
;;

let static = Static.m
