module Response        = Rock.Response
module Request         = Rock.Request
module Rock            = Rock
module Cookie          = Cookie
module Router          = Router
module Middleware_pack = Middleware_pack
module App             = App

(** Open this module where you define your application's
    routes. Opening this module's namespace is NOT necessary to use
    this library. The main point is convenience in common
    operations *)
module Std = struct
  module Response        = Rock.Response
  module Request         = Rock.Request
  module Rock            = Rock
  module Cookie          = Cookie
  module Router          = Router
  module Middleware_pack = Middleware_pack
  module App             = App
  (* selectively export the most useful parts of App *)
  let param    = App.param
  let respond  = App.respond
  let respond' = App.respond'

  let get    = App.get
  let post   = App.post
  let put    = App.put
  let delete = App.delete
end
