(lang dune 2.0)

(name opium)

(generate_opam_files true)

(source
 (github rgrinberg/opium))

(authors "Rudi Grinberg" "Anurag Soni" "Thibaut Mattio")

(maintainers "Rudi Grinberg <me@rgrinberg.com>")

(documentation https://rgrinberg.github.io/opium/)

(license MIT)

(package
 (name rock)
 (synopsis
   "Minimalist framework to build extensible HTTP servers and clients")
 (description
   "Rock is a Unix indpendent API to build extensible HTTP servers and clients. It provides building blocks such as middlewares and handlers (a.k.a controllers).")
 (depends
  (ocaml
   (>= 4.08))
  (lwt
   (>= 5.3.0))
  bigstringaf
  hmap
  httpaf
  lwt
  sexplib0
  (odoc :with-doc)))

(package
 (name opium)
 (synopsis "OCaml web framework")
 (description
   "Opium is a web framework for OCaml that provides everything you need to build safe, fast and extensible web applications.")
 (depends
  (ocaml
   (>= 4.08))
  (rock
   (= :version))
  (lwt
   (>= 5.3.0))
  httpaf-lwt-unix
  logs
  fmt
  mtime
  cmdliner
  ptime
  magic-mime
  yojson
  tyxml
  mirage-crypto
  base64
  astring
  re
  uri
  multipart-form-data
  (odoc :with-doc)
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
  (opium
   (= :version))
  alcotest
  alcotest-lwt
  (odoc :with-doc)))
