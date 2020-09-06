(** [Logger] logs the requests and their response.

    The request's target URL and the HTTP method are logged with the "info" verbosity.
    Once the request has been processed successfully, the response's HTTP code is logged
    with the "info" verbosity.

    If the body of the request or the response are a string (as opposed to a stream),
    their content is logged with the "debug" verbosity.

    If an error occurs while processing the request, the error is logged with an "error"
    verbosity.

    Note that this middleware is best used as the first middleware of the pipeline because
    any previous middleware might change the request / response after [Logger] has been
    applied. *)

let log_src = Logs.Src.create "opium.server"

module Log = (val Logs.src_log log_src : Logs.LOG)

let respond ?time_f handler req =
  let open Lwt.Syntax in
  match time_f with
  | Some time_f ->
    let f () = handler req in
    let span, response_lwt = time_f f in
    let+ response = response_lwt in
    let code = response.Response.status |> Status.to_string in
    Log.info (fun m -> m "Responded with HTTP code %s in %a" code Mtime.Span.pp span);
    Log.debug (fun m -> m "%a" Response.pp_hum response);
    response
  | None ->
    let+ response = handler req in
    let code = response.Response.status |> Status.to_string in
    Log.info (fun m -> m "Responded with HTTP code %s" code);
    Log.debug (fun m -> m "%a" Response.pp_hum response);
    response
;;

let m ?time_f () =
  let filter handler req =
    let meth = Method.to_string req.Request.meth in
    let uri = req.Request.target |> Uri.of_string |> Uri.path_and_query in
    Logs.info ~src:log_src (fun m -> m "Received %s %S" meth uri);
    Logs.debug ~src:log_src (fun m -> m "%a" Request.pp_hum req);
    Lwt.catch
      (fun () -> respond ?time_f handler req)
      (fun exn ->
        Logs.err ~src:log_src (fun f -> f "%s" (Nifty.Exn.to_string exn));
        Lwt.fail exn)
  in
  Rock.Middleware.create ~name:"Logger" ~filter
;;
