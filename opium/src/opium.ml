module Context = Rock.Context
module Headers = Rock.Headers
module Cookie = Cookie
module Method = Rock.Method
module Version = Rock.Version
module Status = Rock.Status
module Body = Rock.Body
module Request = Request
module Response = Response
module App = App
module Route = Route
module Router = Middleware_router

module Handler = struct
  let serve = Middleware_static.serve
end

module Middleware = struct
  let router = Middleware_router.m
  let debugger = Middleware_debugger.m
  let logger = Middleware_logger.m
  let allow_cors = Middleware_allow_cors.m
  let static = Middleware_static.m
  let content_length = Middleware_content_length.m
  let method_override = Middleware_method_override.m
  let etag = Middleware_etag.m
  let method_required = Middleware_method_required.m
  let head = Middleware_head.m
end
