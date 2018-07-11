
let test_mime_lookup () =
  let open Opium_kernel.Rock in
  let expected_content_type = "application/json; charset=utf-8" in
  let my_lookup (s:string) = expected_content_type in
  let mw = Opium.Middleware.static ~local_path:"" ~uri_prefix:"/"
             ~mime_lookup:my_lookup () in
  let response =
    Middleware.apply mw Handler.default
      @@ Request.create @@ Cohttp.Request.make @@ Uri.of_string "/static_serve.ml"
  in
  let response = Lwt_main.run response in
  Alcotest.(check int "response 200ok" 200
              (Cohttp.Code.code_of_status response.code));
  let real_content_type = Cohttp.Header.get response.headers "content-type" in
  Alcotest.(check (option string) "mime_lookup not work"
              (Some expected_content_type)
              real_content_type)


let () =
  Alcotest.run "static_serve"
    [ "main",
      [ "test mime_lookup", `Slow, test_mime_lookup ]
    ]
