# Simple Middleware

```
dune exec example/exit_hook/main.exe
```

This example shows how to implement a simple middleware. It implements an `Reject UA` middleware that rejects request if the User-Agent contains `"MSIE"`.
