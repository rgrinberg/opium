open Core.Std
open Async.Std

module Std = struct
  module Response = Rock.Response
  module Request = Rock.Request
  module Rock = Rock
  module Cookie = Cookie
  include App
end
