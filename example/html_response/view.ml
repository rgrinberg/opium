let layout ~title:title_ body_ =
  let open Tyxml.Html in
  html
    ~a:[ a_lang "en" ]
    (head
       (title (txt title_))
       [ meta ~a:[ a_charset "utf-8" ] ()
       ; meta ~a:[ a_name "viewport"; a_content "width=device-width, initial-scale=1" ] ()
       ; meta ~a:[ a_name "theme-color"; a_content "#ffffff" ] ()
       ; link
           ~rel:[ `Stylesheet ]
           ~href:"https://unpkg.com/tailwindcss@^1.8/dist/tailwind.min.css"
           ()
       ])
    (body body_)
;;

let check_icon =
  let open Tyxml.Html in
  let a_svg_custom x y = Tyxml.Xml.string_attrib x y |> Tyxml.Svg.to_attrib in
  svg
    ~a:
      [ Tyxml.Svg.a_class [ "flex-shrink-0 h-5 w-5 text-teal-500" ]
      ; Tyxml.Svg.a_viewBox (0., 0., 20., 20.)
      ; Tyxml.Svg.a_fill `CurrentColor
      ]
    [ Tyxml.Svg.path
        ~a:
          [ a_svg_custom "fill-rule" "evenodd"
          ; Tyxml.Svg.a_d
              "M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 \
               10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
          ; a_svg_custom "clip-rule" "evenodd"
          ]
        []
    ]
;;

let index =
  let open Tyxml.Html in
  layout
    ~title:"Opium Example"
    [ div
        ~a:
          [ a_class
              [ "min-h-screen bg-gray-100 py-6 flex flex-col justify-center sm:py-12" ]
          ]
        [ div
            ~a:[ a_class [ "relative py-3 sm:max-w-xl sm:mx-auto" ] ]
            [ div
                ~a:
                  [ a_class
                      [ "relative px-4 py-10 bg-white shadow-lg sm:rounded-lg sm:p-20" ]
                  ]
                [ div
                    ~a:[ a_class [ "max-w-md mx-auto" ] ]
                    [ div
                        [ p
                            ~a:
                              [ a_class
                                  [ "mt-1 text-3xl leading-10 font-extrabold \
                                     text-gray-900 sm:text-4xl sm:leading-none \
                                     sm:tracking-tight lg:text-5xl"
                                  ]
                              ]
                            [ txt "Opium" ]
                        ]
                    ; div
                        ~a:[ a_class [ "divide-y divide-gray-200" ] ]
                        [ div
                            ~a:
                              [ a_class
                                  [ "py-8 text-base leading-6 space-y-4 text-gray-700 \
                                     sm:text-lg sm:leading-7"
                                  ]
                              ]
                            [ p [ txt "Web Framework for OCaml" ]
                            ; ul
                                ~a:[ a_class [ "list-disc space-y-2" ] ]
                                [ li
                                    ~a:[ a_class [ "flex items-start" ] ]
                                    [ span
                                        ~a:[ a_class [ "h-6 flex items-center sm:h-7" ] ]
                                        [ check_icon ]
                                    ; p
                                        ~a:[ a_class [ "ml-2" ] ]
                                        [ txt "Safe as in static typing" ]
                                    ]
                                ; li
                                    ~a:[ a_class [ "flex items-start" ] ]
                                    [ span
                                        ~a:[ a_class [ "h-6 flex items-center sm:h-7" ] ]
                                        [ check_icon ]
                                    ; p
                                        ~a:[ a_class [ "ml-2" ] ]
                                        [ txt "Fast... "
                                        ; span
                                            ~a:[ a_class [ "font-bold text-gray-900" ] ]
                                            [ txt "really" ]
                                        ; txt " fast!"
                                        ]
                                    ]
                                ; li
                                    ~a:[ a_class [ "flex items-start" ] ]
                                    [ span
                                        ~a:[ a_class [ "h-6 flex items-center sm:h-7" ] ]
                                        [ check_icon ]
                                    ; p
                                        ~a:[ a_class [ "ml-2" ] ]
                                        [ txt "Dozens of middlewares ready to use" ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]
;;
