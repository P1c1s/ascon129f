# ASCON 129f

 Modello Ridotto per il Cube Attack Numerico

Ascon-129f è una variante "giocattolo" (didattica) della suite di cifratura **Ascon-128a**. Scalata a uno stato interno di sole **5 parole da 8 bit** (40 bit totali, con chiave e nonce ridotti a 16 bit), mantiene inalterata la struttura algebrica originale - basata su funzioni di S-box, strati di diffusione lineare e permutazioni a round ridotti — ma con una complessità computazionale trattabile.

Questa versione miniaturizzata serve come **laboratorio algebrico** per l'applicazione del **Cube Attack numerico**.

![Schema ASCON 129f](ascon129f.drawio.png)