Seleziona[i_, BLR_List, MC_List, TN_List] := 

  Module[{posizioniZero, coeff, term},
    coeff = Flatten[MC, 1];
    term = Flatten[TN];
    posizioniZero = Flatten[Position[BLR, 0]];
    {coeff[posizioniZero], TN[posizioniZero]}
  ]

Test[tripla_]:= tripla[[1]]==0

Seleziona[i_, BLR_List, MC_List, TN_List] :=
    Module[{data},
    data = {Flatten[BLR], Flatten[MC, 1], Flatten[TN]};

    Select[data, Test]
    ]

MakeSistema[mt_] := Seleziona@@{i, BLR, MC, TN}



--VERSIONE MIGLIORATA--

(* Struttura dati
BLR = {{0, 1, 0, 1}, {}, {}}
MC = {{{1, {0,1,0,0}}, {0, {1,1,0,0,}}, {}}}
TN =  {{0,1,0,0}, {0,0,0,0}, {}}*)


Seleziona[i_, BLR_List, MC_List, TN_List] :=
    Module[{terne, blr, mc,  tn}, 

        blr = Flatten[BLR];
        mc = Flatten[MC, 1];
        tn = Flatten[TN];

        terne = Table[
            Module[{mcNuovo, tnNuovo}, 
                mcNuovo = mc[[i, 2]];
                tnNuovo = mc[[i, 1]] + tn[[i]];

            {blr[[i]], mcNuovo, tnNuovo}
            ],
            {i, 1, Length[BLR]}
        ];
        Select[terne, Test]
    ]


MakeSistema[mt_] := Seleziona @@ {i, BLR, MC, TN}