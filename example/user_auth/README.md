# User Auth

```
dune exec example/user_auth/main.exe
```

This example implements a very simple authentication system using `Basic` authentication.

The middleware stores the authenticated user in the request's context, which can be retrieved in the handlers.

The username and password for the authentication are `admin` and `admin`.
The corresponding `Basic` header is `Basic YWRtaW46YWRtaW4=`.

You can test that you are unauthorized to access the `/` endpoint without the correct authorization header:

```sh
curl http://localhost:3000/ -X GET
```

And that you are allows to access when you provide it:

```sh
curl http://localhost:3000/ -X GET --user admin:admin
```
