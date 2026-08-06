(* Definizione dell'Input per ottenere 5 parole da 8 bit ciascuna *)
iv = IntegerDigits[FromDigits["BA", 16], 2, 8];       (* 8 bit  -> x0 *)
key = IntegerDigits[FromDigits["AAAA", 16], 2, 16];    (* 16 bit -> x1, x2 *)
nonce = IntegerDigits[FromDigits["FFFF", 16], 2, 16];  (* 16 bit -> x3, x4 *)
ivs={v1,v2,v3,v4,v5,v6,v7,v8};
keys={k1,k2,k3,k4,k5,k6,k7,k8,k9,k10,k11,k12,k13,k14,k15,k16};
nonces={n1,n2,n3,n4,n5,n6,n7,n8,n9,n10,n11,n12,n13,n14,n15,n16};

(* Matrice 5x8: Join produce 40 bit, Partition crea 5 liste da 8 bit *)
Struct[key_,nonce_]:= Partition[Join[iv, key, nonce], 8]

(* Costanti di Round a 8 bit per i 12 round *)
roundConstants = IntegerDigits[#, 2, 8] & /@ {
   16^^F0, 16^^E1, 16^^D2, 16^^C3, 16^^B4, 16^^A5, 
   16^^96, 16^^87, 16^^78, 16^^69, 16^^5A, 16^^4B
};

(* Layer 1: Addition of Round Constant *)
addRoundConstant[stato_List, n_Integer] := ReplacePart[stato, 3 -> PolynomialMod[stato[[3]] + roundConstants[[n]], 2]];

(* Layer 2: Substitution Layer (S-box 5-bit verticalmente su 8 colonne) *)
substitutionLayer[stato_] := Module[
  {x1, x2, x3, x4, x5, trasposta, nuovaTrasposta},
  {x1, x2, x3, x4, x5} = stato;
  
  (* Trasponiamo per trattare ogni colonna di 5 bit *)
  trasposta = Transpose[{x1, x2, x3, x4, x5}];
  
  nuovaTrasposta = Map[Function[col,
     Module[{b1 = col[[1]], b2 = col[[2]], b3 = col[[3]], b4 = col[[4]], b5 = col[[5]]},
      {
        PolynomialMod[b5*b2 + b4 + b2*b3 + b3 + b1*b2 + b2 + b1, 2],
        PolynomialMod[b5 + b3*b4 + b2*b4 + b4 + b2*b3 + b2 + b3 + b1, 2],
        PolynomialMod[b4*b5 + b5 + b3 + b2 + 1, 2],
        PolynomialMod[b1*b5 + b5 + b1*b4 + b4 + b3 + b2 + b1, 2],
        PolynomialMod[b2*b5 + b5 + b4 + b1*b2 + b2, 2]
      }
     ]
    ], trasposta];
    
  Transpose[nuovaTrasposta]
];

(* Layer 3: Linear Diffusion Layer (Rotazioni su parole da 8 bit) *)
linearDiffusionLayer[stato_] := Module[
  {x1, x2, x3, x4, x5},
  {x1, x2, x3, x4, x5} = stato;
  x1 = PolynomialMod[x1 + RotateRight[x1, 3], 2];
  x2 = PolynomialMod[x2 + RotateRight[x2, 1] + RotateRight[x2, 3], 2];
  x3 = PolynomialMod[x3 + RotateRight[x3, 1] + RotateRight[x3, 2], 2];
  x4 = PolynomialMod[x4 + RotateRight[x4, 2] + RotateRight[x4, 1], 2];
  x5 = PolynomialMod[x5 + RotateRight[x5, 3] + RotateRight[x5, 1], 2];
  {x1, x2, x3, x4, x5}
];

(* Permutazione del singolo Round n *)
AsconRound[state_List, nRound_Integer]:=linearDiffusionLayer[substitutionLayer[addRoundConstant[state, nRound]]];

(* --- 3. ESECUZIONE DELL'INTERA PERMUTAZIONE A 12 ROUND --- *)
Ascon129f[key_,nonce_, rounds_]:=Fold[AsconRound[#1, #2] &, Struct[key,nonce], Range[rounds]];
(*ATTACCO*)

(* Versione da usare dentro i test ... *)
AsconNRound[key_,nonce_]:=Ascon129f [key, nonce, rounds ];
