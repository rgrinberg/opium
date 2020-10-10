# HTML Response

```
dune exec example/html_response/main.exe
```

This example shows how to serve HTML content.

The `View` module contains `Tyxml` code with the following functions:

- `layout ~title body`
  Build an HTML document with the title `title` and the body `body`

- `check_icon`
  SVG element for a check icon

- `index`
  HTML document with the content of our page
