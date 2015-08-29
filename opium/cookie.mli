(** Simple cookie module.  Cookies are base64'd and percent encoded.
*)
(** Fetch all cookies from a rock request *)
val cookies : Opium_rock.Request.t -> (string * string) list
(** Get the follow of a cookie with a certain key *)
val get : Opium_rock.Request.t -> key:string -> string option
(** Set the value of a cookie with a certain key in a response *)
val set : Opium_rock.Response.t -> key:string -> data:string -> Opium_rock.Response.t
(** Like set but will do multiple cookies at once *)
val set_cookies : Opium_rock.Response.t -> (string * string) list -> Opium_rock.Response.t
(** Opium_rock middleware to add the the functionality above *)
val create_m : ?name:string -> ?expiration:Cohttp.Cookie.expiration -> unit -> Opium_rock.Middleware.t
(** Session cookie middleware *)
val m : Opium_rock.Middleware.t
(** 1-day persistent cookie middleware *)
val m_1d : Opium_rock.Middleware.t
(** 1-week persistent cookie middleware *)
val m_1w : Opium_rock.Middleware.t
(** 1-month persistent cookie middleware *)
val m_1m : Opium_rock.Middleware.t
(** 1-year persistent cookie middleware *)
val m_1y : Opium_rock.Middleware.t
