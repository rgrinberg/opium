module Hmap0 = Hmap0
module Headers = Headers
module Body = Body
module Method = Method
module Status = Status
module Version = Version
module Rock = Rock
module Route = Route
module Server_connection = Server_connection
module Router = Router
module Static = Static
module Request = Request
module Response = Response

module Middleware = struct
  let router = Router.m
  let debugger = Debugger.m
  let logger = Logger.m
  let allow_cors = Allow_cors.m
  let static = Static.m
end
