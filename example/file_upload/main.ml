open Opium

let layout ~title:title_ children =
  let open Tyxml.Html in
  html
    ~a:[ a_lang "en" ]
    (head
       (title (txt title_))
       [ meta ~a:[ a_charset "utf-8" ] ()
       ; meta ~a:[ a_name "viewport"; a_content "width=device-width, initial-scale=1" ] ()
       ; meta ~a:[ a_name "theme-color"; a_content "#ffffff" ] ()
       ; script
           ~a:
             [ a_src
                 "https://cdn.jsdelivr.net/gh/alpinejs/alpine@v2.7.0/dist/alpine.min.js"
             ; a_defer ()
             ]
           (txt "")
       ; link
           ~rel:[ `Stylesheet ]
           ~href:
             "https://cdn.jsdelivr.net/npm/@tailwindcss/ui@latest/dist/tailwind-ui.min.css"
           ()
       ])
    (body children)
;;

let index_view ?(success = false) () =
  let open Tyxml.Html in
  let a_custom x y = Xml.string_attrib x y |> to_attrib in
  let a_svg_custom x y = Tyxml.Xml.string_attrib x y |> Tyxml.Svg.to_attrib in
  layout
    ~title:"Opium file upload"
    [ (if success
      then
        div
          ~a:[ a_class [ "mx-auto mt-16 max-w-lg rounded-md bg-green-50 p-4" ] ]
          [ div
              ~a:[ a_class [ "flex" ] ]
              [ div
                  ~a:[ a_class [ "flex-shrink-0" ] ]
                  [ svg
                      ~a:
                        [ Tyxml.Svg.a_class [ "h-5 w-5 text-green-400" ]
                        ; Tyxml.Svg.a_viewBox (0., 0., 20., 20.)
                        ; Tyxml.Svg.a_fill `CurrentColor
                        ]
                      [ Tyxml.Svg.path
                          ~a:
                            [ a_svg_custom "fill-rule" "evenodd"
                            ; Tyxml.Svg.a_d
                                "M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 \
                                 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 \
                                 1.414l2 2a1 1 0 001.414 0l4-4z"
                            ; a_svg_custom "clip-rule" "evenodd"
                            ]
                          []
                      ]
                  ]
              ; div
                  ~a:[ a_class [ "ml-3" ] ]
                  [ p
                      ~a:[ a_class [ "text-sm leading-5 font-medium text-green-800" ] ]
                      [ txt "Successfully uploaded" ]
                  ]
              ; div
                  ~a:[ a_class [ "ml-auto pl-3" ] ]
                  [ div
                      ~a:[ a_class [ "-mx-1.5 -my-1.5" ] ]
                      [ button
                          ~a:
                            [ a_class
                                [ "inline-flex rounded-md p-1.5 text-green-500 \
                                   hover:bg-green-100 focus:outline-none \
                                   focus:bg-green-100 transition ease-in-out \
                                   duration-150"
                                ]
                            ; a_aria "label" [ "Dismiss" ]
                            ]
                          [ svg
                              ~a:
                                [ Tyxml.Svg.a_class [ "h-5 w-5" ]
                                ; Tyxml.Svg.a_viewBox (0., 0., 20., 20.)
                                ; Tyxml.Svg.a_fill `CurrentColor
                                ]
                              [ Tyxml.Svg.path
                                  ~a:
                                    [ a_svg_custom "fill-rule" "evenodd"
                                    ; Tyxml.Svg.a_d
                                        "M4.293 4.293a1 1 0 011.414 0L10 \
                                         8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 \
                                         10l4.293 4.293a1 1 0 01-1.414 1.414L10 \
                                         11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 \
                                         10 4.293 5.707a1 1 0 010-1.414z"
                                    ; a_svg_custom "clip-rule" "evenodd"
                                    ]
                                  []
                              ]
                          ]
                      ]
                  ]
              ]
          ]
      else div [])
    ; form
        ~a:[ a_enctype "multipart/form-data"; a_action "/upload"; a_method `Post ]
        [ div
            ~a:
              [ a_class
                  [ "mx-auto mt-16 max-w-lg justify-center px-6 pt-5 pb-6 border-2 \
                     border-gray-300 border-dashed rounded-md"
                  ]
              ]
            [ div
                ~a:[ a_class [ "text-center" ] ]
                [ label
                    ~a:
                      [ a_label_for "file-upload"
                      ; a_class
                          [ "inline-block cursor-pointer font-medium text-gray-500 \
                             hover:text-gray-400 focus:outline-none focus:underline \
                             transition duration-150 ease-in-out"
                          ]
                      ]
                    [ span
                        ~a:[ a_class [ "mt-1 text-sm" ] ]
                        [ svg
                            ~a:
                              [ Tyxml.Svg.a_class [ "mx-auto h-12 w-12" ]
                              ; Tyxml.Svg.a_stroke `CurrentColor
                              ; Tyxml.Svg.a_fill `None
                              ; Tyxml.Svg.a_viewBox (0., 0., 48., 48.)
                              ]
                            [ Tyxml.Svg.path
                                ~a:
                                  [ Tyxml.Svg.a_d
                                      "M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 \
                                       4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 \
                                       00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 \
                                       0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
                                  ; a_svg_custom "stroke-width" "2"
                                  ; a_svg_custom "stroke-linecap" "round"
                                  ; a_svg_custom "stroke-linejoin" "round"
                                  ]
                                []
                            ]
                        ; txt "Upload a file"
                        ]
                    ]
                ; div
                    ~a:[ a_custom "x-data" "{ fileName: '' }" ]
                    [ input
                        ~a:
                          [ a_input_type `File
                          ; a_name "file"
                          ; a_id "file-upload"
                          ; a_custom "x-ref" "file"
                          ; a_custom "@change" "fileName = $refs.file.files[0].name"
                          ; a_hidden ()
                          ]
                        ()
                    ; p
                        ~a:
                          [ a_class [ "hidden" ]
                          ; a_custom
                              ":class"
                              "{ 'mt-4' : fileName !== '' , 'hidden': fileName === ''  }"
                          ]
                        [ svg
                            ~a:
                              [ Tyxml.Svg.a_class [ "inline w-6 h-6 text-gray-500" ]
                              ; Tyxml.Svg.a_fill `None
                              ; Tyxml.Svg.a_stroke `CurrentColor
                              ; Tyxml.Svg.a_viewBox (0., 0., 24., 24.)
                              ]
                            [ Tyxml.Svg.path
                                ~a:
                                  [ a_svg_custom "stroke-linecap" "round"
                                  ; a_svg_custom "stroke-linejoin" "round"
                                  ; a_svg_custom "stroke-width" "2"
                                  ; Tyxml.Svg.a_d
                                      "M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 \
                                       2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 \
                                       0 01.293.707V19a2 2 0 01-2 2z"
                                  ]
                                []
                            ]
                        ; span ~a:[ a_custom "x-text" "fileName" ] []
                        ]
                    ; div
                        ~a:[ a_class [ "mt-4" ] ]
                        [ span
                            ~a:[ a_class [ "rounded-md shadow-sm" ] ]
                            [ button
                                ~a:
                                  [ a_button_type `Submit
                                  ; a_class
                                      [ "inline-flex items-center px-3 py-2 border \
                                         border-transparent text-sm leading-4 \
                                         font-medium rounded-md text-white transition \
                                         ease-in-out duration-150 bg-indigo-300 \
                                         pointer-events-none"
                                      ]
                                  ; a_custom
                                      ":class"
                                      "{'inline-flex items-center px-3 py-2 border \
                                       border-transparent text-sm leading-4 font-medium \
                                       rounded-md text-white transition ease-in-out \
                                       duration-150' : true, 'bg-indigo-300 \
                                       pointer-events-none': fileName === '','': \
                                       fileName === '','bg-indigo-600 \
                                       hover:bg-indigo-500 focus:outline-none \
                                       focus:border-indigo-700 \
                                       focus:shadow-outline-indigo \
                                       active:bg-indigo-700': fileName !== '' }"
                                  ]
                                [ txt "Upload" ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]
;;

let index_handler _request = Lwt.return @@ Response.of_html (index_view ())

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
  Lwt.return @@ Response.of_html (index_view ~success:true ())
;;

let _ =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Debug);
  App.empty
  |> App.get "/" index_handler
  |> App.post "/upload" upload_handler
  |> App.run_command
;;
