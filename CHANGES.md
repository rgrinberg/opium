# 0.20.0

## Added

- New `Auth` module to work with `Authorization` header (#238)
- New `basic_auth` middleware to protect handlers with a `Basic` authentication method (#238)
- New `Response.of_file` API for conveniently creating a response of a file (#244)
- Add a package `opium-graphql` to easily create GraphQL server with Opium (#235)
- Add a function `App.run_multicore` that uses pre-forking and spawns multiple processes that will handle incoming requests (#239)

## Fixed

- Fix reading cookie values when multiple cookies are present in `Cookie` header (#246)

# 0.19.0

This release is a complete rewrite of the Opium's internal that switches from Cohttp to Httpaf.
As demonstrated in several benchmarks, Httpaf's latency is much lower than Cohttp's in stress tests, so it is expected that Opium will perform better in these high pressure situations with this change.

The underlying HTTP server implementation is now contained in the `rock` package, that provides a Service and Filter implementation, inspired by Finagle's. The architecture is similar to Ruby's Rack library (hence the name), so one can compose complex web applications by combining Rock applications.

The `rock` package offers a very slim API, with very few dependencies, so it should be an attractive option for other Web framework to build on, which would allow the re-usability of middlewares and handlers, independently of the framework used (e.g. one could use Sihl middlewares with Opium, and vice versa).

Apart from the architectural changes, this release comes with a lot of additionnal utilities and middlewares which should make Opium a better candidate for complex web applications, without having to re-write a lot of common Web server functionnalities.

The Request and Response modules now provide:

- JSON encoders/decoders with `Yojson`
- HTML encoders/decoders with `Tyxml`
- XML encoders/decoders with `Tyxml`
- SVG encoders/decoders with `Tyxml`
- multipart/form encoders/decoders with `multipart_form_data`
- urlencoded encoders/decoders with `Uri`

And the following middlewares are now built-in:

- `debugger` to display an HTML page with the errors in case of failures
- `logger` to log requests and responses, with a timer
- `allow_cors` to add CORS headers
- `static` to serve static content given a custom read function (e.g. read from S3)
- `static_unix` to to serve static content from the local filesystem
- `content_length` to add the `Content-Length` header to responses
- `method_override` to replace the HTTP method with the one found in the `_method` field of `application/x-www-form-urlencoded` encoded `POST` requests.
- `etag` to add `ETag` header to the responses and send an HTTP code `304` when the computed ETag matches the one specified in the request.
- `method_required` to filter the requests by method and respond with an HTTP code `405` if the method is not allowed.
- `head` to add supports for `HEAD` request for handlers that receive `GET` requests.

Lastly, this release also adds a package `opium-testing` that can be used to test Opium applications with `Alcotest`. It provides `Testable` modules for every Opium types, and implements helper functions to easily get an `Opium.Response` from an `Opium.Request`.

# 0.18.0

* Make examples easier to find and add documentation related to features used in them. (#125, @shonfeder)
* Allow overriding 404 handlers (#127, @anuragsoni)
* Support cohttp streaming response (#135, #137, #139, @anuragsoni)

# v0.17.1

* Change Deferred.t to Lwt.t in readme (#91, @rymdhund)
* Remove `cow` from deps (#92, @anuragsoni)

# v0.17.0

* Switch to dune (#88, @anuragsoni)
* Keep the "/" cookie default and expose all cookie directives (#82, @actionshrimp)
* Do not assume base 64 encoding of cookies (#74, @malthe)
* Add caching capabilities to middleware (#76, @mattjbray)
