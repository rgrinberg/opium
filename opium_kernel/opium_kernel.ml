module Export = struct
  module Rock            = Rock
  module Response        = Rock.Response
  module Request         = Rock.Request
  module Cookie          = Cookie
  module Router          = Router
  module Route           = Route
end
include Export

module Std = struct
  include Export

end

module Hmap = Hmap0
