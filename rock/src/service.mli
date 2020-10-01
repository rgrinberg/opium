(** A service is simply a function that returns its result asynchronously *)
type ('req, 'rep) t = 'req -> 'rep Lwt.t
