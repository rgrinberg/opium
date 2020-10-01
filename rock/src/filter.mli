(** A filter is a higher order function that transforms a service into another service. *)

type ('req, 'rep, 'req', 'rep') t = ('req, 'rep) Service.t -> ('req', 'rep') Service.t

(** A filter is simple when it preserves the type of a service *)
type ('req, 'rep) simple = ('req, 'rep, 'req, 'rep) t

val ( >>> ) : ('q1, 'p1, 'q2, 'p2) t -> ('q2, 'p2, 'q3, 'p3) t -> ('q1, 'p1, 'q3, 'p3) t

val apply_all
  :  ('req, 'rep) simple list
  -> ('req, 'rep) Service.t
  -> ('req, 'rep) Service.t
