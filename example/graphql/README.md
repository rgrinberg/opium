# GraphQL

```
dune exec example/graphql/main.exe
```

This example implements a simple GraphQL API with Opium. It uses `opium-graphql` to interface with `ocaml-graphql-server`.

The example provides two endpoints:

- `/` that serves the actual GraphQL API
- `/graphiql` that serves the GraphiQL tool

To test the API, you can go on the GraphiQL tool and run the following query:

```graphql
query {
  users {
    name
  }
}
```
