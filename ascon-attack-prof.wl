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

LinearityTest[key1_List,key2_List,nonce_List]:=
    Mod[
        Total[Map[AsconNRound[key1,#] &, nonce ]]+
        Total[Map[AsconNRound[key2,#] &, nonce ]]+
        Total[Map[AsconNRound[ ConstantArray[0,Length[key]], #] &, nonce ]] +  (*alpha zero*)
        Total[Map[AsconNRound[Mod[key1 + key2,2],#] &, nonce]]       (*elelmento di ugualianza*)
    ,2];

BLR[mt_] := Fold[
   MatrixOr, 
   LinearityTest[#1, #2, GenCombNonce[mt]] & @@@RandomKeyPairs[16,Npairs];
];
MakeCube[indexes_List]:=GenCombNonce[indexes];
Alpha0[termindexes_]:=Mod[Plus@@Map[AsconNRound[Array[0&,16],#]&,MakeCube[termindexes]],2] ;
Alpha[termindexes_][kindex_]:=Mod[Plus@@Map[AsconNRound[KeyUnits[[kindex]],#]&,MakeCube[termindexes]]+Alpha0[termindexes]  ,2]

LinearityTest[mt_]:=Apply[Times,Flatten@BLR[mt]];

NonZeroTest[triple_]:=Module[{ft},
                        ( 
                            ft=Flatten[triple[[2]],1];
                            (* seleziona i supepoly che superano il test di linearità e non sono costanti *)

                            Select[ft,(#[[1]]==0)&&(Plus@@#[[3]]>0)&]
                        )];

candidates=Select[maxterms, LinearityTest[#] == 0 &]

termindexes = candidates[[3]];
triple={termindexes,Transpose[{BLR[termindexes],Alpha0[termindexes],Transpose[Map[Alpha[termindexes],Range[1,16]],2]},2]};
If[NonZeroTest[triple]=={},Print["No non-zero found"];{},triple ]

pre-sistema=Map[
    (
        termindexes = #;
        triple={termindexes,
                Transpose[{BLR[termindexes],Alpha0[termindexes],Transpose[Map[Alpha[termindexes],Range[1,16]],2]},2]};

        If[NonZeroTest[triple]=={},Print["No non-zero found"];{},triple ]
    )&, candidates]