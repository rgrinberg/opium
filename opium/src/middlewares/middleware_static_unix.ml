let m ~local_path ?uri_prefix ?headers ?etag_of_fname () =
  Middleware_static.m
    ~read:(Body.of_file ~local_path)
    ?uri_prefix
    ?headers
    ?etag_of_fname
    ()
;;
