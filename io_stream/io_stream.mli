module In : sig
  type 'a t

  val create : (unit -> 'a option Lwt.t) -> 'a t
  val of_list : 'a list -> 'a t
  val read : 'a t -> 'a option Lwt.t
  val iter : ('a -> unit Lwt.t) -> 'a t -> unit Lwt.t
end

module Out : sig
  type 'a t

  val create : ('a option -> unit Lwt.t) -> 'a t
  val write : 'a option -> 'a t -> unit Lwt.t
end

val connect : 'a In.t -> 'a Out.t -> unit Lwt.t
