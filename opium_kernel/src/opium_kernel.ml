module Hmap0 = Core.Hmap0
module Body = Core.Body
module Rock = Core.Rock
module Route = Core.Route
module Server_connection = Server_connection
module Router = Middlewares.Router

module Middleware = struct
  let router = Middlewares.Router.m
  let debugger = Middlewares.Debugger.m
  let logger = Middlewares.Logger.m
  let html_error_handler = Middlewares.Error_handler.Html.m
  let json_error_handler = Middlewares.Error_handler.Json.m
end
