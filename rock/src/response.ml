type t =
  { version : Httpaf.Version.t
  ; status : Httpaf.Status.t
  ; reason : string option
  ; headers : Httpaf.Headers.t
  ; body : Body.t
  ; env : Context.t
  }

let make
    ?(version = { Httpaf.Version.major = 1; minor = 1 })
    ?(status = `OK)
    ?reason
    ?(headers = Httpaf.Headers.empty)
    ?(body = Body.empty)
    ?(env = Context.empty)
    ()
  =
  { version; status; reason; headers; body; env }
;;
