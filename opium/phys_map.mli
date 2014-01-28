type t
val empty : t
val mem : t -> _ -> t
val remove : t -> _ -> t
val add : t -> _ -> t
val find : t -> 'a -> 'a option
