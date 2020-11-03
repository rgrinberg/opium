open Opium

let layout ~title:title_ children =
  let open Tyxml.Html in
  html ~a:[ a_lang "en" ] (head (title (txt title_)) []) (body children)
;;

let index_view =
  let open Tyxml.Html in
  layout
    ~title:"Opium file upload"
    [ form
        ~a:[ a_action "/upload"; a_method `Post; a_enctype "multipart/form-data" ]
        [ input ~a:[ a_input_type `File; a_name "file" ] ()
        ; button ~a:[ a_button_type `Submit ] [ txt "Submit" ]
        ]
    ]
;;

let index_handler _request = Lwt.return @@ Response.of_html index_view

let upload_handler request =
  let open Lwt.Syntax in
  let files = Hashtbl.create ~random:true 5 in
  let callback ~name:_ ~filename string =
    let filename = Filename.basename filename in
    let write file =
      string |> String.length |> Lwt_unix.write_string file string 0 |> Lwt.map ignore
    in
    match Hashtbl.find_opt files filename with
    | Some file -> write file
    | None ->
      let* file =
        Lwt_unix.openfile filename Unix.[ O_CREAT; O_TRUNC; O_WRONLY; O_NONBLOCK ] 0o600
      in
      Hashtbl.add files filename file;
      write file
  in
  let* _ = Request.to_multipart_form_data_exn ~callback request in
  let close _ file prev =
    let* () = prev in
    Lwt_unix.close file
  in
  let* () = Hashtbl.fold close files Lwt.return_unit in
  Lwt.return @@ Response.of_plain_text "File uploaded successfully!"
;;

let _ =
  App.empty
  |> App.get "/" index_handler
  |> App.post "/upload" upload_handler
  |> App.run_command
;;
