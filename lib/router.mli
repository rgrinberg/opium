open Core.Std
       
type meth = Cohttp.Code.meth
              
module Method_bin : sig
  type 'a t = 'a Queue.t array
  val create : unit -> 'a Queue.t Array.t
  val int_of_meth : meth -> int
  val add : 'a Queue.t Array.t -> meth -> 'a -> unit
  val get : 'a Array.t -> meth -> 'a
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
  meth : meth;
  route : Route.t;
  action : 'action;
}
val matching_endpoint :
  'a endpoint Queue.t Array.t ->
  meth ->
  string -> ('a endpoint * (string * string) List.t) option

module Env : sig
  type path_params = (string * string) list
  val key : path_params Univ_map.Key.t
end

val param : Rock.Request.t -> string -> string
val m :
  (Rock.Request.t -> 'a) endpoint Queue.t Array.t ->
  (Rock.Request.t -> 'a) -> Rock.Request.t -> 'a
