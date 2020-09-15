module Hmap = Hmap0
module Headers = Headers
module Body = Body
module Method = Method
module Status = Status
module Version = Version
module Rock = Rock
module Route = Route
module Server_connection = Server_connection
module Request = Request
module Response = Response
module Cookie = Cookie
module Router = Middleware_router
module Static = Middleware_static

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
