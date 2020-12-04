val m
  :  ?unauthorized_handler:Rock.Handler.t
  -> key:'a Context.key
  -> realm:string
  -> auth_callback:(username:string -> password:string -> 'a option Lwt.t)
  -> unit
  -> Rock.Middleware.t
