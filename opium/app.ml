open Core.Std
open Async.Std

module Rock = Opium_rock
open Rock
module Co = Cohttp

module Make (Router : App_intf.Router) = struct
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
       Log.Global.debug
         "Warning: you're using [any] attempting to bind to '%s' but your list
        of http methods is empty route"
         route);
    let route = Router.Route.of_string route in
    methods |> List.fold_left ~init:t
                 ~f:(fun app meth -> app |> register ~meth ~route ~action)

  let all = any [`GET;`POST;`DELETE;`PUT;`PATCH;`HEAD;`OPTIONS]

  let to_rock app =
    Rock.App.create ~middlewares:(attach_middleware app)
      ~handler:(app.not_found)

  let start ?(on_handler_error=`Ignore) app =
    let middlewares = attach_middleware app in
    if app.verbose then
      Log.Global.info "Running on port: %d%s" app.port
        (if app.debug then " (debug)" else "");
    let port = app.port in
    let app = Rock.App.create ~middlewares ~handler:app.not_found in
    app |> Rock.App.run ~port ~on_handler_error >>| ignore |> don't_wait_for;
    Scheduler.go ()

  type 'a runner = int -> string -> bool -> bool -> bool -> bool -> bool -> bool -> 'a
  type 'a action = (unit -> 'a Deferred.t) runner
  type 'a spec = ('a runner, 'a) Command.Spec.t

  let spec ?(on_handler_error=`Ignore) app' =
    let summary = name app' in
    let open Command.Spec in
    object
      method summary = summary

      method spec =
        empty
        +> flag "-p" (optional_with_default 3000 int)
             ~doc:"port number to listen"
        +> flag "-h" (optional_with_default "0.0.0.0" string)
             ~doc:"interface to listen"
        +> flag "-r" no_arg ~doc: "print routes"
        +> flag "-m" no_arg ~doc:"print middleware stack"
        +> flag "-d" no_arg ~doc:"enable debug information"
        +> flag "-v" no_arg ~doc:"enable verbose mode"
        +> flag "-xi" no_arg ~doc:"Ignore errors (conflicts with -xr and -d)"
        +> flag "-xr" no_arg ~doc:"Raise on errors (conflicts with -xi)"

      method action =
        (fun port host print_routes print_middleware debug verbose
          ignore_e raise_e () ->
          let app' = { app' with debug ; verbose } in
          let app = to_rock app' in
          let err s =
            print_endline s;
            Shutdown.exit 1
          in
          let on_handler_error =
            match ignore_e, raise_e with
            | true, true   -> err "cannot provide both ignore and raise"
            | true, false  -> return `Ignore
            | false, true  -> return `Raise
            | false, false -> return on_handler_error in
          on_handler_error >>= fun on_handler_error ->
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
             don't_wait_for @@ Shutdown.exit 0;
           end;
           if print_middleware then begin
             print_endline "Active middleware:";
             app
             |> Rock.App.middlewares
             |> List.map ~f:(Fn.compose Info.to_string_hum Rock.Middleware.name)
             |> List.iter ~f:(fun name ->
               printf "> %s \n" name);
             don't_wait_for @@ Shutdown.exit 0;
           end
          );
          (if debug || verbose then
             Log.Global.info "Listening on %s:%s" host (Int.to_string port));
          (* for now we will ignore errors in the on_handler_error because
             they are revealed using the debug middleware anyway *)
          app |> Rock.App.run ~port ~on_handler_error
          >>| ignore >>= never
        )
    end

  let command ?on_handler_error app =
    let spec = spec ?on_handler_error app in
    Command.async_basic
      ~summary:spec#summary
      spec#spec spec#action

  type body = [
    | `Html of Cow.Html.t
    | `Json of Cow.Json.t
    | `Xml of Cow.Xml.t
    | `String of string ]

  module Response_helpers = struct
    open Cow

    let content_type ct = Cohttp.Header.init_with "Content-Type" ct
    let json_header     = content_type "application/json"
    let xml_header      = content_type "application/xml"
    let html_header     = content_type "text/html"

    let respond_with_string = Response.of_string_body

    let respond ?headers ?(code=`OK) = function
      | `String s -> respond_with_string ?headers ~code s
      | `Json s ->
        respond_with_string ~code ~headers:json_header (Json.to_string s)
      | `Html s ->
        respond_with_string ~code ~headers:html_header (Html.to_string s)
      | `Xml s ->
        respond_with_string ~code ~headers:xml_header (Xml.to_string s)

    let respond' ?headers ?code s =
      s |> respond ?headers ?code |> return

    let redirect ?headers uri =
      let headers = Cohttp.Header.add_opt headers "Location" (Uri.to_string uri) in
      Response.create ~headers ~code:`Found ()

    let redirect' ?headers uri =
      uri |> redirect ?headers |> return
  end

  module Request_helpers = struct
    open Cow
    let json_exn req =
      req |> Request.body |> Cohttp_async.Body.to_string >>| Json.of_string
    let string_exn req = 
      req |> Request.body |> Cohttp_async.Body.to_string
    let pairs_exn req = 
      req |> Request.body |> Cohttp_async.Body.to_string >>| Uri.query_of_encoded
  end

  let json_of_body_exn = Request_helpers.json_exn
  let string_of_body_exn = Request_helpers.string_exn
  let urlencoded_pairs_of_body = Request_helpers.pairs_exn
  let param            = Router.param
  let splat            = Router.splat
  let respond          = Response_helpers.respond
  let respond'         = Response_helpers.respond'
  let redirect         = Response_helpers.redirect
  let redirect'        = Response_helpers.redirect'
end

include Make(Router)
