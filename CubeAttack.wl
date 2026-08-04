(* Definizione delle chiavi unitarie usate in CubeOffline *)
keysUnit = IdentityMatrix[16];

(* Versione da usare dentro i test ... *)
AsconNRound[key_,nonce_]:= Ascon129f [key, nonce, 1];

(* A partire da una lista di indici genera le varie combinazioni di grado dei maxterm *)
GenerateMaxterms[indexes_List, degree_] := Flatten[Map[Subsets[indexes,{#}]&, degree], 1]

(* Prende n elemnti a caso dalla mega lista di maxterm *)
RandomMaxterm[num_] := RandomSample[GenerateMaxterms[maxtermsIndexes,{4}], num]

(* Genera i cubi del nonce a partire da un maxterm specifico *)
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

(* Indicatore di "diversità" tra due matrici (parity check) *)
MatrixOr[a_List,b_List] := Mod[a+b + a*b,2]

(* Test di linearità per BLR *)
(* Nella matrice risultante 0 -> bit con superpolinomio lineare, 1 -> bit con superpolinomio non lineare *)
LinearityTest[key1_List,key2_List,nonce_List]:=
Mod[
Total[Map[AsconNRound [key1,#] &, nonce ]]+
Total[Map[AsconNRound [key2,#]  &, nonce ]]+
Total[Map[AsconNRound [ ConstantArray[0,Length[key]], #] &, nonce ]] +  (*alpha zero*)
Total[Map[ AsconNRound[Mod[key1 + key2,2],#] &, nonce]]       (*elemento di ugualianza*)
,2]

(* Genera una coppia di chiavi randomica usata nel BLR *)
RandomKeyPairs[keyBits_Integer, numPairs_Integer] := Table[ {RandomInteger[{0, 1}, keyBits], RandomInteger[{0, 1}, keyBits]}, {numPairs} ];

(* Test verifica linearità superpolinomio, parity check iterato più volte con stesso maxterm (Manuel Blum, Michael Luby e Ronitt Rubinfeld) *)
(* BLR[mt_] := Fold[
   MatrixOr, 
   LinearityTest[#1, #2, GenCombNonce[mt]] & @@@RandomKeyPairs[16,100]
]; *)

(* Applica il BLR su diversi maxterms *)
(* BLRAll[maxterms_] := BLR /@ maxterms
positionZeroLista = Map[Position[#, 0] &, BLRAll[maxterms]]; *)

(* Test verifica linearità superpolinomio, parity check iterato più volte con stesso maxterm (Manuel Blum, Michael Luby e Ronitt Rubinfeld) *)
(* restitusce una lista con le posizioni dei bit lineari *)
BLR[maxterms_List, numCoppie_Integer : 100] := Module[
   {blrSingoloMaxterm, risultatiBLRAll},

   (* 1. Esegue il test di linearità Blum-Luby-Rubinfeld su un singolo maxterm *)
   blrSingoloMaxterm[mt_] := Fold[
      MatrixOr,
      LinearityTest[#1, #2, GenCombNonce[mt]] & @@@ RandomKeyPairs[16, numCoppie]
   ];

   (* 2. Applica il test BLR su ciascun maxterm della lista *)
   risultatiBLRAll = Map[blrSingoloMaxterm, maxterms];

   (* 3. Estrae le posizioni degli elementi pari a zero per ogni matrice ottenuta, gli elementi con 0 sono lienari quelli con 1 non sono lineari*)
   Map[Position[#, 0] &, risultatiBLRAll]
]

(* Restituisce la matrice dei coefficienti del cube attack offline *)
CubeOffline[maxterms_List, positionZeroLista_List] := Module[
   {keysUnit, valutaVersoriPerNonce, valutazioniCubi},
 
   
   (* Base canonica di chiavi unitarie e1, e2, ... *)
   keysUnit = IdentityMatrix[Length[key]];
   
   (* 1. Funzione ausiliaria per valutare le righe di keysUnit su un dato cubo/nonce *)
   valutaVersoriPerNonce[nonce_List] := Module[{alpha0},
      alpha0 = Mod[Total[AsconNRound[ConstantArray[0, Length[key]], #] & /@ nonce], 2];
      Map[
         Function[k, Mod[Total[AsconNRound[k, #] & /@ nonce] + alpha0, 2]],
         keysUnit
      ]
   ];

   (* 2. Calcola la triade/matrice di valutazioni per ogni maxterm *)
   valutazioniCubi = Map[
      valutaVersoriPerNonce[GenCombNonce[#]] &, 
      maxterms
   ];

   (* 3. Estrazione parallela dei coefficienti sui vettori dei versori *)
   MapThread[
      Function[{triade, indici},
         Table[triade[[i, #1, #2]], {i, 1, Length[keysUnit]}] & @@@ indici
      ],
      {valutazioniCubi, positionZeroLista}
   ]
]

(* Calcola i termini noti associati a ciascina riga della matrice dei coefficenti ottenute con il CubeOfflne *)
CubeOnline[key_List, maxterms_List, positionZeroLista_List] := Module[
   {terminiNotiGrezzi, calcolaSingoloCube},
   
   (* Funzione ausiliaria per calcolare la matrice 5x8 del Cube per un dato insieme di nonce *)
   calcolaSingoloCube[nonce_List] := Mod[
      Total[Map[AsconNRound[key, #] &, nonce]] + 
      Total[Map[AsconNRound[ConstantArray[0, Length[key]], #] &, nonce]], 
      2
   ];

   (* 1. Genera la lista delle matrici 5x8 per ciascun maxterm *)
   terminiNotiGrezzi = Map[
      calcolaSingoloCube[GenCombNonce[#]] &, 
      maxterms
   ];

   (* 2. Estrae in parallelo i termini noti corrispondenti alle posizioni zero *)
   MapThread[
      Function[{matriceTN, indici},
         matriceTN[[#1, #2]] & @@@ indici
      ],
      {terminiNotiGrezzi, positionZeroLista}
   ]
]
