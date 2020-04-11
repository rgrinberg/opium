module K : module type of struct
  include Opium_kernel.Make (Cohttp_lwt_unix.IO)
end

(** An opium app provides a set of convenience functions and types to construct
    a rock app.

    - Re-exporting common functions needed in handlers
    - Easy handling of routes and bodies
    - Automatic generation of a command line app *)

(** An opium app is a simple builder wrapper around a rock app *)
type t [@@deriving sexp_of]

val empty : t
(** A basic empty app *)

(** A builder is a function that transforms an [app] by adding some
    functionality. Builders are usuallys composed with a base app using (|>) to
    create a full app *)
type builder = t -> t [@@deriving sexp_of]

val port : int -> builder

val ssl : cert:string -> key:string -> builder

val cmd_name : string -> builder

(** A route is a function that returns a buidler that hooks up a handler to a
    url mapping *)
type route = string -> K.Rock.Handler.t -> builder [@@deriving sexp_of]

val not_found : K.Rock.Handler.t -> builder
(** [not_found] accepts a regular Opium handler that will be used instead of the
    default 404 handler. *)

val get : route
(** Method specific routes *)

val post : route

val delete : route

val put : route

val patch : route
(** Less common method specific routes *)

val options : route

val head : route

val any : Cohttp.Code.meth list -> route
(** any [methods] will bind a route to any http method inside of [methods] *)

val all : route
(** all [methods] will bind a route to a URL regardless of the http method. You
    may escape the actual method used from the request passed. *)

val action : Cohttp.Code.meth -> route

val middleware : K.Rock.Middleware.t -> builder

val to_rock : t -> K.Rock.App.t
(** Convert an opium app to a rock app *)

val start : t -> unit Lwt.t
(** Start an opium server. The thread returned can be cancelled to shutdown the
    server *)

val run_command : t -> unit
(** Create a cmdliner command from an app and run lwt's event loop *)

(* Run a cmdliner command from an app. Does not launch Lwt's event loop. `Error
   is returned if the command line arguments are incorrect. `Not_running is
   returned if the command was completed without the server being launched *)
val run_command' : t -> [> `Ok of unit Lwt.t | `Error | `Not_running]

(** Convenience functions for a running opium app *)
type body =
  [ `Html of string
  | `Json of Ezjsonm.t
  | `Xml of string
  | `String of string
  | `Streaming of string Lwt_stream.t ]

val json_of_body_exn : K.Rock.Request.t -> Ezjsonm.t Lwt.t

val string_of_body_exn : K.Rock.Request.t -> string Lwt.t

val urlencoded_pairs_of_body :
  K.Rock.Request.t -> (string * string list) list Lwt.t
(** Parse a request body encoded according to the
    [application/x-www-form-urlencoded] content type (typically from POST
    requests with form data) into an association list of key-value pairs. An
    exception is raised on invalid data. *)

val param : K.Rock.Request.t -> string -> string

val splat : K.Rock.Request.t -> string list

val respond :
     ?headers:Cohttp.Header.t
  -> ?code:Cohttp.Code.status_code
  -> body
  -> K.Rock.Response.t

(* Same as return (respond ...) *)
val respond' :
     ?headers:Cohttp.Header.t
  -> ?code:Cohttp.Code.status_code
  -> body
  -> K.Rock.Response.t Lwt.t

val create_stream :
     unit
  -> (   ?headers:Cohttp.Header.t
      -> ?code:Cohttp.Code.status_code
      -> unit Lwt.t
      -> K.Rock.Response.t Lwt.t)
     * (string -> unit)

val redirect : ?headers:Cohttp.Header.t -> Uri.t -> K.Rock.Response.t

(* Same as return (redirect ...) *)
val redirect' : ?headers:Cohttp.Header.t -> Uri.t -> K.Rock.Response.t Lwt.t
