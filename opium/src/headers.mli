(* A major part of this documentation is extracted from
   {{:https://github.com/inhabitedtype/httpaf/blob/master/lib/httpaf.mli}.

   Copyright (c) 2016, Inhabited Type LLC

   All rights reserved.*)

(** Header Fields

    Each header field consists of a case-insensitive {b field name} and a {b field value}.
    The order in which header fields {i with differing field names} are received is not
    significant. However, it is good practice to send header fields that contain control
    data first so that implementations can decide when not to handle a message as early as
    possible.

    A sender MUST NOT generate multiple header fields with the same field name in a
    message unless either the entire field value for that header field is defined as a
    comma-separated list or the header field is a well-known exception, e.g.,
    [Set-Cookie].

    A recipient MAY combine multiple header fields with the same field name into one
    "field-name: field-value" pair, without changing the semantics of the message, by
    appending each subsequent field value to the combined field value in order, separated
    by a comma.
    {i The order in which header fields with the same field name are received is therefore
       significant to the interpretation of the combined field value}; a proxy MUST NOT
    change the order of these field values when forwarding a message.

    {i Note.} Unless otherwise specified, all operations preserve header field order and
    all reference to equality on names is assumed to be case-insensitive.

    See {{:https://tools.ietf.org/html/rfc7230#section-3.2} RFC7230§3.2} for more
    details. *)

type t = Httpaf.Headers.t

(** The type of a case-insensitive header name. *)
type name = string

(** The type of a header value. *)
type value = string

(** {3 Constructor} *)

(** [empty] is the empty collection of header fields. *)
val empty : t

(** [of_list assoc] is a collection of header fields defined by the association list
    [assoc]. [of_list] assumes the order of header fields in [assoc] is the intended
    transmission order. The following equations should hold:

    - [to_list (of_list lst) = lst]
    - [get (of_list \[("k", "v1"); ("k", "v2")\]) "k" = Some "v2"]. *)
val of_list : (name * value) list -> t

(** [of_list assoc] is a collection of header fields defined by the association list
    [assoc]. [of_list] assumes the order of header fields in [assoc] is the {i reverse} of
    the intended trasmission order. The following equations should hold:

    - [to_list (of_rev_list lst) = List.rev lst]
    - [get (of_rev_list \[("k", "v1"); ("k", "v2")\]) "k" = Some "v1"]. *)
val of_rev_list : (name * value) list -> t

(** [to_list t] is the association list of header fields contained in [t] in transmission
    order. *)
val to_list : t -> (name * value) list

(** [to_rev_list t] is the association list of header fields contained in [t] in
    {i reverse} transmission order. *)
val to_rev_list : t -> (name * value) list

(** [add t name value] is a collection of header fields that is the same as [t] except
    with [(name, value)] added at the end of the trasmission order. The following
    equations should hold:

    - [get (add t name value) name = Some value] *)
val add : t -> name -> value -> t

(** [add_unless_exists t name value] is a collection of header fields that is the same as
    [t] if [t] already inclues [name], and otherwise is equivalent to [add t name value]. *)
val add_unless_exists : t -> name -> value -> t

(** [add_list t assoc] is a collection of header fields that is the same as [t] except
    with all the header fields in [assoc] added to the end of the transmission order, in
    reverse order. *)
val add_list : t -> (name * value) list -> t

(** [add_list_unless_exists t assoc] is a collection of header fields that is the same as
    [t] except with all the header fields in [assoc] added to the end of the transmission
    order, in reverse order if their name is not already included in [t]. *)
val add_list_unless_exists : t -> (name * value) list -> t

(** [add_multi t assoc] is the same as

    {[
      add_list
        t
        (List.concat_map assoc ~f:(fun (name, values) ->
             List.map values ~f:(fun value -> name, value)))
    ]}

    but is implemented more efficiently. For example,

    {[
      add_multi t [ "name1", [ "x", "y" ]; "name2", [ "p", "q" ] ]
      = add_list [ "name1", "x"; "name1", "y"; "name2", "p"; "name2", "q" ]
    ]} *)
val add_multi : t -> (name * value list) list -> t

(** [remove t name] is a collection of header fields that contains all the header fields
    of [t] except those that have a header-field name that are equal to [name]. If [t]
    contains multiple header fields whose name is [name], they will all be removed. *)
val remove : t -> name -> t

(** [replace t name value] is a collection of header fields that is the same as [t] except
    with all header fields with a name equal to [name] removed and replaced with a single
    header field whose name is [name] and whose value is [value]. This new header field
    will appear in the transmission order where the first occurrence of a header field
    with a name matching [name] was found. If no header field with a name equal to [name]
    is present in [t], then the result is simply [t], unchanged. *)
val replace : t -> name -> value -> t

(** {3 Destructors} *)

(** [mem t name] is true iff [t] includes a header field with a name that is equal to
    [name]. *)
val mem : t -> name -> bool

(** [get t name] returns the last header from [t] with name [name], or [None] if no such
    header is present. *)
val get : t -> name -> value option

(** [get t name] returns the last header from [t] with name [name], or raises if no such
    header is present. *)
val get_exn : t -> name -> value

(** [get_multi t name] is the list of header values in [t] whose names are equal to
    [name]. The returned list is in transmission order. *)
val get_multi : t -> name -> value list

(** {3 Iteration} *)

val iter : f:(name -> value -> unit) -> t -> unit
val fold : f:(name -> value -> 'a -> 'a) -> init:'a -> t -> 'a

(** {2 Utilities} *)

(** [to_string t] returns a string representation of the headers [t]. *)
val to_string : t -> string

(** [sexp_of_t t] converts the request [t] to an s-expression *)
val sexp_of_t : t -> Sexplib0.Sexp.t

(** [pp] formats the request [t] as an s-expression *)
val pp : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]

(** [pp_hum] formats the request [t] as a standard HTTP request *)
val pp_hum : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]
