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
  x1 = PolynomialMod[x1 + RotateRight[x1, 3] + RotateRight[x1, 4], 2];
  x2 = PolynomialMod[x2 + RotateRight[x2, 5] + RotateRight[x2, 7], 2];
  x3 = PolynomialMod[x3 + RotateRight[x3, 1] + RotateRight[x3, 6], 2];
  x4 = PolynomialMod[x4 + RotateRight[x4, 2] + RotateRight[x4, 1], 2];
  x5 = PolynomialMod[x5 + RotateRight[x5, 7] + RotateRight[x5, 1], 2];
  {x1, x2, x3, x4, x5}
];

(* Permutazione del singolo Round n *)
AsconRound[state_List, nRound_Integer]:=linearDiffusionLayer[substitutionLayer[addRoundConstant[state, nRound]]];

(* --- 3. ESECUZIONE DELL'INTERA PERMUTAZIONE A 12 ROUND --- *)
Ascon129f[key_,nonce_, rounds_]:=Fold[AsconRound[#1, #2] &, Struct[key,nonce], Range[rounds]];

(* Converte una stringa di testo in una lista di liste di bit a 8-bit per carattere *)
StringToBits[text_String] := IntegerDigits[ToCharacterCode[text],2,8];

(* Converte una lista di liste di bit a 8-bit per carattere in una stringa *)
BitsToString[bits_List] := FromCharacterCode[FromDigits[#, 2] & /@ bits];

(* Converte un  umero in bianrio in esadecimale *)
BitsToHex[bits_List] := IntegerDigits[FromDigits[bits, 2], 16]

(* Sovraccarico: se riceve una Stringa, la converte in bit e richiama se stessa *)
AsconEncrypt[messaggio_String, key_, nonce_] := 
  AsconEncrypt[StringToBits[messaggio], key, nonce];

(* Cifra *)
AsconEncrypt[messaggio_List, key_, nonce_] := Module[{statoIniziale, passoCifratura, statiRisultato},
  statoIniziale = Ascon129f[key, nonce, 12];
  
  (* Trasformazione funzionale pura per singolo blocco *)
  passoCifratura[{stato_, _}, mBlock_] := Module[{cBlock, nuovoStato},
    cBlock = PolynomialMod[mBlock + stato[[1]], 2];
    nuovoStato = Fold[AsconRound[#1, #2] &, ReplacePart[stato, 1 -> cBlock], Range[6]];
    {nuovoStato, cBlock}
  ];
  
  (* FoldList accumula gli stati passo dopo passo senza cicli Do o AppendTo *)
  statiRisultato = FoldList[passoCifratura, {statoIniziale, None}, messaggio];
  
  (* Estrae solo i blocchi cifrati (escludendo l'elemento iniziale None) *)
  Rest[statiRisultato][[All, 2]]
];

(* Decifra *)
AsconDecrypt[cifrato_List, key_, nonce_] := Module[{statoIniziale, passoDecifratura, statiRisultato},
  statoIniziale = Ascon129f[key, nonce, 12];
  
  (* Trasformazione funzionale pura per singolo blocco *)
  passoDecifratura[{stato_, _}, cBlock_] := Module[{mBlock, nuovoStato},
    mBlock = PolynomialMod[cBlock + stato[[1]], 2];
    nuovoStato = Fold[AsconRound[#1, #2] &, ReplacePart[stato, 1 -> cBlock], Range[6]];
    {nuovoStato, mBlock}
  ];
  
  (* Applicazione sequenziale pura *)
  statiRisultato = FoldList[passoDecifratura, {statoIniziale, None}, cifrato];
  
  (* Estrae i blocchi decifrati *)
  Rest[statiRisultato][[All, 2]]
];