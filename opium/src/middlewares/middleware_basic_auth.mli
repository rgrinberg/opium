val m
  :  ?unauthorized_handler:Rock.Handler.t
  -> key:'a Context.key
  -> realm:string
  -> auth_callback:(username:string -> password:string -> 'a option)
  -> unit
  -> Rock.Middleware.t
