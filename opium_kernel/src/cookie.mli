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

(** Cookie management for both requests and responses. *)

(** Sign an unsign cookies with secret.

    Beware that signing a cookie is not the same as encrypting it! The value of a signed
    cookie is still visible to anyone, so don't store any sensitive information in it.

    When signing a cookie, a hash of its value is generated using the Signer's secret. The
    generated string is appended to the Cookie's value. So, for instance, if you have a
    Cookie [key=value], the signed cookie will look like [key=value.xRt15vh].

    When reading the cookie value, the hash will be regenerated again and compared with
    the sent value. If the values are not the same, the cookie has been tempered with, and
    we discard it. *)
module Signer : sig
  type t

  (** {1 Constructors} *)

  (** {3 [make]} *)

  (** [make ?salt secret] returns a new signer that will sign values with [secret] *)
  val make : ?salt:string -> string -> t

  (** {1 Signing functions} *)

  (** {3 [sign]} *)

  (** [sign signer value] signs the string [value] with [signer] *)
  val sign : t -> string -> string

  (** {3 [unsign]} *)

  (** [unsign signer value] unsigns a signed string [value] with [signer].Httpaf

      To avoid time attacks, this function is constant time, it will iterate through all
      the characters of [value], even if it is not the same. *)
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

(** The value of a cookie is a tuple of [(name, value)] *)
type value = string * string

type t =
  { expires : expires
  ; scope : Uri.t
  ; same_site : same_site
  ; secure : bool
  ; http_only : bool
  ; value : value
  }

(** {1 Constructors} *)

(** {3 [make]} *)

(** [make cookie] creates a cookie with the key-value pair [cookie]

    It will default to the following values:

    - {!type:expires} - `Session
    - {!type:scope} - None
    - {!type:same_site} - `Lax
    - [secure] - false
    - [http_only] - false

    Note that if no value is given for [scope], the browsers might use a default value.
    For instance, if the cookie is set from the response of
    [http://example.com/users/login] and does not specify a scope, some browsers will use
    [/users] as a scope. If you want the cookie to be valid for every endpoint of your
    application, you need to use ["/"] as the scope of your cookie. *)
val make
  :  ?expires:expires
  -> ?scope:Uri.t
  -> ?same_site:same_site
  -> ?secure:bool
  -> ?http_only:bool
  -> ?sign_with:Signer.t
  -> value
  -> t

(** {3 [of_set_cookie_header]} *)

(** [of_set_cookie_header ?signed_with ?origin header] creates a cookie from a
    [Set-Cookie] header [header].

    If the header is not a valid [Set-Cookie] header, [None] is returned. *)
val of_set_cookie_header : ?signed_with:Signer.t -> ?origin:string -> header -> t option

(** {3 [to_set_cookie_header]} *)

(** {1 Encoders} *)

(** {3 to_set_cookie_header} *)

(** [to_set_cookie_header t] creates an HTTP header for the cookie [t]. *)
val to_set_cookie_header : t -> header

(** {3 [to_cookie_header]} *)

(** [to_cookie_header ?now ?elapsed ?scope cookies] creates an HTTP header for the list of
    cookies [cookies]. *)
val to_cookie_header : ?now:Ptime.t -> ?elapsed:int64 -> ?scope:Uri.t -> t list -> header

(** {1 Decoders} *)

(** {3 [cookie_of_header]} *)

(** [cookie_of_header ?signed_with key header] returns the value of a the cookie with the
    key [key] in the header [header].

    If the cookie with the key [key] does not exist, or if the header is not a valid
    [Cookie] header, [None] will be returned. *)
val cookie_of_header : ?signed_with:Signer.t -> string -> header -> value option

(** {3 [cookies_of_header]} *)

(** [cookies_of_header ?signed_with header] returns the list of cookie values in the
    header [header].

    If the header is not a valid [Cookie] header, an empty list is returned. *)
val cookies_of_header : ?signed_with:Signer.t -> header -> value list

(** {3 [cookie_of_headers]} *)

(** [cookie_of_headers ?signed_with key headers] returns the value of a the cookie with
    the key [key] in the headers [headers].

    If the cookie with the key [key] does not exist, or if no header is not a valid
    [Cookie] header, [None] will be returned. *)
val cookie_of_headers : ?signed_with:Signer.t -> string -> header list -> value option

(** {3 [cookies_of_headers]} *)

(** [cookies_of_headers ?signed_with headers] returns the list of cookie values in the
    headers [headers].

    If no header is not a valid [Cookie] header, an empty list is returned. *)
val cookies_of_headers : ?signed_with:Signer.t -> header list -> value list

(** {1 Utilities} *)

(** {3 [sexp_of_t]} *)

(** [sexp_of_t t] converts the cookie [t] to an s-expression. *)
val sexp_of_t : t -> Sexplib0.Sexp.t

(** {3 [pp]} *)

(** [pp] formats the cookie [t] as an s-expression. *)
val pp : Format.formatter -> t -> unit
  [@@ocaml.toplevel_printer]
