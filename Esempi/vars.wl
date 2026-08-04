(* Definizione delle variabili*)
iv = IntegerDigits[FromDigits["BA", 16], 2, 8];       (* 8 bit  -> x0 *)
key = IntegerDigits[FromDigits["AAAA", 16], 2, 16];    (* 16 bit -> x1, x2 *)
nonce = IntegerDigits[FromDigits["FFFF", 16], 2, 16];  (* 16 bit -> x3, x4 *)