module Rock = Opium_kernel.Rock
module Router = Opium_kernel.Router
module Route = Opium_kernel.Route
module Server = Httpaf_lwt_unix.Server
module Reqd = Httpaf.Reqd
open Lwt.Syntax

let err_invalid_host host =
  Lwt.fail_invalid_arg ("Could not get host info for `" ^ host ^ "`")
;;

let run_unix ?ssl t ~host ~port =
  let _mode =
    match ssl with
    | None -> `TCP (`Port port)
    | Some (c, k) -> `TLS (c, k, `No_password, `Port port)
  in
  let* host_entry =
    Lwt.catch
      (fun () -> Lwt_unix.gethostbyname host)
      (function
        | Not_found -> err_invalid_host host
        | exn -> Lwt.fail exn)
  in
  let inet_addr = host_entry.h_addr_list.(0) in
  let listen_address = Unix.ADDR_INET (inet_addr, port) in
  let connection_handler addr fd =
    let f ~request_handler ~error_handler =
      Httpaf_lwt_unix.Server.create_connection_handler
        ~request_handler:(fun _ -> request_handler)
        ~error_handler:(fun _ -> error_handler)
        addr
        fd
    in
    Opium_kernel.Server_connection.run f t
  in
  Lwt_io.establish_server_with_client_socket listen_address connection_handler
;;

type t =
  { host : string
  ; port : int
  ; ssl : ([ `Crt_file_path of string ] * [ `Key_file_path of string ]) option
  ; debug : bool
  ; verbose : bool
  ; routes : (Httpaf.Method.t * Route.t * Rock.Handler.t) list
  ; middlewares : Rock.Middleware.t list
  ; name : string
  ; not_found : Rock.Handler.t
  }

type builder = t -> t
type route = string -> Rock.Handler.t -> builder

let register app ~meth ~route ~action =
  { app with routes = (meth, route, action) :: app.routes }
;;

let default_not_found _ =
  let open Opium_kernel in
  Lwt.return
    (Response.make
       ~status:`Not_found
       ~body:(Body.of_string "<html><body><h1>404 - Not found</h1></body></html>")
       ())
;;

let empty =
  { name = "Opium Default Name"
  ; host = "0.0.0.0"
  ; port = 3000
  ; ssl = None
  ; debug = false
  ; verbose = false
  ; routes = []
  ; middlewares = []
  ; not_found = default_not_found
  }
;;

let create_router routes =
  ListLabels.fold_left routes ~init:Router.empty ~f:(fun router (meth, route, action) ->
      Router.add router ~meth ~route ~action)
;;

let attach_middleware { verbose; debug; routes; middlewares; _ } =
  let rec filter_opt = function
    | [] -> []
    | None :: l -> filter_opt l
    | Some x :: l -> x :: filter_opt l
  in
  [ Some (routes |> create_router |> Router.m) ]
  @ ListLabels.map ~f:Option.some middlewares
  @ [ (if verbose then Some Middleware.logger else None)
    ; (if debug then Some Middleware.debugger else None)
    ]
  |> filter_opt
;;

let port port t = { t with port }
let host host t = { t with host }
let ssl ~cert ~key t = { t with ssl = Some (`Crt_file_path cert, `Key_file_path key) }
let cmd_name name t = { t with name }
let middleware m app = { app with middlewares = m :: app.middlewares }
let action meth route action = register ~meth ~route:(Route.of_string route) ~action

let not_found action t =
  let open Opium_kernel in
  let action req =
    let+ headers, body = action req in
    Response.make ~headers ~body ~status:`Not_found ()
  in
  { t with not_found = action }
;;

let get route action = register ~meth:`GET ~route:(Route.of_string route) ~action
let post route action = register ~meth:`POST ~route:(Route.of_string route) ~action
let delete route action = register ~meth:`DELETE ~route:(Route.of_string route) ~action
let put route action = register ~meth:`PUT ~route:(Route.of_string route) ~action

let patch route action =
  register ~meth:(`Other "PATCH") ~route:(Route.of_string route) ~action
;;

