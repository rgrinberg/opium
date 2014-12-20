open Core_kernel.Std
open Opium_misc

module Rock = Opium_rock
open Rock

type t = {
  port:        int;
  debug:       bool;
  verbose:     bool;
  routes :     (Co.Code.meth * Router.Route.t * Handler.t) list;
  middlewares: Middleware.t list;
  name:        string;
  not_found :  Handler.t;
} with fields, sexp_of

type builder = t -> t with sexp_of

type route = string -> Handler.t -> builder with sexp_of

let register app ~meth ~route ~action =
  { app with routes=(meth, route, action)::app.routes }

let empty =
  { name        = "Opium Default Name";
    port        = 3000;
    debug       = false;
    verbose     = false;
    routes      = [];
    middlewares = [];
    not_found   = Handler.not_found }

let create_router routes =
  let router = Router.create () in
  routes
  |> List.iter ~f:(fun (meth, route, action) ->
    Router.add router ~meth ~route ~action);
  router

let attach_middleware { verbose ; debug ; routes ; middlewares ; _  } =
  [ Some (routes |> create_router |> Router.m) ] @
  (List.map ~f:Option.some middlewares) @
  [
    (if verbose then Some Middleware_pack.trace else None);
    (if debug then Some Middleware_pack.debug else None);
  ] |> List.filter_opt

let port port t = { t with port }
let cmd_name name t = { t with name }

let middleware m app =
  { app with middlewares=m::app.middlewares }

let public_path root requested =
  let asked_path = Filename.concat root requested in
  Option.some_if (String.is_prefix asked_path ~prefix:root) asked_path

let action meth route action =
  register ~meth ~route:(Router.Route.of_string route) ~action

let get route action =
  register ~meth:`GET ~route:(Router.Route.of_string route) ~action
let post route action =
  register ~meth:`POST ~route:(Router.Route.of_string route) ~action
let delete route action =
  register ~meth:`DELETE ~route:(Router.Route.of_string route) ~action
let put route action =
  register ~meth:`PUT ~route:(Router.Route.of_string route) ~action

let patch route action =
  register ~meth:`PATCH ~route:(Router.Route.of_string route) ~action
let head route action =
  register ~meth:`HEAD ~route:(Router.Route.of_string route) ~action
let options route action =
  register ~meth:`OPTIONS ~route:(Router.Route.of_string route) ~action

let any methods route action t =
  (if List.is_empty methods then
     Lwt_log.ign_warning_f
       "Warning: you're using [any] attempting to bind to '%s' but your list
        of http methods is empty route" route);
  let route = Router.Route.of_string route in
  methods |> List.fold_left ~init:t
               ~f:(fun app meth -> app |> register ~meth ~route ~action)

let all = any [`GET;`POST;`DELETE;`PUT;`PATCH;`HEAD;`OPTIONS]

let to_rock app =
  Rock.App.create ~middlewares:(attach_middleware app)
    ~handler:(app.not_found)

let start app =
  let middlewares = attach_middleware app in
  if app.verbose then
    Lwt_log.ign_info_f "Running on port: %d%s" app.port
      (if app.debug then " (debug)" else "");
  let port = app.port in
  let app = Rock.App.create ~middlewares ~handler:app.not_found in
  app |> Rock.App.run ~port |> Lwt_unix.run

let cmd_run app' port host print_routes print_middleware debug verbose (errors : bool) =
  let app' = { app' with debug ; verbose } in
  let app = to_rock app' in
  (if print_routes then begin
     let routes_tbl = Hashtbl.Poly.create () in
     app' |> routes |> List.iter ~f:(fun (meth, route, _) ->
       Hashtbl.add_multi routes_tbl ~key:route ~data:meth);
     printf "%d Routes:\n" (Hashtbl.length routes_tbl);
     Hashtbl.iter routes_tbl ~f:(fun ~key ~data ->
       printf "> %s (%s)\n" (Router.Route.to_string key)
         (data
          |> List.map ~f:Cohttp.Code.string_of_method
          |> String.concat ~sep:" ")
     );
     exit 0;
   end;
   if print_middleware then begin
     print_endline "Active middleware:";
     app
     |> Rock.App.middlewares
     |> List.map ~f:(Fn.compose Info.to_string_hum Rock.Middleware.name)
     |> List.iter ~f:(printf "> %s \n");
     exit 0
   end
  );
  (if debug || verbose then
     Lwt_log.ign_info_f "Listening on %s:%d" host port);
  app |> Rock.App.run ~port |> Lwt_main.run

module Cmds = struct
  open Cmdliner

  let routes =
    let doc = "print routes" in
    Arg.(value & flag & info ["r"; "routes"] ~doc)
  let middleware =
    let doc = "print middleware stack" in
    Arg.(value & flag & info ["m"; "middlware"] ~doc)
  let port =
    let doc = "port" in
    Arg.(value & opt int 8080 & info ["m"; "middleware"] ~doc)
  let interface =
    let doc = "interface" in
    Arg.(value & opt string "0.0.0.0" & info ["i"; "interface"] ~doc)
  let debug =
    let doc = "enable debug information" in
    Arg.(value & flag & info ["d"; "debug"] ~doc)
  let verbose =
    let doc = "enable verbose mode" in
    Arg.(value & flag & info ["v"; "verbose"] ~doc)
  let errors =
    let doc = "raise on errors. default is print" in
    Arg.(value & flag & info ["f"; "fatal"] ~doc)
end

let run_command =
  let open Cmds in
  let open Cmdliner.Term in
  fun app -> pure cmd_run
             $ (pure app)
             $ port
             $ interface
             $ routes
             $ middleware
             $ debug
             $ verbose
             $ errors

type body = [
  | `Html of string
  | `Json of Ezjsonm.t
  | `Xml of string
  | `String of string ]

module Response_helpers = struct

  let content_type ct = Cohttp.Header.init_with "Content-Type" ct
  let json_header     = content_type "application/json"
  let xml_header      = content_type "application/xml"
  let html_header     = content_type "text/html"

  let respond_with_string = Response.of_string_body

  let respond ?headers ?(code=`OK) = function
    | `String s -> respond_with_string ?headers ~code s
    | `Json s ->
      respond_with_string ~code ~headers:json_header (Ezjsonm.to_string s)
    | `Html s ->
      respond_with_string ~code ~headers:html_header s
    | `Xml s ->
      respond_with_string ~code ~headers:xml_header s

  let respond' ?headers ?code s =
    s |> respond ?headers ?code |> return

  let redirect ?headers uri =
    let headers = Cohttp.Header.add_opt headers "Location" (Uri.to_string uri) in
    Response.create ~headers ~code:`Found ()

  let redirect' ?headers uri =
    uri |> redirect ?headers |> return
end

module Request_helpers = struct
  let json_exn req =
    req |> Request.body |> Body.to_string >>| Ezjsonm.from_string
  let string_exn req =
    req |> Request.body |> Body.to_string
  let pairs_exn req =
    req |> Request.body |> Body.to_string >>| Uri.query_of_encoded
end

let json_of_body_exn         = Request_helpers.json_exn
let string_of_body_exn       = Request_helpers.string_exn
let urlencoded_pairs_of_body = Request_helpers.pairs_exn
let param                    = Router.param
let splat                    = Router.splat
let respond                  = Response_helpers.respond
let respond'                 = Response_helpers.respond'
let redirect                 = Response_helpers.redirect
let redirect'                = Response_helpers.redirect'

