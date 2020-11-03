# File Upload Example

```
dune exec example/file_upload/main.exe
```

This is an example of a simple file upload.

The server offers two endpoints:

- `/` to serve an HTML page with a form and an upload button
- `/upload` that receives `multipart/form-data` `POST` requests and writes the content of uploaded files on the disk.

You'll see that the `layout` and `index_view` functions are quite verbose. That's because we're using TailwindCSS and AlpineJS to create a nice UX, but that's got nothing to do with how file upload works. If you'd prefer to have a bare-bone file upload, check out the `simple.ml` file!

The implementation of the `upload_handler` function is borrowed from [ReWeb](https://github.com/yawaramin/re-web/blob/main/ReWeb/Filter.ml#L237).
