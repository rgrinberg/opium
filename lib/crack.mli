(** Finagle inspired type definitions *)
open Core.Std
open Async.Std

module Service : sig
  type ('req, 'rep) t = 'req -> 'rep Deferred.t

  val id : ('a, 'a) t
end

module Filter : sig
  type ('req, 'rep, 'req', 'rep') t =
    ('req, 'rep) Service.t -> ('req', 'rep') Service.t

  type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t

  val (>>>) : ('q1, 'p1, 'q2, 'p2) t
    -> ('q2, 'p2, 'q3, 'p3) t
    -> ('q1, 'p1, 'q3, 'p3) t

  val id : ('req, 'rep) simple
end
