(** A polymorphic set module that uses physical equality *)
type 'a t
val empty : _ t
val mem : _ t -> key:_ -> bool
val remove : 'a t -> key:_ -> 'a t
val add : 'a t -> key:_ -> data:'a -> [`Ok of 'a t | `Duplicate]
val add_exn : 'a t -> key:_ -> data:'a -> 'a t
val find : 'a t -> key:_ -> 'a option
