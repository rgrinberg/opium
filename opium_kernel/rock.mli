(** A tiny clone of ruby's Rack protocol in OCaml. Which is slightly more
    general and inspired by Finagle. It's not imperative to have this to for
    such a tiny framework but it makes extensions a lot more straightforward *)

module type S = Rock_intf.S

module Make (IO : Cohttp_lwt.S.IO) : S with module IO := IO
