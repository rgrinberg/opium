type t =
  { version: Httpaf.Version.t option
  ; target: string
  ; headers: Httpaf.Headers.t
  ; meth: Httpaf.Method.standard
  ; body: Body.t
  ; env: Hmap0.t }

let make ?version ?(body = Body.empty) ?(env = Hmap0.empty)
    ?(headers = Httpaf.Headers.empty) target meth () =
  {version; target; headers; meth; body; env}
