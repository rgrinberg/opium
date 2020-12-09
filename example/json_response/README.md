# JSON Response Example

```
dune exec example/json_response/main.exe
```

This is an example of a JSON response.

The server offers an endpoint `/` that serves a single JSON object.
The JSON object is internally represented using `Yojson.Safe.t`,
and populated with values from the `Sys` module.
The function `Response.of_json` is used to serialize the JSON object and sets the correct content-type.

Read more about [yojson](https://github.com/ocaml-community/yojson) at their homepage.
