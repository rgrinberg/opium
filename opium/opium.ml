module Opium_raw = struct
  module Response        = Rock.Response
  module Request         = Rock.Request
  module Rock            = Rock
  module Cookie          = Cookie
  module Router          = Router
  module Middleware_pack = Middleware_pack
  module App             = App
end
include Opium_raw

(** Open this module where you define your application's
    routes. Opening this module's namespace is NOT necessary to use
    this library. The main point is convenience in common
    operations *)
module Std = struct
  include Opium_raw
  (* selectively export the most useful parts of App *)
  let param    = App.param
  let splat    = App.splat
  let respond  = App.respond
  let respond' = App.respond'

  let get    = App.get
  let post   = App.post
  let put    = App.put
  let delete = App.delete

  let all = App.all
  let any = App.any

  let middleware = App.middleware
end
