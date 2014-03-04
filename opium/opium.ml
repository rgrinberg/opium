open Core.Std
open Async.Std

(** Open this module where you define your application's routes *)
module Std = struct
  module Response = Rock.Response
  module Request = Rock.Request
  module Rock = Rock
  module Cookie = Cookie
  module Static = Static
  module App = App

  (* selectively export the most useful parts of App *)
  let param = App.param
  let respond = App.respond
  let respond' = App.respond'

  let get = App.get
  let post = App.post
  let put = App.put
  let delete = App.delete
end
