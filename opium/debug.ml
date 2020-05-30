open Lwt.Infix
open Opium_kernel.Rock

let exn_ e = Logs.err (fun f -> f "%s" (Printexc.to_string e))
let log_src = Logs.Src.create "opium.server"

let format_error req exn =
  Format.asprintf
    "\n\
     <html>\n\
    \  <body>\n\
    \  <div id=\"request\"><pre>%a</pre></div>\n\
    \  <div id=\"error\"><pre>%s</pre></div>\n\
    \  </body>\n\
     </html>"
    Request.pp_hum
    req
    (Printexc.to_string exn)
;;

let debug =
  let filter handler req =
    Lwt.catch
      (fun () -> handler req)
      (fun exn ->
        exn_ exn;
        let body = format_error req exn |> Opium_kernel.Body.of_string in
        Lwt.return (Response.make ~status:`Internal_server_error ~body ()))
  in
  Middleware.create ~name:"Debug" ~filter
;;

let trace =
  let filter handler req =
    handler req
    >|= fun response ->
    let status = response.Response.status |> Httpaf.Status.to_code in
    Logs.debug ~src:log_src (fun m -> m "Responded with %d" status);
    response
  in
  Middleware.create ~name:"Trace" ~filter
;;
