open Httpaf
open Httpaf_lwt_unix

let text =
  "CHAPTER I. Down the Rabbit-Hole  Alice was beginning to get very tired of sitting by \
   her sister on the bank, and of having nothing to do: once or twice she had peeped \
   into the book her sister was reading, but it had no pictures or conversations in it, \
   <and what is the use of a book,> thought Alice <without pictures or conversations?> \
   So she was considering in her own mind (as well as she could, for the hot day made \
   her feel very sleepy and stupid), whether the pleasure of making a daisy-chain would \
   be worth the trouble of getting up and picking the daisies, when suddenly a White \
   Rabbit with pink eyes ran close by her. There was nothing so very remarkable in that; \
   nor did Alice think it so very much out of the way to hear the Rabbit say to itself, \
   <Oh dear! Oh dear! I shall be late!> (when she thought it over afterwards, it \
   occurred to her that she ought to have wondered at this, but at the time it all \
   seemed quite natural); but when the Rabbit actually took a watch out of its \
   waistcoat-pocket, and looked at it, and then hurried on, Alice started to her feet, \
   for it flashed across her mind that she had never before seen a rabbit with either a \
   waistcoat-pocket, or a watch to take out of it, and burning with curiosity, she ran \
   across the field after it, and fortunately was just in time to see it pop down a \
   large rabbit-hole under the hedge. In another moment down went Alice after it, never \
   once considering how in the world she was to get out again. The rabbit-hole went \
   straight on like a tunnel for some way, and then dipped suddenly down, so suddenly \
   that Alice had not a moment to think about stopping herself before she found herself \
   falling down a very deep well. Either the well was very deep, or she fell very \
   slowly, for she had plenty of time as she went down to look about her and to wonder \
   what was going to happen next. First, she tried to look down and make out what she \
   was coming to, but it was too dark to see anything; then she looked at the sides of \
   the well, and noticed that they were filled with cupboards......"
;;

let benchmark =
  let headers =
    Headers.of_list [ "content-length", Int.to_string (String.length text) ]
  in
  let handler reqd =
    let { Request.target; _ } = Reqd.request reqd in
    let request_body = Reqd.request_body reqd in
    Body.close_reader request_body;
    match target with
    | "/" -> Reqd.respond_with_string reqd (Response.create ~headers `OK) text
    | _ -> Reqd.respond_with_string reqd (Response.create `Not_found) "Route not found"
  in
  handler
;;

let error_handler ?request:_ error start_response =
  let response_body = start_response Headers.empty in
  (match error with
  | `Exn exn ->
    Body.write_string response_body (Printexc.to_string exn);
    Body.write_string response_body "\n"
  | #Status.standard as error ->
    Body.write_string response_body (Status.default_reason_phrase error));
  Body.close_writer response_body
;;

let () =
  let open Lwt.Infix in
  let listen_address = Unix.(ADDR_INET (inet_addr_loopback, 3000)) in
  let request_handler _ = benchmark in
  let error_handler _ = error_handler in
  Lwt.async (fun () ->
      Lwt_io.establish_server_with_client_socket
        ~backlog:11_000
        listen_address
        (Server.create_connection_handler ~request_handler ~error_handler)
      >>= fun _server -> Lwt.return_unit);
  let forever, _ = Lwt.wait () in
  Lwt_main.run forever
;;
