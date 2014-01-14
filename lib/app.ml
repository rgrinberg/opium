open Core.Std
open Async.Std
open Rock

module Co = Cohttp

module Response_helpers = struct
  open Cow

  let content_type ct = Cohttp.Header.init_with "Content-Type" ct
  let json_header = content_type "application/json"
  let xml_header = content_type "application/xml"
  let html_header = content_type "text/html"

  let respond_with_string = Response.string_body

  let respond ?headers ?(code=`OK) = function
    | `String s -> respond_with_string ?headers ~code s
    | `Json s ->
      respond_with_string ~headers:json_header (Json.to_string s)
    | `Html s ->
      respond_with_string ~headers:html_header (Html.to_string s)
    | `Xml s ->
      respond_with_string ~headers:xml_header (Xml.to_string s)

  let respond' ?headers ?code s =
    s |> respond ?headers ?code |> return
end

type 'a t = {
  routes : 'a Router.endpoint Router.Method_bin.t;
  not_found : Handler.t;
} with fields

type builder = Handler.t t -> unit

type route = string -> Handler.t -> builder

let register app ~meth ~route ~action =
  Router.Method_bin.add app.routes meth {Router.meth; route; action}

let app () = 
  { routes=Router.Method_bin.create ();
    not_found=Handler.not_found }

let public_path root requested =
  let asked_path = Filename.concat root requested in
  Option.some_if (String.is_prefix asked_path ~prefix:root) asked_path

let param = Middleware_pack.Router.param
let respond = Response_helpers.respond
let respond' = Response_helpers.respond'

let get route action =
  register ~meth:`GET ~route:(Router.Route.create route) ~action
let post route action =
  register ~meth:`POST ~route:(Router.Route.create route) ~action
let delete route action =
  register ~meth:`DELETE ~route:(Router.Route.create route) ~action
let put route action =
  register ~meth:`PUT ~route:(Router.Route.create route) ~action

let start ?(verbose=true) ?(debug=true) ?(port=3000)
      ?(extra_middlewares=[]) endpoints =
  let app = app () in
  endpoints |> List.iter ~f:(fun build -> build app);
  let middlewares = (Middleware_pack.Router.m app.routes)::extra_middlewares in
  let middlewares =
    middlewares @ (if debug then [Middleware_pack.Debug.m] else [])
  in
  if verbose then
    Log.Global.info "Running on port: %d%s" port (if debug then " (debug)" else "");
  let app = Rock.App.create ~middlewares ~handler:Handler.default in
  app |> Rock.App.run ~port >>| ignore |> don't_wait_for;
  Scheduler.go ()
