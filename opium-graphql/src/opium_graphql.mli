module Params : sig
  type t =
    { query : string option
    ; variables : (string * Yojson.Basic.t) list option
    ; operation_name : string option
    }

  val empty : t
  val of_uri_exn : Uri.t -> t
  val of_json_body_exn : string -> t
  val of_graphql_body : string -> t
  val merge : t -> t -> t
  val post_params_exn : Opium.Request.t -> string -> t
  val of_req_exn : Opium.Request.t -> string -> t

  val extract
    :  Opium.Request.t
    -> string
    -> ( string * (string * Graphql_parser.const_value) list option * string option
       , string )
       result
end

module Schema = Graphql_lwt.Schema

val execute_query
  :  'a
  -> 'a Schema.schema
  -> Schema.variables option
  -> string option
  -> string
  -> [ `Response of Yojson.Basic.t
     | `Stream of Yojson.Basic.t Schema.response Schema.Io.Stream.t
     ]
     Schema.response
     Lwt.t

val execute_request : 'a Schema.schema -> 'a -> Opium.Request.t -> Opium.Response.t Lwt.t

val make_handler
  :  ?make_context:(Opium.Request.t -> unit)
  -> unit Schema.schema
  -> Opium.Request.t
  -> Opium.Response.t Lwt.t

val graphiql_handler
  :  graphql_endpoint:string
  -> Opium.Request.t
  -> Opium.Response.t Lwt.t
