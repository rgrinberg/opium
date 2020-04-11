module Make (IO : Cohttp_lwt.S.IO) = struct
  module type S = Rock_intf.S

  module Export = struct
    module Rock = Rock.Make (IO)
    module Response = Rock.Response
    module Request = Rock.Request
    module Cookie = Cookie.Make (IO) (Rock)
    module Router = Router.Make (IO) (Rock)
    module Route = Route
  end

  include Export
  module Std = Export
  module Hmap = Hmap0
end

module type S = Rock_intf.S

module Route = Route
module Hmap = Hmap0
