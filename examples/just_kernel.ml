open Rock
open Lwt.Syntax

let make_router routes =
  routes
  |> ListLabels.fold_left ~init:Router.empty ~f:(fun router (meth, route, action) ->
         Router.add router ~route:(Route.of_string route) ~meth ~action)
  |> Middleware.router
;;

let router =
  make_router
    [ (`GET, "/", fun _req -> Lwt.return (Response.of_plain_text "Hello world\n"))
    ; ( `GET
      , "/sum/:a/:b"
      , fun req ->
          let a = Router.param req "a" |> int_of_string in
          let b = Router.param req "b" |> int_of_string in
          Lwt.return
            (Response.of_plain_text
               (Printf.sprintf "Sum of %d and %d = %d\n" a b (a + b))) )
    ]
;;

let app =
  Rock.App.create
    ~middlewares:[ router ]
    ~handler:(fun _ ->
      Lwt.return (Response.of_plain_text ~status:`Not_found "No route found\n"))
    ()
;;

let run () =
  let listen_address = Unix.(ADDR_INET (inet_addr_loopback, 8080)) in
  let connection_handler addr fd =
    let f ~request_handler ~error_handler =
      Httpaf_lwt_unix.Server.create_connection_handler
        ~request_handler:(fun _ -> request_handler)
        ~error_handler:(fun _ -> error_handler)
        addr
        fd
    in
    Rock.Server_connection.run f app
  in
  Lwt.async (fun () ->
      let* _ =
        Lwt_io.establish_server_with_client_socket listen_address connection_handler
      in
      Lwt.return_unit);
  let forever, _ = Lwt.wait () in
  Lwt_main.run forever
;;

let () = run ()
