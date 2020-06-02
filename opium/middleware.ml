include Opium_kernel.Middleware

let debugger = debugger ()

let logger =
  Opium_kernel.Middleware.logger
    ~time_f:(fun f ->
      let t1 = Mtime_clock.now () in
      let x = f () in
      let t2 = Mtime_clock.now () in
      let span = Mtime.span t1 t2 in
      span, x)
    ()
;;

let static = Static_serve.m
