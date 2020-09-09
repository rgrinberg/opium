module App = App

module App_export = struct
  module App = App

  (* selectively export the most useful parts of App *)
  let not_found = App.not_found
  let get = App.get
  let post = App.post
  let put = App.put
  let patch = App.patch
  let delete = App.delete
  let all = App.all
  let any = App.any
  let middleware = App.middleware
end

module Std = struct
  module Rock = Opium_kernel.Rock
  module Response = Opium_kernel.Response
  module Request = Opium_kernel.Request
  module Router = Opium_kernel.Router
  module Route = Opium_kernel.Route
  module Middleware = Middleware
  module Body = Opium_kernel.Body
  include App_export
end
