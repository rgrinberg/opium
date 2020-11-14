open Lwt.Syntax

module Input = struct
  type 'a t = unit -> 'a option Lwt.t

  let create f = f
  let read f = f ()

  let rec iter f t =
    let* res = read t in
    match res with
    | None -> Lwt.return_unit
    | Some item ->
      let* () = f item in
      iter f t
  ;;

  let singleton item =
    let finished = ref false in
    fun () ->
      if !finished
      then Lwt.return_none
      else (
        finished := true;
        Lwt.return (Some item))
  ;;
end

module Output = struct
  type 'a t = 'a option -> unit Lwt.t

  let create f =
    let closed = ref false in
    fun v ->
      if !closed
      then Lwt.return_unit
      else (
        match v with
        | None ->
          closed := true;
          f None
        | v -> f v)
  ;;

  let write i f = f i
end

let transfer input output =
  let rec loop () =
    let* item = Input.read input in
    let* () = Output.write item output in
    match item with
    | None -> Lwt.return_unit
    | Some _ -> loop ()
  in
  loop ()
;;
