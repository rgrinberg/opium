open Lwt.Infix

let default_error_handler ?request:_ error start_response =
  let open Httpaf in
  let message =
    match error with
    | `Exn _e ->
        (* TODO: log error *)
        Status.default_reason_phrase `Internal_server_error
    | (#Status.server_error | #Status.client_error) as error ->
        Status.default_reason_phrase error
  in
  let len = Int.to_string (String.length message) in
  let headers = Headers.of_list [("content-length", len)] in
  let body = start_response headers in
  Body.write_string body message ;
  Body.close_writer body

let create_error_handler handler =
  let error_handler ?request error start_response =
    let req_headers =
      match request with
      | None -> Httpaf.Headers.empty
      | Some req -> req.Httpaf.Request.headers
    in
    Lwt.async (fun () ->
        handler req_headers error
        >>= fun (headers, ({Body.length; _} as b)) ->
        let headers =
          match length with
          | None -> headers
          | Some l ->
              Httpaf.Headers.add_unless_exists headers "content-length"
                (Int64.to_string l)
        in
        let res_body = start_response headers in
        Lwt_stream.iter
          (fun s -> Httpaf.Body.write_string res_body s)
          (Body.to_stream b)
        >|= fun () -> Httpaf.Body.close_writer res_body)
  in
  error_handler

type error_handler =
     Httpaf.Headers.t
  -> Httpaf.Server_connection.error
  -> (Httpaf.Headers.t * Body.t) Lwt.t

let read_httpaf_body body =
  Lwt_stream.from (fun () ->
      let promise, wakeup = Lwt.wait () in
      let on_eof () = Lwt.wakeup_later wakeup None in
      let on_read buf ~off ~len =
        let b = Bytes.create len in
        Bigstringaf.blit_to_bytes buf ~src_off:off ~dst_off:0 ~len b ;
        Lwt.wakeup_later wakeup (Some (Bytes.unsafe_to_string b))
      in
      Httpaf.Body.schedule_read body ~on_eof ~on_read ;
      promise)

let httpaf_request_to_request ?body req =
  let headers = req.Httpaf.Request.headers in
  let meth =
    match req.meth with
    | #Httpaf.Method.standard as meth -> meth
    | _ -> failwith "invalid method"
  in
  Rock.Request.make ~headers ?body req.target meth ()

let run server_handler ?error_handler app =
  let {Rock.App.middlewares; handler} = app in
  let filters =
    ListLabels.map ~f:(fun m -> m.Rock.Middleware.filter) middlewares
  in
  let service = Rock.Filter.apply_all filters handler in
  let request_handler reqd =
    Lwt.async (fun () ->
        let req = Httpaf.Reqd.request reqd in
        let req_body = Httpaf.Reqd.request_body reqd in
        let length =
          match Httpaf.Request.body_length req with
          | `Chunked -> None
          | `Fixed l -> Some l
          | `Error _ -> failwith "Bad request"
        in
        let body =
          let stream = read_httpaf_body req_body in
          Lwt.on_termination (Lwt_stream.closed stream) (fun () ->
              Httpaf.Body.close_reader req_body) ;
          Body.of_stream ?length stream
        in
        let write_fixed_response ~headers f status body =
          f reqd (Httpaf.Response.create ~headers status) body ;
          Lwt.return_unit
        in
        let request = httpaf_request_to_request ~body req in
        Lwt.catch
          (fun () ->
            service request
            >>= fun {Rock.Response.body; headers; status; _} ->
            let {Body.content; length} = body in
            let headers =
              match length with
              | None ->
                  Httpaf.Headers.add_unless_exists headers "transfer-encoding"
                    "chunked"
              | Some l ->
                  Httpaf.Headers.add_unless_exists headers "content-length"
                    (Int64.to_string l)
            in
            match content with
            | `Empty ->
                write_fixed_response ~headers Httpaf.Reqd.respond_with_string
                  status ""
            | `String s ->
                write_fixed_response ~headers Httpaf.Reqd.respond_with_string
                  status s
            | `Bigstring b ->
                write_fixed_response ~headers Httpaf.Reqd.respond_with_bigstring
                  status b
            | `Stream s ->
                let rb =
                  Httpaf.Reqd.respond_with_streaming reqd
                    (Httpaf.Response.create ~headers status)
                in
                Lwt_stream.iter (fun s -> Httpaf.Body.write_string rb s) s
                >|= fun () ->
                Httpaf.Body.flush rb (fun () -> Httpaf.Body.close_writer rb))
          (fun exn ->
            Httpaf.Reqd.report_exn reqd exn ;
            Lwt.return_unit))
  in
  let error_handler =
    match error_handler with
    | None -> default_error_handler
    | Some h -> create_error_handler h
  in
  server_handler ~request_handler ~error_handler
