(** An opium app provides a set of convenience functions and types to construct a rock
    app.

    - Re-exporting common functions needed in handlers
    - Easy handling of routes and bodies
    - Automatic generation of a command line app *)
open Opium_kernel.Rock

(** An opium app is a simple builder wrapper around a rock app *)
type t

(** A basic empty app *)
val empty : t

(** A builder is a function that transforms an [app] by adding some functionality.
    Builders are usuallys composed with a base app using (|>) to create a full app *)
type builder = t -> t

val host : string -> builder
val port : int -> builder
val ssl : cert:string -> key:string -> builder
val cmd_name : string -> builder

(** [not_found] accepts a regular Opium handler that will be used instead of the default
    404 handler. *)
val not_found : (Request.t -> (Httpaf.Headers.t * Body.t) Lwt.t) -> builder

(** A route is a function that returns a buidler that hooks up a handler to a url mapping *)
type route = string -> Handler.t -> builder

(** Method specific routes *)
val get : route

val post : route
val delete : route
val put : route
val patch : route

(* val patch : route *)

(** Less common method specific routes *)
val options : route

val head : route

(** any [methods] will bind a route to any http method inside of [methods] *)
val any : Httpaf.Method.t list -> route

(** all [methods] will bind a route to a URL regardless of the http method. You may escape
    the actual method used from the request passed. *)
val all : route

val action : Httpaf.Method.t -> route
val middleware : Middleware.t -> builder

(** Convert an opium app to a rock app *)
val to_rock : t -> Opium_kernel.Rock.App.t

(** Start an opium server. The thread returned can be cancelled to shutdown the server *)
val start : t -> Lwt_io.server Lwt.t

(** Create a cmdliner command from an app and run lwt's event loop *)
val run_command : t -> unit

(* Run a cmdliner command from an app. Does not launch Lwt's event loop. `Error is
   returned if the command line arguments are incorrect. `Not_running is returned if the
   command was completed without the server being launched *)
val run_command' : t -> [> `Ok of unit Lwt.t | `Error | `Not_running ]
val json_of_body_exn : Request.t -> Yojson.Safe.t Lwt.t
val string_of_body_exn : Request.t -> string Lwt.t

(** Parse a request body encoded according to the [application/x-www-form-urlencoded]
    content type (typically from POST requests with form data) into an association list of
    key-value pairs. An exception is raised on invalid data. *)
val urlencoded_pairs_of_body : Request.t -> (string * string list) list Lwt.t

val param : Request.t -> string -> string
val splat : Request.t -> string list
