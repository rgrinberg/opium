open Core.Std
open Opium_misc
open Opium_rock
module Rock = Opium_rock

let exn_ e = Lwt_log.ign_error_f "%s" (Exn.to_string e)

let format_error req _exn = sprintf "
<html>
  <body>
  <div id=\"request\"><pre>%s</pre></div>
  <div id=\"error\"><pre>%s</pre></div>
  </body>
</html>" (req |> Request.sexp_of_t |> Sexp.to_string_hum) (Exn.to_string _exn)

let debug =
  let filter handler req =
    Lwt.catch (fun () -> handler req) (fun _exn ->
      exn_ _exn;
      let body = format_error req _exn in
      return @@ Response.of_string_body ~code:`Internal_server_error body)
  in Rock.Middleware.create ~name:(Info.of_string "Debug") ~filter

let trace =
  let filter handler req =
    handler req >>| fun response ->
    let code = response |> Response.code |> Cohttp.Code.code_of_status in
    Lwt_log.ign_debug_f "Responded with %d" code;
    response
  in Rock.Middleware.create ~name:(Info.of_string "Trace") ~filter
