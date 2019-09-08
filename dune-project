(lang dune 1.11)
(name opium)
(using fmt 1.2)
(generate_opam_files true)

(source (github rgrinberg/opium))
(documentation "https://rgrinberg.github.io/opium")
(authors "Rudi Grinberg")
(maintainers "Rudi Grinberg <rudi.grinberg@gmail>")
(license MIT)

(package
 (name opium_core)
 (synopsis "Finagle inspired service & filters")
 (depends
  (ocaml
   (>= 4.04.2))
  (dune
   (>= 1.11))
  ppx_sexp_conv
  lwt
  (alcotest :with-test)
  (alcotest-lwt :with-test)))

(package
 (name opium_kernel)
 (synopsis "Sinatra like web toolkit based on Lwt + Cohttp")
 (description "Opium_kernel is the Unix indpendent core of Opium. Useful for extremely portable environments such as mirage.")
 (depends
  (ocaml (>= 4.04.2))
  (dune (>= 1.11))
  (base (>= "v0.11.0"))
  opium_core
  hmap
  cohttp
  cohttp-lwt
  ezjsonm
  lwt
  fieldslib
  sexplib
  ppx_fields_conv
  ppx_sexp_conv
  re
  (alcotest :with-test))
 )

(package
 (name opium)
 (synopsis "Sinatra like web toolkit based on Lwt + Cohttp")
 (description
 "Opium is a minimalistic library for quickly binding functions to http routes. Its features include (but not limited to):

    Middleware system for app independent components
    A simple router for matching urls and parsing parameters
    Request/Response pretty printing for easier debugging
  ")
 (depends
  (ocaml (>= 4.04.2))
  (dune (>= 1.11))
  (base (>= "v0.11.0"))
  (stdio (>= "v0.11.0"))
  opium_core
  opium_kernel
  cohttp-lwt-unix
  lwt
  logs
  cmdliner
  ppx_fields_conv
  ppx_sexp_conv
  re
  magic-mime
  stringext
  (alcotest :with-test))
 )
