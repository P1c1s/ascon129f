Get["/home/lorenzo/Documenti/GitHubProjects/ascon129f/vars.wl"]
Get["/home/lorenzo/Documenti/GitHubProjects/ascon129f/Ascon.wl"]

plaintext = "Testo di prova";

cyphertext = AsconEncrypt[plaintext, key, nonce];
msgDecifrato = AsconDecrypt[testoCifrato, key, nonce];

Print["Il testo in chiaro e': ", plaintext]
Print["Il testo cifrato e': ", BitsToHex[cyphertext]]
Print["Il testo decifrato e': ", BitsToString[msgDecifrato]]

BitsToHexDigits[bits_List] := StringJoin[ToUpperCase[IntegerString[FromDigits[#, 2], 16, 2]] & /@ bits]