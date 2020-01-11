## Things missing when compared to version based on Cohttp

* ~~Request body isn't handled yet (most important task for now)~~
* No sexp derivers (Httpaf doesn't have sexp derivers for their types, consider using their pretty printers instead?)
* ~~No static file serving.~~
* No cookie module (will need something similar to Cohttp's cookie module)
* No SSL (https://github.com/inhabitedtype/httpaf/pull/83 should help)

Update this file as more gaps are found
