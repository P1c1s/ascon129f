
Get["ascon-definition.wl"];


(*  GENERA IL CUBO di un maxterm  *)
GenCombNonce[maxterm_List] := Module[{d, zv},
  d = Length[maxterm];
  zv = Table[0, Length[nonce]];
  
  Map[
    Module[{ztmp = zv},
      ztmp[[maxterm]] = IntegerDigits[#, 2, d];
      ztmp
    ] &, 
    Range[0, 2^d - 1]
  ]
]

(* Operotore "Somma" dei test *)
MatrixOr[a_List,b_List] := Mod[a+b + a*b,2]

(* Test di linearità per BLR *)
LinearityTest[key1_List,key2_List,nonce_List]:=
Mod[
Total[Map[AsconNRound [key1,#] &, nonce ]]+
Total[Map[AsconNRound [key2,#]  &, nonce ]]+
Total[Map[AsconNRound [ ConstantArray[0,Length[key]], #] &, nonce ]] +  (*alpha zero*)
Total[Map[ AsconNRound[Mod[key1 + key2,2],#] &, nonce]]       (*elelmento di ugualianza*)
,2];


(* Prodotto cartesiano chiavi random *)
KeyPairAll = Permutations[Rest @ Tuples[{0, 1}, #1], {#2}] &;

RandomKeyPairs[keyBits_Integer, numPairs_Integer] := Table[ {RandomInteger[{0, 1}, keyBits], RandomInteger[{0, 1}, keyBits]}, {numPairs} ];


(* Deve dare esito positivo il 90% dei casi date due chiavi random, Manuel Blum, Michael Luby e Ronitt Rubinfeld *)

Npairs = 1000;
BLR[mt_] := Fold[
   MatrixOr, 
   LinearityTest[#1, #2, GenCombNonce[mt]] & @@@RandomKeyPairs[16,Npairs];
];




(**)
GeneraTriade[keys_,nonce_] := Module[{alpha0},
   (* Matrice 3x3 per la chiave nulla *)
   alpha0 = Mod[Total[AsconNRound[ConstantArray[0,Length[key]],#] & /@ nonce], 2];

   (*Calcolo per ciascuna chiave *)
   Map[
      Function[k, Mod[Total[AsconNRound[k,#] & /@ nonce] + alpha0, 2]], 
      keys
   ]
]

(* A partire da una lista di indici genera le varie combinazioni di grado dei maxterm *)
GenerateMaxterms[indexes_List, degree_] := Flatten[Map[Subsets[indexes,{#}]&, degree], 1]

(* Prende n elemnti a caso dalla mega lista di maxterm *)
RandomMaxterm[num_]:= RandomSample[GenerateMaxterms[maxtermsIndexes,{1,2,3}], num]


(* CI SERVIRA' PER AUTOMATIZZARE IL TUTTO*)
(*maxterms={{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14},{15},{16}};*)

maxtermsIndexes = Range[Length[nonce]];

(*maxterms = GenerateMaxterms[maxtermsIndexes,{1,2}]*)

maxterms={{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14},{15},{16}};

maxterms = RandomMaxterm[20]

(* Applica a tutta la lista di maxterm *)
risultati = BLR /@ maxterms;
positionZeroLista = Map[Position[#, 0] &, risultati];

(*Definizione delle chiavi unitarie per la triade*)
keysUnit = IdentityMatrix[16];

(*Lista elementi [S(v#,k1),S(v#,k2),S(v#,k3)] iterando i maxterm*)
(*TriadiLista = Map[keysUnit, GeneraTriade[GenCombNonce[#]] &, maxterms]; *)
TriadiLista = GeneraTriade[keysUnit, GenCombNonce[#]] & /@ maxterms;

(* Applicazione con MapThread su tutte le triadi e le relative liste di indici *)
matriceCoeffLista = MapThread[
   Function[{triade, indici},
      (* triade[[1]] è m1, triade[[2]] è m2, triade[[3]] è m3 *)
      (*{triade[[1, #1, #2]], triade[[2, #1, #2]], triade[[3, #1, #2]]} & @@@ indici*)
      Table[triade[[i, #1, #2]], {i, 1, 16}] & @@@ indici
   ],
   {TriadiLista, positionZeroLista}
];

CUBEONLINE[key_List, nonce_List] := Mod[Total[Map[AsconNRound[key, #] &, nonce]]+Total[Map[AsconNRound[ConstantArray[0,Length[key]], #] &, nonce ]],2]


(* Genera una lista di matrici 5*8 dei termini noti, una per ogni maxterm *)
terminiNotiLista = Map[
   CUBEONLINE[key, GenCombNonce[#]] &, 
   maxterms
];

(* Estrazione parallela degli elementi specificati dalle coordinate di ciascuna matrice *)
terminiNotiLista = MapThread[
   Function[{matriceTN, indici},
      matriceTN[[#1, #2]] & @@@ indici
   ],
   {terminiNotiLista, positionZeroLista}
];

(* Print["SISTEMA FINALE"] *)
MC=Flatten[matriceCoeffLista,1];
TN=Flatten[terminiNotiLista,1];


(* 1. Crea la matrice aumentata [M | N] *)
aug = Join[MC, Partition[TN, 1], 2];

(* 2. Riduzione modulo 2 ed eliminazione delle righe nulle *)
rref = DeleteCases[RowReduce[aug, Modulus -> 2], {0 ..}];

(* 3. Estrazione delle nuove M e N ridotte *)
MCridotta = rref[[All, 1 ;; Last[Dimensions[MC]]]];
TNridotta = rref[[All, -1]];

Print[MatrixForm[MCridotta] ," x ", MatrixForm[keys]," = ", MatrixForm[TNridotta]]



Print["Bit della chiave:         ", key]
(* Print["Bit della chiave trovata: ", LinearSolve[MC, TN, Modulus->2]] *)
Print["Bit della chiave trovata: ", LinearSolve[MCridotta, TNridotta, Modulus->2]]










