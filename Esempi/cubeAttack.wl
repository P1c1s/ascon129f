Get["/home/lorenzo/Documenti/GitHubProjects/ascon129f/Librerie/CubeAttack.wl"]

(* maxterms={{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{15},{16}}; *)

nRound = 3; (* Round da eseguire *)
gradiMaxterm = {4}; (* Lista gradi maxterm *)
nMaxterm = 15; (* Numero di maxterm da testare *)

maxterms = RandomMaxterms[nMaxterm, gradiMaxterm];
positionZeroLista = BLR[maxterms, nRound];

MatriceCoefficenti = Flatten[CubeOffline[maxterms, positionZeroLista, nRound], 1];

VettoreColonnaTerminiNoti = Flatten[CubeOnline[key, maxterms, positionZeroLista, nRound],1];

{MCridotta, TNridotta} = RiduciSistema[MatriceCoefficenti, VettoreColonnaTerminiNoti];

Print[MatrixForm[MCridotta] ," x ", MatrixForm[keys]," = ", MatrixForm[TNridotta]]

Print["Bit della chiave:         ", key]

(* Chiamata della funzione *)
soluzioni = BruteForce[MCridotta, TNridotta];
