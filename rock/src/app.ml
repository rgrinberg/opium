type t =
  { middlewares : Middleware.t list
  ; handler : Handler.t
  }

let append_middleware t m = { t with middlewares = t.middlewares @ [ m ] }
let create ?(middlewares = []) ~handler () = { middlewares; handler }
