open Lwt.Infix
open Opium_kernel.Rock

let exn_ e = Logs.err (fun f -> f "%s" (Printexc.to_string e))

let log_src = Logs.Src.create "opium.server"

let format_error req _exn =
  Printf.sprintf
    "\n\
     <html>\n\
    \  <body>\n\
    \  <div id=\"request\"><pre>%s</pre></div>\n\
    \  <div id=\"error\"><pre>%s</pre></div>\n\
    \  </body>\n\
     </html>"
    (req |> Request.sexp_of_t |> Sexplib.Sexp.to_string_hum)
    (Printexc.to_string _exn)

let debug =
  let filter handler req =
    Lwt.catch
      (fun () -> handler req)
      (fun _exn ->
        exn_ _exn ;
        format_error req _exn
        |> Response.of_string_body ~code:`Internal_server_error
        |> Lwt.return)
  in
  Middleware.create ~name:"Debug" ~filter

let trace =
  let filter handler req =
    handler req
    >|= fun response ->
    let code = response |> Response.code |> Httpaf.Status.to_code in
    Logs.debug ~src:log_src (fun m -> m "Responded with %d" code) ;
    response
  in
  Middleware.create ~name:"Trace" ~filter
