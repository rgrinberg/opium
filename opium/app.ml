open Opium_kernel__Misc
module Rock = Opium_kernel.Rock
module Router = Opium_kernel.Router
module Route = Opium_kernel.Route
module Server = Httpaf_lwt_unix.Server
module Reqd = Httpaf.Reqd
open Rock

let run_unix ?ssl t ~port =
  let middlewares = t |> App.middlewares |> List.map ~f:Middleware.filter in
  let handler = App.handler t in
  let _mode =
    Option.value_map ssl
      ~default:(`TCP (`Port port))
      ~f:(fun (c, k) -> `TLS (c, k, `No_password, `Port port))
  in
  let listen_address = Unix.(ADDR_INET (inet_addr_loopback, port)) in
  let connection_handler =
    let read_body m request_body =
      let body_read, finished = Lwt.wait () in
      ( match m with
      | `POST | `PUT ->
          let b =
            Buffer.create Httpaf.Config.default.request_body_buffer_size
          in
          let rec on_read bs ~off ~len =
            let b' = Bytes.create len in
            Bigstringaf.blit_to_bytes bs ~src_off:off b' ~dst_off:0 ~len ;
            Buffer.add_bytes b b' ;
            Httpaf.Body.schedule_read request_body ~on_read ~on_eof
          and on_eof () =
            Lwt.wakeup_later finished (Body.of_string (Buffer.contents b))
          in
          Httpaf.Body.schedule_read request_body ~on_read ~on_eof
      | _ -> Lwt.wakeup_later finished Rock.Body.empty ) ;
      body_read
    in
    let request_handler _ reqd =
      Lwt.async (fun () ->
          let request = Reqd.request reqd in
          read_body request.meth (Httpaf.Reqd.request_body reqd)
          >>= fun body ->
          let req = Request.create ~body request in
          let handler = Filter.apply_all middlewares handler in
          handler req
          >>| fun {Response.code; headers; body; _} ->
          let headers =
            Httpaf.Headers.add_unless_exists headers "Content-Length"
              (string_of_int (Body.length body))
          in
          let response = Httpaf.Response.create ~headers code in
          match body with
          | `Empty -> Reqd.respond_with_string reqd response ""
          | `String s -> Reqd.respond_with_string reqd response s
          | `Bigstring b -> Reqd.respond_with_bigstring reqd response b)
    in
    let error_handler _ ?request:_ error start_response =
      let response_body = start_response Httpaf.Headers.empty in
      ( match error with
      | `Exn exn ->
          Httpaf.Body.write_string response_body (Printexc.to_string exn) ;
          Httpaf.Body.write_string response_body "\n"
      | #Httpaf.Status.standard as error ->
          Httpaf.Body.write_string response_body
            (Httpaf.Status.default_reason_phrase error) ) ;
      Httpaf.Body.close_writer response_body
    in
    Server.create_connection_handler ~request_handler ~error_handler
  in
  Lwt_io.establish_server_with_client_socket ~backlog:128 listen_address
    connection_handler

type t =
  { port: int
  ; ssl: ([`Crt_file_path of string] * [`Key_file_path of string]) option
  ; debug: bool
  ; verbose: bool
  ; routes: (Httpaf.Method.t * Route.t * Handler.t) list
  ; middlewares: Middleware.t list
  ; name: string
  ; not_found: Handler.t }
[@@deriving fields]

type builder = t -> t

type route = string -> Handler.t -> builder

let register app ~meth ~route ~action =
  {app with routes= (meth, route, action) :: app.routes}

let empty =
  { name= "Opium Default Name"
  ; port= 3000
  ; ssl= None
  ; debug= false
  ; verbose= false
  ; routes= []
  ; middlewares= []
  ; not_found= Handler.not_found }

let create_router routes =
  let router = Router.create () in
  routes
  |> List.iter ~f:(fun (meth, route, action) ->
         Router.add router ~meth ~route ~action) ;
  router

let attach_middleware {verbose; debug; routes; middlewares; _} =
  [Some (routes |> create_router |> Router.m)]
  @ List.map ~f:Option.some middlewares
  @ [ (if verbose then Some Debug.trace else None)
    ; (if debug then Some Debug.debug else None) ]
  |> List.filter_opt

let port port t = {t with port}

let ssl ~cert ~key t =
  {t with ssl= Some (`Crt_file_path cert, `Key_file_path key)}

let cmd_name name t = {t with name}

let middleware m app = {app with middlewares= m :: app.middlewares}

let action meth route action =
  register ~meth ~route:(Route.of_string route) ~action

let not_found action t =
  let action req =
    action req >>| fun resp -> {resp with Response.code= `Not_found}
  in
  {t with not_found= action}

let get route action =
  register ~meth:`GET ~route:(Route.of_string route) ~action

let post route action =
  register ~meth:`POST ~route:(Route.of_string route) ~action

let delete route action =
  register ~meth:`DELETE ~route:(Route.of_string route) ~action

let put route action =
  register ~meth:`PUT ~route:(Route.of_string route) ~action

