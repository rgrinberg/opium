open Core.Std
open Async.Std

module Co = Cohttp

module Response_helpers = struct
  open Cow

  let content_type ct = Cohttp.Header.init_with "Content-Type" ct
  let json_header = content_type "application/json"
  let xml_header = content_type "application/xml"
  let html_header = content_type "text/html"

  let respond_with_string = Rock.Response.string_body

  let respond ?headers ?(code=`OK) = Fn.compose return @@ function
      | `String s -> respond_with_string ?headers ~code s
      | `Json s ->
        respond_with_string ~headers:json_header (Json.to_string s)
      | `Html s ->
        respond_with_string ~headers:html_header (Html.to_string s)
      | `Xml s ->
        respond_with_string ~headers:xml_header (Xml.to_string s)
end

type 'a filter = 'a -> 'a Deferred.t

type 'a t = {
  mutable before_filters : Rock.Request.t filter list;
  mutable after_filters : Rock.Response.t filter list;
  routes : 'a Router.endpoint Router.Method_bin.t;
  not_found : Rock.Handler.t;
  public_dir : Static.t option;
} with fields

type 'a builder = 'a t -> unit

let build : 'a t -> 'a builder -> unit = fun t builder -> builder t

let cons_before app filter =
  app.before_filters <- (filter::app.before_filters)

let cons_after app filter =
  app.after_filters <- (filter::app.after_filters)

let register app ~meth ~route ~action =
  Router.Method_bin.add app.routes meth {Router.meth; route; action}

let app () = 
  let public_dir =
    let open Static in
    Some { prefix="/public"; local_path="./public" } in
  { before_filters=[];
    routes=Router.Method_bin.create ();
    after_filters=[];
    public_dir;
    not_found=Rock.Handler.not_found }

let public_path root requested =
  let asked_path = Filename.concat root requested in
  Option.some_if (String.is_prefix asked_path ~prefix:root) asked_path

let apply_filters filters req = (* not pretty... *)
  let acc = ref req in
  filters |> List.iter ~f:(fun filter ->
      !acc >>> (fun req -> acc := filter req));
  !acc

let order_filters app =
  { app with before_filters=(List.rev app.before_filters);
             after_filters=(List.rev app.after_filters); }

let param = Middleware_pack.Router.param
let respond = Response_helpers.respond

let get route action =
  register ~meth:`GET ~route:(Router.Route.create route) ~action
let post route action =
  register ~meth:`POST ~route:(Router.Route.create route) ~action
let delete route action =
  register ~meth:`DELETE ~route:(Router.Route.create route) ~action
let put route action =
  register ~meth:`PUT ~route:(Router.Route.create route) ~action

let app = app

let before action app = cons_before app action
let after action app = cons_after app action

let start ?(verbose=true) ?(debug=true) ?(port=3000) ?(extra_middlewares=[])
    endpoints =
  let app = app () in
  endpoints |> List.iter ~f:(build app);
  let middlewares = extra_middlewares @ [Middleware_pack.Router.m app.routes] in
  let middlewares =
    if debug
    then Middleware_pack.Debug.m::middlewares
    else middlewares
  in
  if verbose then
    Log.Global.info "Running on port: %d%s" port (if debug then " (debug)" else "");
  let app = Rock.App.create ~middlewares ~handler:Rock.Handler.default in
  app |> Rock.App.run ~port >>| ignore |> don't_wait_for;
  Scheduler.go ()
