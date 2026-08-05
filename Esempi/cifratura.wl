Get["Esempi/vars.wl"]
Get["Librerie/Ascon.wl"]

plaintext = "Testo di prova";
bitCifrati = AsconEncrypt[plaintext, key, nonce];
bitDecifrati = AsconDecrypt[bitCifrati, key, nonce];

Print["Il testo in chiaro e': ", plaintext];
Print["I bit cifrati sono: ", bitCifrati];
(*Print["Cyphertext: ", BitsToString[bitCifrati]];*)
Print["Il testo decifrato e': ", BitsToString[bitDecifrati]];