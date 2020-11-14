(** A tiny clone of ruby's Rack protocol in OCaml. Which is slightly more general and
    inspired by Finagle. It's not imperative to have this to for such a tiny framework but
    it makes extensions a lot more straightforward *)

module App = App
module Context = Context
module Request = Request
module Response = Response
module Body = Body
module Service = Service
module Filter = Filter
module Handler = Handler
module Middleware = Middleware
module Server_connection = Server_connection
