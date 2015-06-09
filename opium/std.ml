module Rock            = Opium_rock
module Response        = Rock.Response
module Request         = Rock.Request
module Cookie          = Cookie
module Router          = Router
module App             = App

module Middleware = struct
  (** Re-exports simple middleware that doesn't have auxiliary
      functions *)
  let debug = Debug.debug
  let trace = Debug.trace
end

(* selectively export the most useful parts of App *)
let param     = App.param
let splat     = App.splat
let respond   = App.respond
let respond'  = App.respond'
let redirect  = App.redirect
let redirect' = App.redirect'

let get    = App.get
let post   = App.post
let put    = App.put
let delete = App.delete

let all = App.all
let any = App.any

let middleware = App.middleware

include Opium_misc
