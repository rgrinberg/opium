open Lwt.Syntax

module In = struct
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

  let of_list xs =
    let xs = ref xs in
    fun () ->
      match !xs with
      | [] -> Lwt.return_none
      | x :: xs' ->
        xs := xs';
        Lwt.return_some x
  ;;
end

module Out = struct
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

let connect input output =
  let rec loop () =
    let* item = In.read input in
    let* () = Out.write item output in
    match item with
    | None -> Lwt.return_unit
    | Some _ -> loop ()
  in
  loop ()
;;
