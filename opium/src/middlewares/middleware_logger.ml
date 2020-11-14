open Import

let log_src = Logs.Src.create "opium.server"

module Log = (val Logs.src_log log_src : Logs.LOG)

let body_to_string ?(content_type = "text/plain") ?(max_len = 1000) body =
  let open Lwt.Syntax in
  let lhs, rhs =
    match String.split_on_char ~sep:'/' content_type with
    | [ lhs; rhs ] -> lhs, rhs
    | _ -> "application", "octet-stream"
  in
  match lhs, rhs with
  | "text", _ | "application", "json" | "application", "x-www-form-urlencoded" ->
    let+ s = Body.copy body |> Body.to_string in
    if String.length s > max_len
    then
      String.sub s ~pos:0 ~len:(min (String.length s) max_len)
      ^ Format.asprintf " [truncated %d characters]" (String.length s - max_len)
    else s
  | _ -> Lwt.return ("<" ^ content_type ^ ">")
;;

let request_to_string (request : Request.t) =
  let open Lwt.Syntax in
  let content_type = Request.content_type request in
  let+ body_string = body_to_string ?content_type request.body in
  Format.asprintf
    "%s %s %s\n%s\n\n%s\n%!"
    (Method.to_string request.meth)
    request.target
    (Version.to_string request.version)
    (Headers.to_string request.headers)
    body_string
;;

let response_to_string (response : Response.t) =
  let open Lwt.Syntax in
  let content_type = Response.content_type response in
  let+ body_string = body_to_string ?content_type response.body in
  Format.asprintf
    "%a %a %s\n%a\n%s\n%!"
    Version.pp_hum
    response.version
    Status.pp_hum
    response.status
    (Option.value ~default:"" response.reason)
    Headers.pp_hum
    response.headers
    body_string
;;

let respond handler req =
  let time_f f =
    let t1 = Mtime_clock.now () in
    let x = f () in
    let t2 = Mtime_clock.now () in
    let span = Mtime.span t1 t2 in
    span, x
  in
  let open Lwt.Syntax in
  let f () = handler req in
  let span, response_lwt = time_f f in
  let* response = response_lwt in
  let code = response.Response.status |> Status.to_string in
  Log.info (fun m -> m "Responded with HTTP code %s in %a" code Mtime.Span.pp span);
  let+ response_string = response_to_string response in
  Log.debug (fun m -> m "%s" response_string);
  response
;;

let m =
  let open Lwt.Syntax in
  let filter handler req =
    let meth = Method.to_string req.Request.meth in
    let uri = req.Request.target |> Uri.of_string |> Uri.path_and_query in
    Logs.info ~src:log_src (fun m -> m "Received %s %S" meth uri);
    let* request_string = request_to_string req in
    Logs.debug ~src:log_src (fun m -> m "%s" request_string);
    Lwt.catch
      (fun () -> respond handler req)
      (fun exn ->
        Logs.err ~src:log_src (fun f -> f "%s" (Nifty.Exn.to_string exn));
        Lwt.fail exn)
  in
  Rock.Middleware.create ~name:"Logger" ~filter
;;
