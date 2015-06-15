open Core_kernel.Std
open Opium_misc

module Rock = Opium_rock
open Rock

type t = {
  port:        int;
  debug:       bool;
  verbose:     bool;
  routes :     (Co.Code.meth * Route.t * Handler.t) list;
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
    (if verbose then Some Debug.trace else None);
    (if debug then Some Debug.debug else None);
  ] |> List.filter_opt

let port port t = { t with port }
let cmd_name name t = { t with name }

let middleware m app =
  { app with middlewares=m::app.middlewares }

let public_path root requested =
  let asked_path = Filename.concat root requested in
  Option.some_if (String.is_prefix asked_path ~prefix:root) asked_path

let action meth route action =
  register ~meth ~route:(Route.of_string route) ~action

let get route action =
  register ~meth:`GET ~route:(Route.of_string route) ~action
let post route action =
  register ~meth:`POST ~route:(Route.of_string route) ~action
let delete route action =
  register ~meth:`DELETE ~route:(Route.of_string route) ~action
let put route action =
  register ~meth:`PUT ~route:(Route.of_string route) ~action

let patch route action =
  register ~meth:`PATCH ~route:(Route.of_string route) ~action
let head route action =
  register ~meth:`HEAD ~route:(Route.of_string route) ~action
let options route action =
  register ~meth:`OPTIONS ~route:(Route.of_string route) ~action

let any methods route action t =
  (if List.is_empty methods then
     Lwt_log.ign_warning_f
       "Warning: you're using [any] attempting to bind to '%s' but your list
        of http methods is empty route" route);
  let route = Route.of_string route in
  methods |> List.fold_left ~init:t
               ~f:(fun app meth -> app |> register ~meth ~route ~action)

let all = any [`GET;`POST;`DELETE;`PUT;`PATCH;`HEAD;`OPTIONS]

let name app = app.name

let to_rock app =
  if app.verbose then
    Lwt_log.(add_rule "*" Info);
  Rock.App.create ~middlewares:(attach_middleware app)
    ~handler:app.not_found

let print_routes_f routes =
  let routes_tbl = Hashtbl.Poly.create () in
  routes |> List.iter ~f:(fun (meth, route, _) ->
    Hashtbl.add_multi routes_tbl ~key:route ~data:meth);
  printf "%d Routes:\n" (Hashtbl.length routes_tbl);
  Hashtbl.iter routes_tbl ~f:(fun ~key ~data ->
    printf "> %s (%s)\n" (Route.to_string key)
      (data
       |> List.map ~f:Cohttp.Code.string_of_method
       |> String.concat ~sep:" ")
  )

let print_middleware_f middlewares =
  print_endline "Active middleware:";
  middlewares
  |> List.map ~f:(Fn.compose Info.to_string_hum Rock.Middleware.name)
  |> List.iter ~f:(printf "> %s \n")

let print_routes app debug verbose port =
  let app = { app with debug ; verbose ; port } in
  app |> routes |> print_routes_f

let print_middleware app debug verbose port =
  let app = { app with debug ; verbose ; port } in
  let rock_app = to_rock app in
  rock_app |> Rock.App.middlewares |> print_middleware_f

type body = [
  | `Html of string
  | `Json of Ezjsonm.t
  | `Xml of string
  | `String of string ]

module Response_helpers = struct

  let content_type ct h = Cohttp.Header.add_opt h "Content-Type" ct
  let json_header       = content_type "application/json"
  let xml_header        = content_type "application/xml"
  let html_header       = content_type "text/html"

  let respond_with_string = Response.of_string_body

  let respond ?headers ?(code=`OK) = function
    | `String s -> respond_with_string ?headers ~code s
    | `Json s ->
      respond_with_string ~code ~headers:(json_header headers) (Ezjsonm.to_string s)
    | `Html s ->
      respond_with_string ~code ~headers:(html_header headers) s
    | `Xml s ->
      respond_with_string ~code ~headers:(xml_header headers) s

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

