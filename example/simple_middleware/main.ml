open Opium

module Reject_user_agent = struct
  let is_ua_msie =
    let re = Re.compile (Re.str "MSIE") in
    Re.execp re
  ;;

  let m =
    let filter handler req =
      match Request.header "user-agent" req with
      | Some ua when is_ua_msie ua ->
        Response.of_plain_text ~status:`Bad_request "Please upgrade your browser"
        |> Lwt.return
      | _ -> handler req
    in
    Rock.Middleware.create ~filter ~name:"Reject User-Agent"
  ;;
end

let index_handler _request = Response.of_plain_text "Hello World!" |> Lwt.return

let _ =
  App.empty
  |> App.get "/" index_handler
  |> App.middleware Reject_user_agent.m
  |> App.cmd_name "Reject UA"
  |> App.run_command
;;
