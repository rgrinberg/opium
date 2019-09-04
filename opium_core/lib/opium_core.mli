(** A service is simply a function that returns its result asynchronously *)
module Service : sig
  type ('req, 'rep) t = 'req -> 'rep Lwt.t

  val id : ('a, 'a) t

  val const : 'rep -> (_, 'rep) t
end

(** A filter is a higher order function that transforms a service into another
    service. *)
module Filter : sig
  type ('req, 'rep, 'req', 'rep') t =
    ('req, 'rep) Service.t -> ('req', 'rep') Service.t

  type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t
  (** A filter is simple when it preserves the type of a service *)

  val id : ('req, 'rep) simple

  val ( >>> ) :
    ('q1, 'p1, 'q2, 'p2) t -> ('q2, 'p2, 'q3, 'p3) t -> ('q1, 'p1, 'q3, 'p3) t

  val apply_all :
       ('req, 'rep) simple list
    -> ('req, 'rep) Service.t
    -> ('req, 'rep) Service.t
end
