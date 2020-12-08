open Opium

module Schema = struct
  open Graphql_lwt

  type context = unit

  type role =
    | User
    | Admin

  type user =
    { id : int
    ; name : string
    ; role : role
    }

  let users =
    [ { id = 1; name = "Alice"; role = Admin }; { id = 2; name = "Bob"; role = User } ]
  ;;

  let role : (context, role option) Graphql_lwt.Schema.typ =
    Schema.(
      enum
        "role"
        ~doc:"The role of a user"
        ~values:[ enum_value "USER" ~value:User; enum_value "ADMIN" ~value:Admin ])
  ;;

  let user : (context, user option) Graphql_lwt.Schema.typ =
    Schema.(
      obj "user" ~doc:"A user in the system" ~fields:(fun _ ->
          [ field
              "id"
              ~doc:"Unique user identifier"
              ~typ:(non_null int)
              ~args:Arg.[]
              ~resolve:(fun _info p -> p.id)
          ; field
              "name"
              ~typ:(non_null string)
              ~args:Arg.[]
              ~resolve:(fun _info p -> p.name)
          ; field
              "role"
              ~typ:(non_null role)
              ~args:Arg.[]
              ~resolve:(fun _info p -> p.role)
          ]))
  ;;

  let schema =
    Graphql_lwt.Schema.(
      schema
        [ field
            "users"
            ~typ:(non_null (list (non_null user)))
            ~args:Arg.[]
            ~resolve:(fun _info () -> users)
        ])
  ;;
end

let graphql =
  let handler = Opium_graphql.make_handler ~make_context:(fun _req -> ()) Schema.schema in
  Opium.App.all "/" handler
;;

let graphiql =
  let handler = Opium_graphql.make_graphiql_handler ~graphql_endpoint:"/" in
  Opium.App.get "/graphiql" handler
;;

let _ =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Debug);
  App.empty |> graphql |> graphiql |> App.run_command
;;
