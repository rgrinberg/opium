open Rock
open Lwt.Syntax

let index_handler _req =
  let headers = Httpaf.Headers.of_list [ "Content-Type", "text/plain" ] in
  let body = Body.of_string "Hello World!\n" in
  Lwt.return @@ Response.make ~headers ~body ()
;;

let sum_handler ~a ~b _req =
  let headers = Httpaf.Headers.of_list [ "Content-Type", "text/plain" ] in
  let body = Body.of_string (Printf.sprintf "Sum of %d and %d = %d\n" a b (a + b)) in
  Lwt.return @@ Response.make ~headers ~body ()
;;

module Router = struct
  let m =
    let filter handler req =
      let parts =
        req.Request.target
        |> String.split_on_char '/'
        |> List.filter (fun x -> not (String.equal x ""))
      in
      match parts with
      | [] -> index_handler req
      | [ "sum"; a; b ] -> sum_handler ~a:(int_of_string a) ~b:(int_of_string b) req
      | _ -> handler req
    in
    Middleware.create ~filter ~name:""
  ;;
end

let app =
  Rock.App.create
    ~middlewares:[ Router.m ]
    ~handler:(fun _ ->
      let body = Body.of_string "No route found\n" in
      Lwt.return (Response.make ~status:`Not_found ~body ()))
    ()
;;

let sockaddr_to_string = function
  | Unix.ADDR_UNIX x -> x
  | ADDR_INET (inet_addr, port) ->
    Printf.sprintf "%s:%d" (Unix.string_of_inet_addr inet_addr) port
;;

let run () =
  let listen_address = Unix.(ADDR_INET (inet_addr_loopback, 8080)) in
  let connection_handler addr fd =
    Httpaf_lwt_unix.Server.create_connection_handler
      ~request_handler:(fun addr ->
        Rock.Server_connection.to_httpaf_request_handler (sockaddr_to_string addr) app)
      ~error_handler:(fun addr ->
        Rock.Server_connection.(
          to_httpaf_error_handler Server_connection.default_error_handler)
          (sockaddr_to_string addr))
      addr
      fd
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
