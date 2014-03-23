(** See App_intf for documentation *)
module Make (R : App_intf.Router) : App_intf.S
include App_intf.S
