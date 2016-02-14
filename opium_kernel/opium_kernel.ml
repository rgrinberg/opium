module Export = struct
  module Rock            = Opium_rock
  module Response        = Rock.Response
  module Request         = Rock.Request
  module Cookie          = Opium_cookie
  module Router          = Opium_router
  module Route           = Opium_route
end
include Export

module Middleware = struct
  (** Re-exports simple middleware that doesn't have auxiliary
      functions *)
  let debug = Opium_debug.debug
  let trace = Opium_debug.trace
end

module Std = struct
  include Export
  module Middleware = Middleware

  include Opium_misc
end