(* let patch route action = *)
(* register ~meth:`PATCH ~route:(Route.of_string route) ~action *)
let head route action = register ~meth:`HEAD ~route:(Route.of_string route) ~action
let options route action = register ~meth:`OPTIONS ~route:(Route.of_string route) ~action

let any methods route action t =
  if List.length methods = 0
  then
    Logs.warn (fun f ->
        f
          "Warning: you're using [any] attempting to bind to '%s' but your list\n\
          \        of http methods is empty route"
          route);
  let route = Route.of_string route in
  methods
  |> ListLabels.fold_left ~init:t ~f:(fun app meth ->
         app |> register ~meth ~route ~action)
;;

let all = any [ `GET; `POST; `DELETE; `PUT; `HEAD; `OPTIONS ]

let to_rock app =
  Rock.App.create ~middlewares:(attach_middleware app) ~handler:app.not_found ()
;;

let start app =
  let middlewares = attach_middleware app in
  (* if app.verbose then *)
  (* Logs.info.(add_rule "*" Info); *)
  Logs.info (fun f ->
      f
        "Starting Opium on %s:%d%s..."
        app.host
        app.port
        (if app.debug then " (debug)" else ""));
  let host = app.host in
  let port = app.port in
  let ssl = app.ssl in
  let app = Rock.App.create ~middlewares ~handler:app.not_found () in
  run_unix ~host ~port ?ssl app
;;

let hashtbl_add_multi tbl x y =
  let l =
    try Hashtbl.find tbl x with
    | Not_found -> []
  in
  Hashtbl.replace tbl x (y :: l)
;;

let print_routes_f routes =
  let routes_tbl = Hashtbl.create 64 in
  routes
  |> ListLabels.iter ~f:(fun (meth, route, _) -> hashtbl_add_multi routes_tbl route meth);
  Printf.printf "%d Routes:\n" (Hashtbl.length routes_tbl);
  Hashtbl.iter
    (fun key data ->
      Printf.printf
        "> %s (%s)\n"
        (Route.to_string key)
        (data
        |> ListLabels.map ~f:(fun m ->
               Httpaf.Method.to_string m |> String.uppercase_ascii)
        |> String.concat " "))
    routes_tbl
;;

let print_middleware_f middlewares =
  print_endline "Active middleware:";
  middlewares
  |> ListLabels.map ~f:(fun m -> m.Rock.Middleware.name)
  |> ListLabels.iter ~f:(Printf.printf "> %s \n")
;;

let cmd_run
    app
    port
    ssl_cert
    ssl_key
    host
    print_routes
    print_middleware
    debug
    verbose
    _errors
  =
  let map2 ~f a b =
    match a, b with
    | Some x, Some y -> Some (f x y)
    | _ -> None
  in
  let ssl =
    let cmd_ssl =
      map2 ssl_cert ssl_key ~f:(fun c k -> `Crt_file_path c, `Key_file_path k)
    in
    match cmd_ssl, app.ssl with
    | Some s, _ | None, Some s -> Some s
    | None, None -> None
  in
  let app = { app with debug; verbose; host; port; ssl } in
  let rock_app = to_rock app in
  if print_routes
  then (
    let routes = app.routes in
    print_routes_f routes;
    exit 0);
  if print_middleware
  then (
    let middlewares = rock_app.middlewares in
    print_middleware_f middlewares;
    exit 0);
  app |> start
;;

module Cmds = struct
  open Cmdliner

  let routes =
    let doc = "print routes" in
    Arg.(value & flag & info [ "r"; "routes" ] ~doc)
  ;;

  let middleware =
    let doc = "print middleware stack" in
    Arg.(value & flag & info [ "m"; "middlware" ] ~doc)
  ;;

  let port default =
    let doc = "port" in
    Arg.(value & opt int default & info [ "p"; "port" ] ~doc)
  ;;

  let ssl_cert =
    let doc = "SSL certificate file" in
    Arg.(value & opt (some string) None & info [ "s"; "ssl-cert" ] ~doc)
  ;;

  let ssl_key =
    let doc = "SSL key file" in
    Arg.(value & opt (some string) None & info [ "k"; "ssl-key" ] ~doc)
  ;;

  let host default =
    let doc = "host" in
    Arg.(value & opt string default & info [ "h"; "host" ] ~doc)
  ;;

  let debug =
    let doc = "enable debug information" in
    Arg.(value & flag & info [ "d"; "debug" ] ~doc)
  ;;

  let verbose =
    let doc = "enable verbose mode" in
    Arg.(value & flag & info [ "v"; "verbose" ] ~doc)
  ;;

  let errors =
    let doc = "raise on errors. default is print" in
    Arg.(value & flag & info [ "f"; "fatal" ] ~doc)
  ;;

  let term =
    let open Cmdliner.Term in
    fun app ->
      pure cmd_run
      $ pure app
      $ port app.port
      $ ssl_cert
      $ ssl_key
      $ host app.host
      $ routes
      $ middleware
      $ debug
      $ verbose
      $ errors
  ;;

  let info name =
    let doc = Printf.sprintf "%s (Opium App)" name in
    let man = [] in
    Term.info name ~doc ~man
  ;;
end

let run_command' app =
  let open Cmdliner in
  let cmd = Cmds.term app in
  match Term.eval (cmd, Cmds.info app.name) with
  | `Ok a ->
    Lwt.async (fun () ->
        let* _server = a in
        Lwt.return_unit);
    let forever, _ = Lwt.wait () in
    `Ok forever
  | `Error _ -> `Error
  | _ -> `Not_running
;;

let run_command app =
  match app |> run_command' with
  | `Ok a ->
    Lwt.async (fun () ->
        let* _server = a in
        Lwt.return_unit);
    let forever, _ = Lwt.wait () in
    Lwt_main.run forever
  | `Error -> exit 1
  | `Not_running -> exit 0
;;
