(lang dune 1.11)

(using fmt 1.2)

(name opium)

(generate_opam_files true)

(source
 (github rgrinberg/opium))

(authors "Rudi Grinberg")

(maintainers "Rudi Grinberg <rudi.grinberg@gmail>")

(documentation https://rgrinberg.github.io/opium/)

(license MIT)

(package
 (name opium_kernel)
 (synopsis "Sinatra like web toolkit based on Lwt + Cohttp")
 (description
   "Opium_kernel is the Unix indpendent core of Opium. Useful for extremely portable environments such as mirage.")
 (depends
  (ocaml
   (>= 4.08))
  (dune
   (>= 1.11))
  hmap
  httpaf
  (lwt
   (>= 5.3.0))
  fieldslib
  sexplib0
  logs
  magic-mime
  mtime
  yojson
  tyxml
  bigstringaf
  re
  uri
  magic-mime
  multipart-form-data
  (alcotest :with-test)
  (alcotest-lwt :with-test)))

(package
 (name opium-testing)
 (synopsis "Testing library for Opium")
 (description
   "A library that provides helpers to easily test your Opium applications.")
 (depends
  (ocaml
   (>= 4.08))
  (dune
   (>= 1.11))
  opium_kernel
  alcotest
  alcotest-lwt))

(package
 (name opium)
 (synopsis "Sinatra like web toolkit based on Lwt + Cohttp")
 (description
   "Opium is a minimalistic library for quickly binding functions to http routes. Its features include (but not limited to):\n\n    Middleware system for app independent components\n    A simple router for matching urls and parsing parameters\n    Request/Response pretty printing for easier debugging\n  ")
 (depends
  (ocaml
   (>= 4.08))
  (dune
   (>= 1.11))
  (opium_kernel
   (= :version))
  httpaf-lwt-unix
  (lwt
   (>= 5.3.0))
  logs
  mtime
  cmdliner
  sexplib0
  re
  (alcotest :with-test)
  (alcotest-lwt :with-test)))