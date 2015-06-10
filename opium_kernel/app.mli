(** An opium app provides a set of convenience functions and types to construct
    a rock app.

    - Re-exporting common functions needed in handlers
    - Easy handling of routes and bodies
    - Automatic generation of a command line app
*)
open Core_kernel.Std
open Opium_rock

(** An opium app is a simple builder wrapper around a rock app *)
type t with sexp_of

(** A basic empty app *)
val empty : t

(** A builder is a function that transforms an [app] by adding some
    functionality. Builders are usuallys composed with a base app
    using (|>) to create a full app *)
type builder = t -> t with sexp_of

val port : int -> builder

val cmd_name : string -> builder

(** A route is a function that returns a buidler that hooks up a
    handler to a url mapping *)
type route = string -> Handler.t -> builder with sexp_of

(** Method specific routes *)
val get : route
val post : route
val delete : route
val put : route

(** Less common method specific routes  *)
val patch : route
val options : route
val head : route

(** any [methods] will bind a route to any http method inside of
    [methods] *)
val any : Cohttp.Code.meth list -> route
(** all [methods] will bind a route to a URL regardless of the http method.
    You may escape the actual method used from the request passed. *)
val all : route

val action : Cohttp.Code.meth -> route

val middleware : Middleware.t -> builder

val name : t -> string

(** Convert an opium app to a rock app *)
val to_rock : t -> Opium_rock.App.t

val print_routes : t -> bool -> bool -> int -> unit

val print_middleware : t -> bool -> bool -> int -> unit

(** Convenience functions for a running opium app *)
type body = [
  | `Html of string
  | `Json of Ezjsonm.t
  | `Xml of string
  | `String of string ]

val json_of_body_exn : Request.t -> Ezjsonm.t Lwt.t

val string_of_body_exn : Request.t -> string Lwt.t

val urlencoded_pairs_of_body : Request.t -> (string * string list) list Lwt.t

val param : Request.t -> string -> string

val splat : Request.t -> string list

val respond : ?headers:Cohttp.Header.t
  -> ?code:Cohttp.Code.status_code
  -> body
  -> Response.t

(* Same as return (respond ...) *)
val respond' : ?headers:Cohttp.Header.t
  -> ?code:Cohttp.Code.status_code
  -> body
  -> Response.t Lwt.t

val redirect : ?headers:Cohttp.Header.t
  -> Uri.t
  -> Response.t

(* Same as return (redirect ...) *)
val redirect' : ?headers:Cohttp.Header.t
  -> Uri.t
  -> Response.t Lwt.t
