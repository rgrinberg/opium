# User Auth

```
dune exec example/user_auth/main.exe
```

This example implements a very simple authentication system using `Basic` authentication.

The middleware stores the authenticated user in the request's context, which can be retrieved in the handlers.
