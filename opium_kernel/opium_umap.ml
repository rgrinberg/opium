
(** Universal map (currently embedded in opium, might move into opam)
    Initial implementation by Daniel Bünzli

    A dictionary is a set of {{!keys}keys} mapping to typed values. *)

module type DICT = sig
  type 'a user_data
  (** User-specified data embedded into keys *)

  (** {1:keys Keys} *)

  module Key : sig
    type 'a t
    (** The type for dictionary keys whose lookup value is ['a]. *)

    val create : 'a user_data -> 'a t
    (** [create d] is a new dictionary key with [d] as embedded user data. *)

    val user_data : 'a t -> 'a user_data
    (** Extract user data from a key *)
  end

    (** {1:dict Dictionaries} *)

  type t
  (** The type for dictionaries. *)

  val empty : t
  (** [empty] is the empty dictionary. *)

  val is_empty : t -> bool
  (** [is_empty d] is [true] iff [d] is empty. *)

  val mem : 'a Key.t -> t -> bool
  (** [mem k d] is [true] iff [k] has a mapping in [d]. *)

  val add : 'a Key.t -> 'a -> t -> t
  (** [add k v d] is [d] with [k] mapping to [v]. *)

  val rem : 'a Key.t -> t -> t
  (** [rem k d] is [d] with [k] unbound. *)

  val find_exn : 'a Key.t -> t -> 'a
  (** [find d k] is [k]'s mapping in [d], if any.
      @raise Not_found if the key is not present *)

  val find : 'a Key.t -> t -> 'a option
  (** [find d k] is [k]'s mapping in [d], if any. *)

  val get : 'a Key.t -> t -> 'a
  (** [get k d] is [k]'s mapping in [d].

      {b Raises.} [Invalid_argument] if [k] is not bound in [d]. *)

  type pair = Pair : 'a Key.t * 'a -> pair

  val fold : ('a -> pair -> 'a) -> 'a -> t -> 'a
end

module Make(D : sig type _ t end)
: DICT with type 'a user_data = 'a D.t
= struct
  type 'a user_data = 'a D.t

  (* Dictionaries see http://mlton.org/PropertyList *)

  (* Keys *)

  module Key = struct
    let univ (type s) () =
      let module M = struct exception E of s end in
      (fun x -> M.E x), (function M.E x -> x | _ -> raise Not_found)

    let key_id =
      let count = ref (-1) in
      fun () -> incr count; !count

    type 'a t =
      { id : int;
        name : string;
        data : 'a user_data;
        to_univ : 'a -> exn;
        of_univ : exn -> 'a; }

    let create data (type v) =
      let id = key_id () in
      let to_univ, of_univ = univ () in
      { id; data; name = ""; to_univ; of_univ }

    let user_data k = k.data

    type boxed = V : 'a t -> boxed
    let compare (V k0) (V k1) = (compare : int -> int -> int) k0.id k1.id
  end

  (* Dictionaries *)

  module M = Map.Make(struct
    type t = Key.boxed
    let compare = Key.compare
  end)
  type t = exn M.t

  let empty = M.empty
  let is_empty = M.is_empty
  let mem k d = M.mem (Key.V k) d
  let add k v d  = M.add (Key.V k) (k.Key.to_univ v) d
  let rem k d = M.remove (Key.V k) d
  let find k d = try Some (k.Key.of_univ (M.find (Key.V k) d)) with Not_found -> None
  let find_exn k d = k.Key.of_univ (M.find (Key.V k) d)
  let get k d = match find k d with
    | Some v -> v
    | None -> invalid_arg "key unbound in dictionary"

  type pair = Pair : 'a Key.t * 'a -> pair

  let fold (type acc) f acc m =
    let f'
      : Key.boxed -> exn -> acc -> acc 
      = fun (Key.V k) e acc ->
        let v = k.Key.of_univ e in
        f acc (Pair (k,v))
    in
    M.fold f' m acc
end

module Default = struct
  include Make(struct
    type 'a t = string * ('a -> Sexplib.Sexp.t)
  end)

  let sexp_of_t m =
    let open Sexplib.Sexp in
    let l = fold
      (fun l (Pair (k,v)) ->
        let name, to_sexp = Key.user_data k in
        List [Atom name; to_sexp v] :: l)
      [] m
    in
    List l
end
