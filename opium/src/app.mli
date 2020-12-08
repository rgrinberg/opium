(** An opium app provides a set of convenience functions and types to construct a rock
    app.

    - Re-exporting common functions needed in handlers
    - Easy handling of routes and bodies
    - Automatic generation of a command line app *)

(** An opium app is a simple builder wrapper around a rock app *)
type t

(** [to_handler t] converts the app t to a [Rock] handler. *)
val to_handler : t -> Rock.Handler.t

(** A basic empty app *)
val empty : t

(** A builder is a function that transforms an [app] by adding some functionality.
    Builders are usuallys composed with a base app using (|>) to create a full app *)
type builder = t -> t

val host : string -> builder

(** [backlog] specifies the maximum number of clients that can have a pending connection
    request to the Opium server. *)
val backlog : int -> builder

val port : int -> builder
val jobs : int -> builder
val cmd_name : string -> builder

(** [not_found] accepts a regular Opium handler that will be used instead of the default
    404 handler. *)
val not_found : (Request.t -> (Headers.t * Body.t) Lwt.t) -> builder

(** A route is a function that returns a buidler that hooks up a handler to a url mapping *)
type route = string -> Rock.Handler.t -> builder

(** Method specific routes *)

val get : route
val post : route
val delete : route
val put : route
val options : route
val head : route
val patch : route

(** any [methods] will bind a route to any http method inside of [methods] *)
val any : Method.t list -> route

(** all [methods] will bind a route to a URL regardless of the http method. You may escape
    the actual method used from the request passed. *)
val all : route

val action : Method.t -> route
val middleware : Rock.Middleware.t -> builder

(** Start an opium server. The thread returned can be cancelled to shutdown the server *)
val start : t -> Lwt_io.server Lwt.t

(** Start an opium server with multiple processes. *)
val start_multicore : t -> unit

(** Create a cmdliner command from an app and run lwt's event loop *)
val run_command : t -> unit

(* Run a cmdliner command from an app. Does not launch Lwt's event loop. `Error is
   returned if the command line arguments are incorrect. `Not_running is returned if the
   command was completed without the server being launched *)
val run_command' : t -> [> `Ok of unit Lwt.t | `Error | `Not_running ]

(** Create a cmdliner command from an app and spawn with multiple processes. *)
val run_multicore : t -> unit
