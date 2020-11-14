module Input : sig
  type 'a t

  val create : (unit -> 'a option Lwt.t) -> 'a t
  val singleton : 'a -> 'a t
  val read : 'a t -> 'a option Lwt.t
  val iter : ('a -> unit Lwt.t) -> 'a t -> unit Lwt.t
end

module Output : sig
  type 'a t

  val create : ('a option -> unit Lwt.t) -> 'a t
  val write : 'a option -> 'a t -> unit Lwt.t
end

val transfer : 'a Input.t -> 'a Output.t -> unit Lwt.t
