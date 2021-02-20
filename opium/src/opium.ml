module Context = Context
module Headers = Headers
module Cookie = Cookie
module Method = Method
module Version = Version
module Status = Status
module Body = Body
module Request = Request
module Response = Response
module App = App
module Route = Route
module Auth = Auth
module Router = Middleware_router

module Session = struct
  exception Session_not_found = Middleware_cookie_session.Session_not_found

  let find = Middleware_cookie_session.find
  let set = Middleware_cookie_session.set
end

module Handler = struct
  let serve = Handler_serve.h
end

module Middleware = struct
  let router = Middleware_router.m
  let debugger = Middleware_debugger.m
  let logger = Middleware_logger.m
  let allow_cors = Middleware_allow_cors.m
  let static = Middleware_static.m
  let static_unix = Middleware_static_unix.m
  let content_length = Middleware_content_length.m
  let method_override = Middleware_method_override.m
  let etag = Middleware_etag.m
  let method_required = Middleware_method_required.m
  let head = Middleware_head.m
  let basic_auth = Middleware_basic_auth.m
  let cookie_session = Middleware_cookie_session.m
end
