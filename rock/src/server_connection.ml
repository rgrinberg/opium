open Lwt.Syntax

exception Halt of Response.t

let halt response = raise (Halt response)

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
  let headers = Headers.of_list [ "Content-Length", len ] in
  let body = start_response headers in
  Body.write_string body message;
  Body.close_writer body
;;

let create_error_handler handler =
  let error_handler ?request error start_response =
    let req_headers =
      match request with
      | None -> Httpaf.Headers.empty
      | Some req -> req.Httpaf.Request.headers
    in
    Lwt.async (fun () ->
        let* headers, body = handler req_headers error in
        let headers =
          match Body.length body with
          | None -> headers
          | Some l ->
            Httpaf.Headers.add_unless_exists headers "Content-Length" (Int64.to_string l)
        in
        let res_body = start_response headers in
        let+ () =
          Lwt_stream.iter
            (fun s -> Httpaf.Body.write_string res_body s)
            (Body.to_stream body)
        in
        Httpaf.Body.close_writer res_body)
  in
  error_handler
;;

type error_handler =
  Httpaf.Headers.t -> Httpaf.Server_connection.error -> (Httpaf.Headers.t * Body.t) Lwt.t

let read_httpaf_body body =
  Lwt_stream.from (fun () ->
      let promise, wakeup = Lwt.wait () in
      let on_eof () = Lwt.wakeup_later wakeup None in
      let on_read buf ~off ~len =
        let b = Bytes.create len in
        Bigstringaf.blit_to_bytes buf ~src_off:off ~dst_off:0 ~len b;
        Lwt.wakeup_later wakeup (Some (Bytes.unsafe_to_string b))
      in
      Httpaf.Body.schedule_read body ~on_eof ~on_read;
      promise)
;;

let httpaf_request_to_request ?body req =
  let headers =
    req.Httpaf.Request.headers |> Httpaf.Headers.to_list |> Httpaf.Headers.of_rev_list
  in
  Request.make ~headers ?body req.target req.meth
;;

let run server_handler ?error_handler app =
  let { App.middlewares; handler } = app in
  let filters = ListLabels.map ~f:(fun m -> m.Middleware.filter) middlewares in
  let service = Filter.apply_all filters handler in
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
              Httpaf.Body.close_reader req_body);
          Body.of_stream ?length stream
        in
        let write_fixed_response ~headers f status body =
          f reqd (Httpaf.Response.create ~headers status) body;
          Lwt.return_unit
        in
        let request = httpaf_request_to_request ~body req in
        Lwt.catch
          (fun () ->
            let* { Response.body; headers; status; _ } =
              Lwt.catch
                (fun () -> service request)
                (function
                  | Halt response -> Lwt.return response
                  | exn -> Lwt.fail exn)
            in
            let { Body.length; _ } = body in
            let headers =
              match length with
              | None ->
                Httpaf.Headers.add_unless_exists headers "Transfer-Encoding" "chunked"
              | Some l ->
                Httpaf.Headers.add_unless_exists
                  headers
                  "Content-Length"
                  (Int64.to_string l)
            in
            match body.content with
            | `Empty ->
              write_fixed_response ~headers Httpaf.Reqd.respond_with_string status ""
            | `String s ->
              write_fixed_response ~headers Httpaf.Reqd.respond_with_string status s
            | `Bigstring b ->
              write_fixed_response ~headers Httpaf.Reqd.respond_with_bigstring status b
            | `Stream s ->
              let rb =
                Httpaf.Reqd.respond_with_streaming
                  reqd
                  (Httpaf.Response.create ~headers status)
              in
              let+ () = Lwt_stream.iter (fun s -> Httpaf.Body.write_string rb s) s in
              Httpaf.Body.flush rb (fun () -> Httpaf.Body.close_writer rb))
          (fun exn ->
            Httpaf.Reqd.report_exn reqd exn;
            Lwt.return_unit))
  in
  let error_handler =
    match error_handler with
    | None -> default_error_handler
    | Some h -> create_error_handler h
  in
  server_handler ~request_handler ~error_handler
;;
