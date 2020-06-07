module Hmap0 = Hmap0
module Headers = Headers
module Method = Method
module Status = Status
module Version = Version
module Rock = Rock
module Route = Route
module Server_connection = Server_connection
module Router = Router

module Middleware = struct
  let router = Router.m
  let debugger = Debugger.m
  let logger = Logger.m
end
