open Opium_kernel

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
       ; style
           [ txt
               {|/*! normalize.css v8.0.1 | MIT License | github.com/necolas/normalize.css */html{line-height:1.15;-webkit-text-size-adjust:100%}body{margin:0}main{display:block}h1{font-size:2em;margin:.67em 0}hr{box-sizing:content-box;height:0;overflow:visible}pre{font-family:monospace,monospace;font-size:1em}a{background-color:transparent}abbr[title]{border-bottom:none;text-decoration:underline;-webkit-text-decoration:underline dotted;text-decoration:underline dotted}b,strong{font-weight:bolder}code,kbd,samp{font-family:monospace,monospace;font-size:1em}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sub{bottom:-.25em}sup{top:-.5em}img{border-style:none}button,input,optgroup,select,textarea{font-family:inherit;font-size:100%;line-height:1.15;margin:0}button,input{overflow:visible}button,select{text-transform:none}[type=button],[type=submit],button{-webkit-appearance:button}[type=button]::-moz-focus-inner,[type=submit]::-moz-focus-inner,button::-moz-focus-inner{border-style:none;padding:0}[type=button]:-moz-focusring,[type=submit]:-moz-focusring,button:-moz-focusring{outline:1px dotted ButtonText}fieldset{padding:.35em .75em .625em}legend{box-sizing:border-box;color:inherit;display:table;max-width:100%;padding:0;white-space:normal}progress{vertical-align:baseline}textarea{overflow:auto}details{display:block}summary{display:list-item}[hidden],template{display:none}blockquote,dd,dl,figure,h1,h2,h3,h4,h5,h6,hr,p,pre{margin:0}button{background-color:transparent;background-image:none}button:focus{outline:1px dotted;outline:5px auto -webkit-focus-ring-color}fieldset,ol,ul{margin:0;padding:0}ol,ul{list-style:none}html{font-family:system-ui,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica Neue,Arial,Noto Sans,sans-serif,Apple Color Emoji,Segoe UI Emoji,Segoe UI Symbol,Noto Color Emoji;line-height:1.5}*,:after,:before{box-sizing:border-box;border:0 solid #d2d6dc}hr{border-top-width:1px}img{border-style:solid}textarea{resize:vertical}input::-moz-placeholder,textarea::-moz-placeholder{color:#a0aec0}input:-ms-input-placeholder,textarea:-ms-input-placeholder{color:#a0aec0}input::placeholder,textarea::placeholder{color:#a0aec0}button{cursor:pointer}table{border-collapse:collapse}h1,h2,h3,h4,h5,h6{font-size:inherit;font-weight:inherit}a{color:inherit;text-decoration:inherit}button,input,optgroup,select,textarea{padding:0;line-height:inherit;color:inherit}code,kbd,pre,samp{font-family:Menlo,Monaco,Consolas,Liberation Mono,Courier New,monospace}audio,canvas,embed,iframe,img,object,svg,video{display:block;vertical-align:middle}img,video{max-width:100%;height:auto}.bg-indigo-300{--bg-opacity:1;background-color:#b4c6fc;background-color:rgba(180,198,252,var(--bg-opacity))}.bg-indigo-600{--bg-opacity:1;background-color:#5850ec;background-color:rgba(88,80,236,var(--bg-opacity))}.hover\:bg-indigo-500:hover{--bg-opacity:1;background-color:#6875f5;background-color:rgba(104,117,245,var(--bg-opacity))}.active\:bg-indigo-700:active{--bg-opacity:1;background-color:#5145cd;background-color:rgba(81,69,205,var(--bg-opacity))}.border-transparent{border-color:transparent}.border-gray-300{--border-opacity:1;border-color:#d2d6dc;border-color:rgba(210,214,220,var(--border-opacity))}.focus\:border-indigo-700:focus{--border-opacity:1;border-color:#5145cd;border-color:rgba(81,69,205,var(--border-opacity))}.rounded-md{border-radius:.375rem}.border-dashed{border-style:dashed}.border-2{border-width:2px}.border{border-width:1px}.cursor-pointer{cursor:pointer}.inline-block{display:inline-block}.inline{display:inline}.inline-flex{display:inline-flex}.table{display:table}.hidden{display:none}.items-center{align-items:center}.justify-center{justify-content:center}.font-medium{font-weight:500}.h-6{height:1.5rem}.h-12{height:3rem}.text-sm{font-size:.875rem}.leading-4{line-height:1rem}.mx-auto{margin-left:auto;margin-right:auto}.mt-1{margin-top:.25rem}.mt-4{margin-top:1rem}.mt-16{margin-top:4rem}.max-w-lg{max-width:32rem}.focus\:outline-none:focus{outline:0}.py-2{padding-top:.5rem;padding-bottom:.5rem}.px-3{padding-left:.75rem;padding-right:.75rem}.px-6{padding-left:1.5rem;padding-right:1.5rem}.pt-5{padding-top:1.25rem}.pb-6{padding-bottom:1.5rem}.pointer-events-none{pointer-events:none}.shadow-sm{box-shadow:0 1px 2px 0 rgba(0,0,0,.05)}.focus\:shadow-outline-indigo:focus{box-shadow:0 0 0 3px rgba(180,198,252,.45)}.text-center{text-align:center}.text-white{--text-opacity:1;color:#fff;color:rgba(255,255,255,var(--text-opacity))}.text-gray-500{--text-opacity:1;color:#6b7280;color:rgba(107,114,128,var(--text-opacity))}.hover\:text-gray-400:hover{--text-opacity:1;color:#9fa6b2;color:rgba(159,166,178,var(--text-opacity))}.focus\:underline:focus{text-decoration:underline}.antialiased{-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale}.w-6{width:1.5rem}.w-12{width:3rem}.transition{transition-property:background-color,border-color,color,fill,stroke,opacity,box-shadow,transform}.ease-in-out{transition-timing-function:cubic-bezier(.4,0,.2,1)}.duration-150{transition-duration:.15s}@-webkit-keyframes spin{to{transform:rotate(1turn)}}@keyframes spin{to{transform:rotate(1turn)}}@-webkit-keyframes ping{75%,to{transform:scale(2);opacity:0}}@keyframes ping{75%,to{transform:scale(2);opacity:0}}@-webkit-keyframes pulse{50%{opacity:.5}}@keyframes pulse{50%{opacity:.5}}@-webkit-keyframes bounce{0%,to{transform:translateY(-25%);-webkit-animation-timing-function:cubic-bezier(.8,0,1,1);animation-timing-function:cubic-bezier(.8,0,1,1)}50%{transform:none;-webkit-animation-timing-function:cubic-bezier(0,0,.2,1);animation-timing-function:cubic-bezier(0,0,.2,1)}}@keyframes bounce{0%,to{transform:translateY(-25%);-webkit-animation-timing-function:cubic-bezier(.8,0,1,1);animation-timing-function:cubic-bezier(.8,0,1,1)}50%{transform:none;-webkit-animation-timing-function:cubic-bezier(0,0,.2,1);animation-timing-function:cubic-bezier(0,0,.2,1)}}|}
           ]
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
  let open Opium.Std in
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Debug);
  App.empty
  |> get "/" index_handler
  |> post "/upload" upload_handler
  |> middleware Middleware.logger
  |> App.run_command
;;
