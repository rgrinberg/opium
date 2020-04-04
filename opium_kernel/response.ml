type t =
  { version: Httpaf.Version.t option
  ; status: Httpaf.Status.t
  ; reason: string option
  ; headers: Httpaf.Headers.t
  ; body: Body.t
  ; env: Hmap0.t }

let make ?version ?(status = `OK) ?reason ?(headers = Httpaf.Headers.empty)
    ?(body = Body.empty) ?(env = Hmap0.empty) () =
  {version; status; reason; headers; body; env}
