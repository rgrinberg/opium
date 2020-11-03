type t =
  { filter : (Request.t, Response.t) Filter.simple
  ; name : string
  }

let create ~filter ~name = { filter; name }
let apply { filter; _ } handler = filter handler
