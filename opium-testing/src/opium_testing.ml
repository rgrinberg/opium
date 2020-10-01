module Testable = struct
  let status = Alcotest.of_pp Rock.Status.pp
  let meth = Alcotest.of_pp Rock.Method.pp
  let version = Alcotest.of_pp Rock.Version.pp
  let body = Alcotest.of_pp Rock.Body.pp
  let request = Alcotest.of_pp Rock.Request.pp
  let response = Alcotest.of_pp Rock.Response.pp
  let cookie = Alcotest.of_pp Opium.Cookie.pp
end

let handle_request app =
  let open Rock in
  let open Lwt.Syntax in
  let service = Opium.App.to_handler app in
  let request_handler request =
    let+ ({ Response.body; headers; _ } as response) = service request in
    let length = Body.length body in
    let headers =
      match length with
      | None -> Headers.add_unless_exists headers "Transfer-Encoding" "chunked"
      | Some l -> Headers.add_unless_exists headers "Content-Length" (Int64.to_string l)
    in
    { response with headers }
  in
  request_handler
;;

let check_status ?msg expected t =
  let message =
    match msg with
    | Some msg -> msg
    | None -> Format.asprintf "HTTP status is %d" (Rock.Status.to_code expected)
  in
  Alcotest.check Testable.status message expected t
;;

let check_status' ?msg ~expected ~actual = check_status ?msg expected actual

let check_meth ?msg expected t =
  let message =
    match msg with
    | Some msg -> msg
    | None -> Format.asprintf "HTTP method is %s" (Rock.Method.to_string expected)
  in
  Alcotest.check Testable.meth message expected t
;;

let check_meth' ?msg ~expected ~actual = check_meth ?msg expected actual

let check_version ?msg expected t =
  let message =
    match msg with
    | Some msg -> msg
    | None -> Format.asprintf "HTTP version is %s" (Rock.Version.to_string expected)
  in
  Alcotest.check Testable.version message expected t
;;

let check_version' ?msg ~expected ~actual = check_version ?msg expected actual

let check_body ?msg expected t =
  let message =
    match msg with
    | Some msg -> msg
    | None -> "bodies are equal"
  in
  Alcotest.check Testable.body message expected t
;;

let check_body' ?msg ~expected ~actual = check_body ?msg expected actual

let check_request ?msg expected t =
  let message =
    match msg with
    | Some msg -> msg
    | None -> "requests are equal"
  in
  Alcotest.check Testable.request message expected t
;;

let check_request' ?msg ~expected ~actual = check_request ?msg expected actual

let check_response ?msg expected t =
  let message =
    match msg with
    | Some msg -> msg
    | None -> "responses are equal"
  in
  Alcotest.check Testable.response message expected t
;;

let check_response' ?msg ~expected ~actual = check_response ?msg expected actual

let string_contains s1 s2 =
  let re = Str.regexp_string s2 in
  try
    ignore (Str.search_forward re s1 0);
    true
  with
  | Not_found -> false
;;

let check_body_contains ?msg s body =
  let message =
    match msg with
    | Some msg -> msg
    | None -> "response body contains" ^ s
  in
  let open Lwt.Syntax in
  let+ body = body |> Rock.Body.copy |> Rock.Body.to_string in
  Alcotest.check Alcotest.bool message true (string_contains body s)
;;

let check_cookie ?msg expected t =
  let message =
    match msg with
    | Some msg -> msg
    | None -> "cookies are equal"
  in
  Alcotest.check Testable.cookie message expected t
;;

let check_cookie' ?msg ~expected ~actual = check_cookie ?msg expected actual
