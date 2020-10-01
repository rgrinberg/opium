module Testable = struct
  let status = Alcotest.of_pp Opium.Status.pp
  let meth = Alcotest.of_pp Opium.Method.pp
  let version = Alcotest.of_pp Opium.Version.pp
  let body = Alcotest.of_pp Opium.Body.pp
  let request = Alcotest.of_pp Opium.Request.pp
  let response = Alcotest.of_pp Opium.Response.pp
  let cookie = Alcotest.of_pp Opium.Cookie.pp
end

let handle_request app =
  let open Lwt.Syntax in
  let service = Opium.App.to_handler app in
  let request_handler request =
    let+ ({ Opium.Response.body; headers; _ } as response) = service request in
    let length = Opium.Body.length body in
    let headers =
      match length with
      | None -> Opium.Headers.add_unless_exists headers "Transfer-Encoding" "chunked"
      | Some l ->
        Opium.Headers.add_unless_exists headers "Content-Length" (Int64.to_string l)
    in
    { response with headers }
  in
  request_handler
;;

let check_status ?msg expected t =
  let message =
    match msg with
    | Some msg -> msg
    | None -> Format.asprintf "HTTP status is %d" (Opium.Status.to_code expected)
  in
  Alcotest.check Testable.status message expected t
;;

let check_status' ?msg ~expected ~actual = check_status ?msg expected actual

let check_meth ?msg expected t =
  let message =
    match msg with
    | Some msg -> msg
    | None -> Format.asprintf "HTTP method is %s" (Opium.Method.to_string expected)
  in
  Alcotest.check Testable.meth message expected t
;;

let check_meth' ?msg ~expected ~actual = check_meth ?msg expected actual

let check_version ?msg expected t =
  let message =
    match msg with
    | Some msg -> msg
    | None -> Format.asprintf "HTTP version is %s" (Opium.Version.to_string expected)
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
  let+ body = body |> Opium.Body.copy |> Opium.Body.to_string in
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
