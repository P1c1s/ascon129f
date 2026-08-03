# ASCON 129f

Ascon-129f è una variante "toy" (didattica) dell'algoritmo Ascon-128a, il vincitore del progetto **NIST** per la crittografia leggera. Questo modello è progettato per fungere da laboratorio algebrico per l'applicazione del Cube Attack, permettendo lo studio della propagazione dei polinomi e del recupero dei superpoly in un contesto a complessità ridotta.

# Indice

* [Specifiche dell'architettura](#specifiche-dellarchitettura)
* [Stato interno e variabili](#stato-interno-e-variabili)
* [Permutazioni](#permutazioni)
* [Fasi](#fasi)


---

## Specifiche dell'architettura

Ascon-129f, proprio come la versione standard Ascon-128, si basa sul meccanismo della **Sponge Function**, un'architettura crittografica flessibile che permette di elaborare dati di lunghezza variabile "assorbendo" l'input nello stato interno e "strizzandolo" fuori come output. Nello specifico, Ascon adotta la modalità MonkeyDuplex, che prevede fasi di inizializzazione, assorbimento dei dati associati e del testo in chiaro, e una finalizzazione per generare il tag di autenticazione. All'interno di questo processo, il nucleo dell'algoritmo è costruito come una **SPN** (Substitution-Permutation Network), ovvero una rete che trasforma lo stato attraverso round iterativi composti da uno strato di sostituzione non lineare ($p_s$
​), che utilizza S-box quadratiche a 5 bit per generare confusione algebrica, e uno strato di diffusione lineare ($p_l$
​), che impiega rotazioni cicliche e XOR per diffondere l'informazione tra i bit delle parole dello stato. Questa combinazione permette ad Ascon di mantenere un'elevata sicurezza crittografica pur operando con un'efficienza ottimale su dispositivi con risorse limitate.

##
# Stato interno e variabili
Lo stato interno S è composto da 40 bit, organizzati in 5 parole da 8 bit ciascuna (anziché le 5 parole da 64 bit del modello Ascon 128a). $S=IV \parallel KEY \parallel NONCE$


- **IV** (Vettore di Inizializzazione): 8 bit costante specifica della variante dello standard
- **Key**: 16 bit variabile segreta
- **Nonce**: 16 bit variabile pubblica/controllabile dall'utente
- **Round Costant:** vettore di 12 elementi di 8 bit usati per il warm-up

    | Round ($i$) | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
    | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
    | **$RC_i$** | `0xF0` | `0xE1` | `0xD2` | `0xC3` | `0xB4` | `0xA5` | `0x96` | `0x87` | `0x78` | `0x69` | `0x5A` | `0x4B` |

## Permutazioni
Ogni round della permutazione è definito dalla composizione di tre strati: $p=p_l​\circ p_s​\circ p_c$​.

### Add Round Costant ($p_c$)
Il primo strato effettua l'operazione di XOR tra la costante di round RCi​ e la parola $x_3$​ (la riga centrale dello stato): $x_3​\leftarrow x_3\oplus RCi$

### Substitution Layer ($p_s$)
Lo strato di sostituzione applica in parallelo 5 S-box su ogni colonna dello stato. Le funzioni booleane (ANF) che definiscono la S-box sono: 

- $x_1 \leftarrow x_2 \cdot x_5 \oplus x_4 \oplus x_2 \cdot x_3 \oplus x_3 \oplus x_1 \cdot x_2 \oplus x_2 \oplus x_1$

- $x_2 \leftarrow x_5 \oplus x_3 \cdot x_4 \oplus x_2 \cdot x_4 \oplus x_4 \oplus x_2 \cdot x_3 \oplus x_2 \oplus x_3 \oplus x_1 $

- $x_3 \leftarrow x_4 \cdot x_5 \oplus x_5 \oplus x_3 \oplus x_2 \oplus 1 $

- $x_4 \leftarrow x_1 \cdot x_5 \oplus x_5 \oplus x_1 \cdot x_4 \oplus x_4 \oplus x_3 \oplus x_2 \oplus x_1$

- $x_5 \leftarrow x_2 \cdot x_5 \oplus x_5 \oplus x_4 \oplus x_1 \cdot x_2 \oplus x_1$

 ### Linear Diffusion Layer ($p_l$)
Lo strato di diffusione garantisce la dipendenza tra i bit delle parole tramite rotazioni cicliche e XOR. In Ascon-129f, le funzioni lineari $\Sigma_i$​ sono scalate per operare su parole ridotte:


- $x_1\leftarrow\Sigma_1(y_1)=y_1+(y_1 >>>3)+(Y1 >>> 4)$

- $x_2\leftarrow\Sigma_2(y_2)=y_2+(y_2 >>>5)+(Y2 >>> 7)$

- $x_3\leftarrow\Sigma_3(y_3)=y_3+(y_3 >>>1)+(Y3 >>> 6)$

- $x_4\leftarrow\Sigma_4(y_4)=y_4+(y_4 >>>2)+(Y4 >>> 1)$

- $x_5\leftarrow\Sigma_5(y_5)=y_5+(y_5 >>>7)+(Y5 >>> 1)$





## Fasi
![Schema ASCON 129f](ascon129f.drawio.png)


- $p_a$​: è la permutazione di $a$ round con $a$ pari a 12 esegue in tutte le varianti principali (Ascon-128, Ascon-128a, Ascon-80pq). È utilizzata nelle fasi critiche di Inizializzazione (warm-up) e Finalizzazione (generazione del tag), dove è necessaria la massima sicurezza per proteggere la chiave segreta. I


- $p_b$​: è la permutazione di $a$ round con $b$ pari 6 per Ascon-128 e Ascon-80pq, e 8 round per Ascon-128a. $pb​$ è utilizzata nelle fasi intermedie di elaborazione dei Dati Associati e del Testo in Chiaro (fase di assorbimento), dove un numero inferiore di round permette una maggiore velocità di cifratura pur mantenendo la sicurezza grazie alla struttura "sponge".

### Assorbimento

1. Assorbimento tramite XOR nel "Rate"
Il testo in chiaro viene suddiviso in blocchi della dimensione del rate. Nel caso di Ascon-129f, il rate corrisponde a una singola parola dello stato, ovvero 8 bit (mentre nello standard Ascon-128 è di 64 bit),.

Ogni blocco di testo (nell'immagine rappresentato dai caratteri 't', 'e', 's', 't') viene immesso nella parola x1
​.
L'operazione fondamentale è uno XOR ($\oplus$) tra il blocco di testo in chiaro e il valore corrente contenuto in x1
​.
2. Generazione del Cifrato
Secondo la struttura delle funzioni sponge, il risultato di questa operazione di XOR non serve solo ad aggiornare lo stato, ma diventa immediatamente il blocco di testo cifrato (ciphertext) corrispondente. Questo garantisce che il destinatario, possedendo la chiave e lo stato aggiornato, possa invertire l'operazione per recuperare il messaggio originale.
3. Mescolamento dello Stato (Permutazione pb
​)
Dopo che un blocco è stato assorbito e il relativo cifrato è stato prodotto, lo stato interno deve essere "rimescolato" prima di poter accogliere i successivi 8 bit,.

Questo avviene applicando la permutazione pb
​, che nel tuo schema è indicata come una sequenza di 6 Round,.
Durante questi round, l'informazione appena introdotta in x1
​ viene diffusa verticalmente (tramite lo strato di sostituzione ps
​) e orizzontalmente (tramite lo strato di diffusione lineare pl
​) in tutte e cinque le parole dello stato (x1
​,…,x5
​),.
Solo dopo questo mescolamento lo stato è pronto per subire un nuovo XOR con il carattere successivo (ad esempio, passando dalla 't' alla 'e'), garantendo che ogni bit di output dipenda in modo complesso da tutti i bit di input precedenti,.
In sintesi, il meccanismo "assorbi-permuta-assorbi" assicura che il segreto (la chiave immessa nella fase di inizializzazione) rimanga protetto mentre il messaggio viene cifrato blocco dopo blocco,
