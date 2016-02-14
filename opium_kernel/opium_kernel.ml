module Export = struct
  module Rock            = Opium_rock
  module Response        = Rock.Response
  module Request         = Rock.Request
  module Cookie          = Opium_cookie
  module Router          = Opium_router
  module Route           = Opium_route
end
include Export

module Std = struct
  include Export

  include Opium_misc
end
