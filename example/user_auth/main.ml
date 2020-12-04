open Opium

module User = struct
  type t = { username : string }

  let t_of_sexp sexp =
    let open Sexplib0.Sexp in
    match sexp with
    | List [ Atom "username"; Atom username ] -> { username }
    | _ -> failwith "invalid user sexp"
  ;;

  let sexp_of_t t =
    let open Sexplib0.Sexp in
    List [ Atom "username"; Atom t.username ]
  ;;
end

module Env_user = struct
  type t = User.t

  let key : t Opium.Context.key = Opium.Context.Key.create ("user", User.sexp_of_t)
end

let admin_handler req =
  let user = Opium.Context.find_exn Env_user.key req.Request.env in
  Response.of_plain_text (Printf.sprintf "Welcome back, %s!\n" user.username)
  |> Lwt.return
;;

let unauthorized_handler _req =
  Response.of_plain_text ~status:`Unauthorized "Unauthorized!\n" |> Lwt.return
;;

let auth_callback ~username ~password =
  match username, password with
  | "admin", "admin" -> Lwt.return_some User.{ username }
  | _ -> Lwt.return_none
;;

let auth_middleware =
  Middleware.basic_auth
    ~key:Env_user.key
    ~auth_callback
    ~realm:"my_realm"
    ~unauthorized_handler
    ()
;;

let _ =
  App.empty
  |> App.middleware auth_middleware
  |> App.get "/" admin_handler
  |> App.run_command
;;
