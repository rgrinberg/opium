(** Trie based router. Allows for no ambiguities beteween routes. *)

open Import

module Route : sig
  (** A route is defined by the following (pseaudo) bnf:

      {[
        <route> ::= "/" <elements> "/**"?

        <elements> ::=
          | ""
          | <elements> "/" <param>
          | <elements> "/" <literal>

        <param> ::=
          | ":" [^/]+
          | "*"

        <literal> ::= [^/]+
      ]}

      Examples:

      - "/foo/bar" : route that only matches "/foo/bar"
      - "/:foo/*" : route that matches a named parmeter "foo" and unnamed parameter
      - "/foo/:bar/**" : A route that matches any route of the regex form /foo/[^/]+/.* *)
  type t

  val of_string_result : string -> (t, string) result
  val of_string : string -> t
  val sexp_of_t : t -> Sexp.t
  val to_string : t -> string
end

module Params : sig
  (** Parameters obtained after a route matches *)
  type t

  (** Extract a single named parameter *)
  val named : t -> string -> string

  (** only for testing *)
  val all_named : t -> (string * string) list

  (** Only for testing *)
  val make
    :  named:(string * string) list
    -> unnamed:string list
    -> full_splat:string option
    -> t

  (** Etract all unnamed "*" parameters in order *)
  val unnamed : t -> string list

  (** [full_splat t] returns the raw string matched by "**". *)
  val full_splat : t -> string option

  (** [splat t] extracts unnamed + full_splat in a single list. This is present to match
      the old routing behavior *)
  val splat : t -> string list

  val sexp_of_t : t -> Sexp.t
  val equal : t -> t -> bool
  val pp : Format.formatter -> t -> unit
end

(** Represents a router *)
type 'a t

(** Empty router that matches no routes *)
val empty : 'a t

(** [add router route h] Add [route] to [router] and attach [h] when [route] matches.

    It's not allowed to have more than a single route match a single path.*)
val add : 'a t -> Route.t -> 'a -> 'a t

(** [update router route ~f] updates the value at [route]. [f None] is called if the route
    wasn't added before. *)
val update : 'a t -> Route.t -> f:('a option -> 'a) -> 'a t

(** [match_url router url] atempts to match [url] and returns the handler at the route and
    parsed parameters. *)
val match_url : 'a t -> string -> ('a * Params.t) option

val sexp_of_t : ('a -> Sexp.t) -> 'a t -> Sexp.t
