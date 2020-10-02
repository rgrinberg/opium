(** A service is a function that returns its result asynchronously. *)

type ('req, 'rep) t = 'req -> 'rep Lwt.t
