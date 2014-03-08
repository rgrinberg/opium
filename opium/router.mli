open Core.Std

module Method_bin : sig
  type 'a t = 'a Queue.t array with sexp
  val create : unit -> 'a Queue.t Array.t
  val int_of_meth : Cohttp.Code.meth -> int
  val add : 'a Queue.t Array.t -> Cohttp.Code.meth -> 'a -> unit
  val get : 'a Array.t -> Cohttp.Code.meth -> 'a
end

module Route : sig
  type t = Pcre.regexp
  val get_named_matches :
    ?rex:Pcre.regexp ->
    ?pat:string -> string -> (string * string) List.t
  val pcre_of_route : string -> string
  val create : string -> Pcre.regexp
  val match_url :
    Pcre.regexp -> string -> (string * string) List.t option
end

type 'action endpoint = {
  meth : Cohttp.Code.meth;
  route : Route.t;
  action : 'action;
} with fields, sexp

val matching_endpoint :
  'a endpoint Queue.t Array.t -> Cohttp.Code.meth ->
  string -> ('a endpoint * (string * string) List.t) option

val param : Rock.Request.t -> string -> string
val m : (Rock.Handler.t endpoint) Method_bin.t -> Rock.Middleware.t
