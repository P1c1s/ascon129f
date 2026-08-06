
(** run on Mac with /Applications/Wolfram.app/Contents/MacOS/MathKernel -run "Npairs=100;rounds=3;nCandidates=20;<< ascon-attack-prof.wl"   **)

(** on linux with math -run "Npairs=100;rounds=3;nCandidates=20;<< ascon-attack-prof.wl"   **)

Get["ascon-definition.wl"];


(* A partire da una lista di indici genera le varie combinazioni di grado dei maxterm *)
GenerateMaxterms[indexes_List, degree_] := Flatten[Map[Subsets[indexes,{#}]&, degree], 1];
RandomKeyPairs[keyBits_Integer, numPairs_Integer] := Table[ {RandomInteger[{0, 1}, keyBits], RandomInteger[{0, 1}, keyBits]}, {numPairs} ];


maxtermsIndexes = Range[Length[nonce]];

(* Prende n elemnti a caso dalla mega lista di maxterm *)
RandomMaxterm[num_]:= RandomSample[GenerateMaxterms[maxtermsIndexes,degrees], num];

maxterms = RandomMaxterm[nCandidates];

KeyUnits = IdentityMatrix[16];
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
];

(* Nuova Funzione CubeOnline*)
CubeOnline[mt_] := Mod[Total[Map[AsconNRound[key, #]&, GenCombNonce[mt]]], 2];


LinearityTest[key1_List,key2_List,nonce_List]:=
    Mod[
        Total[Map[AsconNRound[key1,#] &, nonce ]]+
        Total[Map[AsconNRound[key2,#] &, nonce ]]+
        Total[Map[AsconNRound[ ConstantArray[0,Length[key]], #] &, nonce ]] +  (*alpha zero*)
        Total[Map[AsconNRound[Mod[key1 + key2,2],#] &, nonce]]       (*elemento di ugualianza*)
    ,2];

(* Operotore "Somma" dei test *)
MatrixOr[a_List,b_List] := Mod[a+b + a*b,2];

BLR[mt_] := Fold[
   MatrixOr,
   LinearityTest[#1, #2, GenCombNonce[mt]] & @@@RandomKeyPairs[16,Npairs]
];

MakeCube[indexes_List]:=GenCombNonce[indexes];
Alpha0[termindexes_]:=Mod[Plus@@Map[AsconNRound[Array[0&,16],#]&,MakeCube[termindexes]],2] ;


Alpha[termindexes_][kindex_]:=Mod[Plus@@Map[AsconNRound[KeyUnits[[kindex]],#]&,MakeCube[termindexes]]  ,2]

LinearityTest[mt_]:=Apply[Times,Flatten@BLR[mt]];

NonZeroTest[triple_]:=Module[{ft},
                        ( 
                            ft=Flatten[triple[[2]],1];
                            (* seleziona i supepoly che superano il test di linearità e non sono costanti *)

                            Select[ft,(#[[1]]==0)&&(Plus@@#[[3]]>0)&]
                        )];

(** Mantieni solo i termini con superpolinomio lineare-affine **)

candidates=Select[maxterms, LinearityTest[#] == 0 &];



(*
termindexes = candidates[[3]];
triple={termindexes,Transpose[{BLR[termindexes],Alpha0[termindexes],Transpose[Map[Alpha[termindexes],Range[1,16]],2]},2]};
If[NonZeroTest[triple]=={},Print["No non-zero found"];{},triple ]
*)

(**. itera per tutti i termini candidati: quelli in cui almeno un bit supera il test di linearità**)


presistema=ParallelMap[
    (
        termindexes = #;
        triple={BLR[termindexes],Alpha0[termindexes],Transpose[Map[Alpha[termindexes],Range[1,16]],{3,1,2}]};
        newtriple={termindexes,Transpose[triple,{3,1,2}]};

        (** mantieni solo i termini con superpolinomio non costante **)
        If[NonZeroTest[newtriple]=={},Print["No non-zero found"];{},newtriple ]
    )&, candidates];

  Print["Pre-sistema: ", presistema];

(** AGGIUNGI QUI, a presistema per ogni elemento (la tripla associata a un candidato ad essere maxterm) LA MATRICE DEI Termini NOTI **)
(** ATTENZIONE : presistema contiene le triple per tutti i termini candidati quindi inizialmente ragiona su una sola tripletta **)

(** crea la funzione che aggiunge la matrice dei termini noti a presistema[[1]] e poi fai la Map **)

(** TBC... **)
TN = CubeOnline[{1,2}] ;


(**  qui sotto non dovresti cambiare nulla se non risolvere il sistema **)

  (* GetSistema[tripla_]:=Select[If[tripla=={},{},Join@@(tripla[[2]])],#[[1]]==0&&Plus@@#[[3]]>0&]; *)


  GetSistema[tripla_] := If[tripla == {} || Length[tripla] < 2, 
                Return[{}],
                (
                    pair={tripla[[2]],CubeOnline[tripla[[1]]]};
                    matrice=Transpose[pair,2];
                    Select[Join @@ (matrice), #[[1,1]] == 0 && Plus @@ #[[1,3]] > 0 &]



                )];


  sistema=Join@@Map[GetSistema, presistema];
  Print["Sistema: ", sistema, "\n con ", Length[sistema], " equazioni, di rango ", MatrixRank[Map[Last[#[[1]]]&,sistema],Modulus->2]  ];


RiduciSistema[MC_, TN_] := Module[{aug, rref, MCridotta, TNridotta},
  (* 1. Matrice aumentata [M | N] *)
  aug = Join[MC, Partition[TN, 1], 2];
  
  (* 2. Riduzione modulo 2 ed eliminazione righe nulle *)
  rref = DeleteCases[RowReduce[aug, Modulus -> 2], {0 ..}];
  
  (* 3. Estrazione M e N ridotte *)
  MCridotta = rref[[All, 1 ;; Last[Dimensions[MC]]]];
  TNridotta = rref[[All, -1]];
  
  {MCridotta, TNridotta}
]

BruteForce[MCridotta_, TNridotta_] := Module[
  {solParticolare, ker, combinazioniCoeff, tutteLeSoluzioni},

  (* 1. Trova una soluzione particolare *)
  solParticolare = LinearSolve[MCridotta, TNridotta, Modulus -> 2];

  (* 2. Trova la base dello spazio nullo (parametri liberi) *)
  ker = NullSpace[MCridotta, Modulus -> 2];

  (* 3. Genera tutti i possibili coefficienti binari {0, 1} per i vettori di base *)
  combinazioniCoeff = Tuples[{0, 1}, Length[ker]];

  (* 4. Genera l'insieme di tutte le soluzioni *)
  tutteLeSoluzioni = Mod[
    Table[solParticolare + c . ker, {c, combinazioniCoeff}],
    2
  ];

  (* Stampa dei risultati *)
  Print["Numero di soluzioni trovate: ", Length[tutteLeSoluzioni]];
  Print["Tutte le chiavi possibili:"];
  Print[MatrixForm[tutteLeSoluzioni]];

  (* Restituisce la lista delle soluzioni *)
  tutteLeSoluzioni
]



{MC,TN}=Transpose[Map[{#[[1,3]],Mod[#[[1,2]]+#[[2]],2]}&, sistema]]

{MCridotta, TNridotta} = RiduciSistema[MC, TN];

soluzioni = BruteForce[MCridotta, TNridotta];