include Opium_kernel.App

let start app port =
  Lwt_log.ign_info_f "Running on port: %d" port;
  app |> Opium_kernel.App.to_rock |> Opium_rock_unix.run ~port

let cmd_run app port host print_routes print_middleware debug verbose errors =
  if print_routes then begin
    Opium_kernel.App.print_routes app debug verbose port;
    exit 0;
  end;
  if print_middleware then begin
    Opium_kernel.App.print_middleware app debug verbose port;
    exit 0;
  end;
  (** TODO pass along host, debug, verbose & errors **)
  start app port

module Cmds = struct
  open Cmdliner

  let routes =
    let doc = "print routes" in
    Arg.(value & flag & info ["r"; "routes"] ~doc)
  let middleware =
    let doc = "print middleware stack" in
    Arg.(value & flag & info ["m"; "middlware"] ~doc)
  let port =
    let doc = "port" in
    Arg.(value & opt int 3000 & info ["p"; "port"] ~doc)
  let interface =
    let doc = "interface" in
    Arg.(value & opt string "0.0.0.0" & info ["i"; "interface"] ~doc)
  let debug =
    let doc = "enable debug information" in
    Arg.(value & flag & info ["d"; "debug"] ~doc)
  let verbose =
    let doc = "enable verbose mode" in
    Arg.(value & flag & info ["v"; "verbose"] ~doc)
  let errors =
    let doc = "raise on errors. default is print" in
    Arg.(value & flag & info ["f"; "fatal"] ~doc)

  let term =
    let open Cmdliner in
    let open Cmdliner.Term in
    fun app ->
      pure cmd_run $ (pure app) $ port $ interface $ routes
      $ middleware $ debug $ verbose $ errors

  let info name =
    let doc = Printf.sprintf "%s (Opium App)" name in
    let man = [] in
    Term.info name ~doc ~man
end

let run_command' app =
  let open Cmdliner in
  let cmd = Cmds.term app in
  match Term.eval (cmd, Cmds.info (Opium_kernel.App.name app)) with
  | `Ok a    -> `Ok a
  | `Error _ -> `Error
  | _        -> `Not_running

let run_command app =
  match app |> run_command' with
  | `Ok a        -> Lwt_main.run a
  | `Error       -> exit 1
  | `Not_running -> exit 0
