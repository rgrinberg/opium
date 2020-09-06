(* This module is based on https://github.com/ulrikstrid/ocaml-cookie, with some API
   modification and the support for Signed cookies.

   BSD 3-Clause License

   Copyright (c) 2020, Ulrik Strid All rights reserved.

   Redistribution and use in source and binary forms, with or without modification, are
   permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of
   conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list
   of conditions and the following disclaimer in the documentation and/or other materials
   provided with the distribution.

   3. Neither the name of the copyright holder nor the names of its contributors may be
   used to endorse or promote products derived from this software without specific prior
   written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
   THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
   STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
   THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. *)

(** ??? *)

(** ??? *)
module Signer : sig
  type t

  (** {1 Constructors} *)

  (** {3 [make]} *)

  (** [make secret] returns a new signer that will sign values with [secret] *)
  val make : ?salt:string -> string -> t

  (** {1 Signing functions} *)

  (** {3 [sign]} *)

  (** [sign signer value] signs the string [value] with [signer] *)
  val sign : t -> string -> string

  (** {3 [unsign]} *)

  (** [unsign signer value] unsigns a signed string [value] with [signer] *)
  val unsign : t -> string -> string option
end

(** A single header represented as a key-value pair. *)
type header = string * string

(** [expires] describes when a cookie will expire.

    - [`Session] - nothing will be set
    - [`Max_age] - Max-Age will be set with the number
    - [`Date] - Expires will be set with a date *)
type expires =
  [ `Session
  | `Max_age of int64
  | `Date of Ptime.t
  ]

type same_site =
  [ `None
  | `Strict
  | `Lax
  ]

(** The [cookie] type is a tuple of [(name, value)] *)
type cookie = string * string

type t =
  { expires : expires
  ; scope : Uri.t
  ; same_site : same_site
  ; secure : bool
  ; http_only : bool
  ; value : string * string
  }

(** {1 Constructors} *)

(** {3 [make]} *)

(** [make] creates a cookie, it will default to the following values:

    - {!type:expires} - `Session
    - {!type:scope} - None
    - {!type:same_site} - `Lax
    - [secure] - false
    - [http_only] - true *)
val make
  :  ?expires:expires
  -> ?scope:Uri.t
  -> ?same_site:same_site
  -> ?secure:bool
  -> ?http_only:bool
  -> ?sign_with:Signer.t
  -> cookie
  -> t

(** {3 [of_set_cookie_header]} *)

(** ??? *)
val of_set_cookie_header : ?signed_with:Signer.t -> ?origin:string -> header -> t option

(** {3 [to_set_cookie_header]} *)

(** {1 Encoders} *)

(** {3 to_set_cookie_header} *)

(** ??? *)
val to_set_cookie_header : t -> header

(** {3 [to_cookie_header]} *)

(** ??? *)
val to_cookie_header : ?now:Ptime.t -> ?elapsed:int64 -> ?scope:Uri.t -> t list -> header

(** {1 Decoders} *)

(** {3 [cookie_of_header]} *)

(** ??? *)
val cookie_of_header : ?signed_with:Signer.t -> string -> header -> cookie option

(** {3 [cookies_of_header]} *)

(** ??? *)
val cookies_of_header : ?signed_with:Signer.t -> header -> cookie list

(** {3 [cookie_of_headers]} *)

(** ??? *)
val cookie_of_headers : ?signed_with:Signer.t -> string -> header list -> cookie option

(** {3 [cookies_of_headers]} *)

(** ??? *)
val cookies_of_headers : ?signed_with:Signer.t -> header list -> cookie list
