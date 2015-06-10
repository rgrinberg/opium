open Opium.Std

(** Start an opium server. The thread returned can be cancelled to shutdown the
    server *)
val start : App.t -> int -> unit Lwt.t

(** Create a cmdliner command from an app and run lwt's event loop *)
val run_command : App.t -> unit

(* Run a cmdliner command from an app. Does not launch Lwt's event loop.
   `Error is returned if the command line arguments are incorrect.
   `Not_running is returned if the command was completed without the server
   being launched *)
val run_command' : App.t -> [> `Ok of unit Lwt.t | `Error | `Not_running ]