(* let patch route action = *)
(* register ~meth:`PATCH ~route:(Route.of_string route) ~action *)
let head route action =
  register ~meth:`HEAD ~route:(Route.of_string route) ~action

let options route action =
  register ~meth:`OPTIONS ~route:(Route.of_string route) ~action

let any methods route action t =
  if List.is_empty methods then
    Logs.warn (fun f ->
        f
          "Warning: you're using [any] attempting to bind to '%s' but your list\n\
          \        of http methods is empty route" route) ;
  let route = Route.of_string route in
  methods
  |> List.fold_left ~init:t ~f:(fun app meth ->
         app |> register ~meth ~route ~action)

let all = any [`GET; `POST; `DELETE; `PUT; `HEAD; `OPTIONS]

let to_rock app =
  Rock.App.create ~middlewares:(attach_middleware app) ~handler:app.not_found

let start app =
  let middlewares = attach_middleware app in
  (* if app.verbose then *)
  (* Logs.info.(add_rule "*" Info); *)
  Logs.info (fun f ->
      f "Running on port: %d%s" app.port (if app.debug then " (debug)" else "")) ;
  let port = app.port in
  let ssl = app.ssl in
  let app = Rock.App.create ~middlewares ~handler:app.not_found in
  run_unix ~port ?ssl app

let print_routes_f routes =
  let routes_tbl = Hashtbl.create 64 in
  routes
  |> List.iter ~f:(fun (meth, route, _) ->
         hashtbl_add_multi routes_tbl route meth) ;
  Printf.printf "%d Routes:\n" (Hashtbl.length routes_tbl) ;
  Hashtbl.iter
    (fun key data ->
      Printf.printf "> %s (%s)\n" (Route.to_string key)
        (data |> List.map ~f:Httpaf.Method.to_string |> String.concat " "))
    routes_tbl

let print_middleware_f middlewares =
  print_endline "Active middleware:" ;
  middlewares
  |> List.map ~f:Rock.Middleware.name
  |> List.iter ~f:(Printf.printf "> %s \n")

let cmd_run app port ssl_cert ssl_key _host print_routes print_middleware debug
    verbose _errors =
  let ssl =
    let cmd_ssl =
      Option.map2 ssl_cert ssl_key ~f:(fun c k ->
          (`Crt_file_path c, `Key_file_path k))
    in
    match (cmd_ssl, app.ssl) with
    | Some s, _ | None, Some s -> Some s
    | None, None -> None
  in
  let app = {app with debug; verbose; port; ssl} in
  let rock_app = to_rock app in
  if print_routes then (
    app |> routes |> print_routes_f ;
    exit 0 ) ;
  if print_middleware then (
    rock_app |> Rock.App.middlewares |> print_middleware_f ;
    exit 0 ) ;
  app |> start

module Cmds = struct
  open Cmdliner

  let routes =
    let doc = "print routes" in
    Arg.(value & flag & info ["r"; "routes"] ~doc)

  let middleware =
    let doc = "print middleware stack" in
    Arg.(value & flag & info ["m"; "middlware"] ~doc)

  let port default =
    let doc = "port" in
    Arg.(value & opt int default & info ["p"; "port"] ~doc)

  let ssl_cert =
    let doc = "SSL certificate file" in
    Arg.(value & opt (some string) None & info ["s"; "ssl-cert"] ~doc)

  let ssl_key =
    let doc = "SSL key file" in
    Arg.(value & opt (some string) None & info ["k"; "ssl-key"] ~doc)

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

  let term =
    let open Cmdliner.Term in
    fun app ->
      pure cmd_run $ pure app $ port app.port $ ssl_cert $ ssl_key $ interface
      $ routes $ middleware $ debug $ verbose $ errors

  let info name =
    let doc = Printf.sprintf "%s (Opium App)" name in
    let man = [] in
    Term.info name ~doc ~man
end

let run_command' app =
  let open Cmdliner in
  let cmd = Cmds.term app in
  match Term.eval (cmd, Cmds.info app.name) with
  | `Ok a -> `Ok a
  | `Error _ -> `Error
  | _ -> `Not_running

let run_command app =
  match app |> run_command' with
  | `Ok a ->
      Lwt.async (fun () -> a >>= fun _server -> Lwt.return_unit) ;
      let forever, _ = Lwt.wait () in
      Lwt_main.run forever
  | `Error -> exit 1
  | `Not_running -> exit 0

type body =
  [ `Html of string
  | `Json of Ezjsonm.t
  | `Xml of string
  | `String of string
  | `Bigstring of Bigstringaf.t ]

module Response_helpers = struct
  let add_opt headers k v =
    match headers with
    | Some h -> Httpaf.Headers.add h k v
    | None -> Httpaf.Headers.of_list [(k, v)]

  let content_type ct h = add_opt h "Content-Type" ct

  let json_header = content_type "application/json"

  let xml_header = content_type "application/xml"

  let html_header = content_type "text/html"

  let respond_with_string = Response.of_string_body

  let respond_with_bigstring = Response.of_bigstring_body

  let respond ?headers ?(code = `OK) = function
    | `String s -> respond_with_string ?headers ~code s
    | `Bigstring s -> respond_with_bigstring ?headers ~code s
    | `Json s ->
        respond_with_string ~code ~headers:(json_header headers)
          (Ezjsonm.to_string s)
    | `Html s -> respond_with_string ~code ~headers:(html_header headers) s
    | `Xml s -> respond_with_string ~code ~headers:(xml_header headers) s

  let respond' ?headers ?code s = s |> respond ?headers ?code |> return

  let redirect ?headers uri =
    let headers = add_opt headers "Location" (Uri.to_string uri) in
    Response.create ~headers ~code:`Found ()

  let redirect' ?headers uri = uri |> redirect ?headers |> return
end

module Request_helpers = struct
  let json_exn req =
    req |> Request.body |> Body.to_string_promise >>| Ezjsonm.from_string

  let string_exn req = req |> Request.body |> Body.to_string_promise

  let pairs_exn req =
    req |> Request.body |> Body.to_string_promise >>| Uri.query_of_encoded
end

let json_of_body_exn = Request_helpers.json_exn

let string_of_body_exn = Request_helpers.string_exn

let urlencoded_pairs_of_body = Request_helpers.pairs_exn

let param = Router.param

let splat = Router.splat

let respond = Response_helpers.respond

let respond' = Response_helpers.respond'

let redirect = Response_helpers.redirect

let redirect' = Response_helpers.redirect'
