(** A context holds heterogeneous value and is passed to the requests or responses. *)

(** {2:keys Keys} *)

(** The type for keys whose lookup value is of type ['a]. *)
type 'a key

(** {3 [Key]} *)

module Key : sig
  (** {2:keys Keys} *)

  (** The type for key information. *)
  type 'a info = string * ('a -> Sexplib0.Sexp.t)

  (** {3 [create]} *)

  (** [create i] is a new key with information [i]. *)
  val create : 'a info -> 'a key

  (** {3 [info]} *)

  (** [info k] is [k]'s information. *)
  val info : 'a key -> 'a info

  (** {2:exists Existential keys}

      Exisential keys allow to compare keys. This can be useful for functions like
      {!filter}. *)

  (** The type for existential keys. *)
  type t

  (** {3 [hide_type]} *)

  (** [hide_type k] is an existential key for [k]. *)
  val hide_type : 'a key -> t

  (** {3 [equal]} *)

  (** [equal k k'] is [true] iff [k] and [k'] are the same key. *)
  val equal : t -> t -> bool

  (** {3 [compare]} *)

  (** [compare k k'] is a total order on keys compatible with {!equal}. *)
  val compare : t -> t -> int
end

(** {1:maps Maps} *)

(** The type for heterogeneous value maps. *)
type t

(** [empty] is the empty map. *)
val empty : t

(** [is_empty m] is [true] iff [m] is empty. *)
val is_empty : t -> bool

(** [mem k m] is [true] iff [k] is bound in [m]. *)
val mem : 'a key -> t -> bool

(** [add k v m] is [m] with [k] bound to [v]. *)
val add : 'a key -> 'a -> t -> t

(** [singleton k v] is [add k v empty]. *)
val singleton : 'a key -> 'a -> t

(** [rem k m] is [m] with [k] unbound. *)
val rem : 'a key -> t -> t

(** [find k m] is the value of [k]'s binding in [m], if any. *)
val find : 'a key -> t -> 'a option

(** [get k m] is the value of [k]'s binding in [m].

    @raise Invalid_argument if [k] is not bound in [m]. *)
val get : 'a key -> t -> 'a

(** The type for bindings. *)
type binding = B : 'a key * 'a -> binding

(** [iter f m] applies [f] to all bindings of [m]. *)
val iter : (binding -> unit) -> t -> unit

(** [fold f m acc] folds over the bindings of [m] with [f], starting with [acc] *)
val fold : (binding -> 'a -> 'a) -> t -> 'a -> 'a

(** [for_all p m] is [true] iff all bindings of [m] satisfy [p]. *)
val for_all : (binding -> bool) -> t -> bool

(** [exists p m] is [true] iff there exists a bindings of [m] that satisfies [p]. *)
val exists : (binding -> bool) -> t -> bool

(** [filter p m] are the bindings of [m] that satisfy [p]. *)
val filter : (binding -> bool) -> t -> t

(** [cardinal m] is the number of bindings in [m]. *)
val cardinal : t -> int

(** [any_binding m] is a binding of [m] (if not empty). *)
val any_binding : t -> binding option

(** [get_any_binding m] is a binding of [m].

    @raise Invalid_argument if [m] is empty. *)
val get_any_binding : t -> binding
