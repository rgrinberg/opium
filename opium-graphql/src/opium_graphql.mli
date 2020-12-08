(** [execute_request schema context request] executes the request [request] on the schema
    [schema] with the context [context].

    You most likely want to use [make_handler] instead of this, but if can be useful for
    unit tests. *)
val execute_request
  :  'a Graphql_lwt.Schema.schema
  -> 'a
  -> Rock.Request.t
  -> Rock.Response.t Lwt.t

(** [make_handler ?make_context] builds a [Rock] handler that serves a GraphQL API.

    [make_context] is the callback that will create the GraphQL context for each request
    and will be passed to resolvers. *)
val make_handler
  :  make_context:(Rock.Request.t -> 'a)
  -> 'a Graphql_lwt.Schema.schema
  -> Rock.Handler.t

(** [make_graphiql_handler ~graphql_endpoint] builds a [Rock] handler that serves an HTML
    page with the GraphiQL tool.

    The [graphql_endpoint] is the URI of the GraphQL API. For instance, if the API is at
    the root on the same server, [graphql_endpoint] is [/].

    The HTML content of the tool is served from the memory. An [ETag] header is added to
    the response. *)
val make_graphiql_handler : graphql_endpoint:string -> Rock.Handler.t
