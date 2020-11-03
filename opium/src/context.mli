(** A context holds heterogeneous value and is passed to the requests or responses. *)

(** {2:keys Keys} *)

(** The type for keys whose lookup value is of type ['a]. *)
type 'a key = 'a Rock.Context.key

(** {3 [Key]} *)

module Key : sig
  (** {2:keys Keys} *)

  (** The type for key information. *)
  type 'a info = 'a Rock.Context.Key.info

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
  type t = Rock.Context.Key.t

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

(** {2:maps Maps} *)

(** The type for heterogeneous value maps. *)
type t = Rock.Context.t

(** {3 [empty]} *)

(** [empty] is the empty map. *)
val empty : t

(** {3 [is_empty]} *)

(** [is_empty m] is [true] iff [m] is empty. *)
val is_empty : t -> bool

(** {3 [mem]} *)

(** [mem k m] is [true] iff [k] is bound in [m]. *)
val mem : 'a key -> t -> bool

(** {3 [add]} *)

(** [add k v m] is [m] with [k] bound to [v]. *)
val add : 'a key -> 'a -> t -> t

(** {3 [singleton]} *)

(** [singleton k v] is [add k v empty]. *)
val singleton : 'a key -> 'a -> t

(** {3 [rem]} *)

(** [rem k m] is [m] with [k] unbound. *)
val rem : 'a key -> t -> t

(** {3 [find]} *)

(** [find k m] is the value of [k]'s binding in [m], if any. *)
val find : 'a key -> t -> 'a option

(** {3 [find_exn]} *)

(** [find_exn k m] is the value of [k]'s binding find_exn [m].

    @raise Invalid_argument if [k] is not bound in [m]. *)
val find_exn : 'a key -> t -> 'a

(** {2:utilities Utilities} *)

(** {3 [sexp_of_t]} *)

(** [sexp_of_t t] converts the request [t] to an s-expression *)
val sexp_of_t : t -> Sexplib0.Sexp.t

(** {3 [pp_hum]} *)

(** [pp_hum] formats the request [t] as a standard HTTP request *)
val pp_hum : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]
