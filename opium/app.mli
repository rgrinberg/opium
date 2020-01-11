open Opium_kernel.Rock
(** An opium app provides a set of convenience functions and types to construct
    a rock app.

    - Re-exporting common functions needed in handlers
    - Easy handling of routes and bodies
    - Automatic generation of a command line app *)

(** An opium app is a simple builder wrapper around a rock app *)
type t

val empty : t
(** A basic empty app *)

(** A builder is a function that transforms an [app] by adding some
    functionality. Builders are usuallys composed with a base app
    using (|>) to create a full app *)
type builder = t -> t

val port : int -> builder

val ssl : cert:string -> key:string -> builder

val cmd_name : string -> builder

val not_found : Handler.t -> builder
(** [not_found] accepts a regular Opium handler that will be used instead of the
    default 404 handler. *)

(** A route is a function that returns a buidler that hooks up a
    handler to a url mapping *)
type route = string -> Handler.t -> builder

val get : route
(** Method specific routes *)

val post : route

val delete : route

val put : route

(** Less common method specific routes  *)
(* val patch : route *)
val options : route

val head : route

(** any [methods] will bind a route to any http method inside of
    [methods] *)
val any : Httpaf.Method.t list -> route
(** all [methods] will bind a route to a URL regardless of the http method.
    You may escape the actual method used from the request passed. *)
val all : route
(** all [methods] will bind a route to a URL regardless of the http method. You
    may escape the actual method used from the request passed. *)

val action : Httpaf.Method.t -> route

val middleware : Middleware.t -> builder

val to_rock : t -> Opium_kernel.Rock.App.t
(** Convert an opium app to a rock app *)

(** Start an opium server. The thread returned can be cancelled to shutdown the
    server *)
val start : t -> Lwt_io.server Lwt.t

val run_command : t -> unit
(** Create a cmdliner command from an app and run lwt's event loop *)

(* Run a cmdliner command from an app. Does not launch Lwt's event loop.
   `Error is returned if the command line arguments are incorrect.
   `Not_running is returned if the command was completed without the server
   being launched *)
val run_command' : t -> [> `Ok of Lwt_io.server Lwt.t | `Error | `Not_running ]

type body =
  [ `Html of string
  | `Json of Ezjsonm.t
  | `Xml of string
  | `String of string
  | `Bigstring of Bigstringaf.t]

val json_of_body_exn : Request.t -> Ezjsonm.t Lwt.t

val string_of_body_exn : Request.t -> string Lwt.t

val urlencoded_pairs_of_body : Request.t -> (string * string list) list Lwt.t
(** Parse a request body encoded according to the
    [application/x-www-form-urlencoded] content type (typically from POST
    requests with form data) into an association list of key-value pairs. An
    exception is raised on invalid data. *)

val param : Request.t -> string -> string

val splat : Request.t -> string list

val respond : ?headers:Httpaf.Headers.t
  -> ?code:Httpaf.Status.t
  -> body
  -> Response.t

(* Same as return (respond ...) *)
val respond' : ?headers:Httpaf.Headers.t
  -> ?code: Httpaf.Status.t
  -> body
  -> Response.t Lwt.t

val redirect : ?headers: Httpaf.Headers.t
  -> Uri.t
  -> Response.t

(* Same as return (redirect ...) *)
val redirect' : ?headers: Httpaf.Headers.t
  -> Uri.t
  -> Response.t Lwt.t
