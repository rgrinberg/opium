open Opium_kernel
open Rock
open Lwt.Infix

let make_router routes =
  let router = Router.create () in
  ListLabels.iter routes ~f:(fun (meth, route, action) ->
      Router.add router ~route:(Route.of_string route) ~meth ~action);
  Router.m router
;;

let router =
  make_router
    [ (`GET, "/", fun _req -> Lwt.return (Response.of_string "Hello world\n"))
    ; ( `GET
      , "/sum/:a/:b"
      , fun req ->
          let a = Router.param req "a" |> int_of_string in
          let b = Router.param req "b" |> int_of_string in
          Lwt.return
            (Response.of_string (Printf.sprintf "Sum of %d and %d = %d\n" a b (a + b))) )
    ]
;;

let app =
  Opium_kernel.Rock.App.create
    ~middlewares:[ router ]
    ~handler:(fun _ ->
      Lwt.return (Response.of_string ~status:`Not_found "No route found\n"))
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
    Opium_kernel.Server_connection.run f app
  in
  Lwt.async (fun () ->
      Lwt_io.establish_server_with_client_socket listen_address connection_handler
      >>= fun _ -> Lwt.return_unit);
  let forever, _ = Lwt.wait () in
  Lwt_main.run forever
;;

let () = run ()
