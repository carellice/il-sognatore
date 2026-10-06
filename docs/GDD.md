# Il Sognatore – Game Design Document

Oct 2, 2026 · @Flavio Ceccarelli

## Panoramica

Il Sognatore è un platform 2D in pixel art per Android: 10 mondi da 5 livelli (4 generati proceduralmente più il boss), in cui il protagonista cresce da bambino ad adulto inseguendo la sua amica immaginaria. È una storia d'amore che all'inizio era un'amicizia.

| Voce | Scelta |
| --- | --- |
| Genere | Platform 2D a livelli, con inizio e fine |
| Piattaforma | Android (smartphone, orientamento orizzontale) |
| Stile | Pixel art |
| Durata | 10 mondi × 5 livelli = 50 livelli (più brevi da contare, più difficili da finire) |
| Rigiocabilità | Livelli generati da seed a ogni nuova partita |
| Pubblico | Generale, giocatori casual e appassionati di platform |
| Monetizzazione | Pagamento una tantum, nessuna pubblicità |

**Modello di vendita consigliato:** demo gratuita (Mondo 1) + sblocco del gioco completo con un unico acquisto in-app. Resta "una tantum e senza pubblicità", ma permette di provare prima di comprare. Alternativa: app a pagamento diretta sul Play Store.

## Storia e tema

Flavio, 6 anni, perde la sua amica immaginaria Chiara, rapita dall'Incubo, e la insegue nel mondo dei sogni; crescendo, il ricordo di lei sbiadisce, ma Flavio sceglie di non dimenticarla. Quella che era nata come un'amicizia si rivela, alla fine, l'amore della sua vita.

**Flavio.** Il protagonista. Inizia il gioco a 6 anni e lo finisce adulto, intorno ai 30. Curioso e coraggioso, un po' goffo da piccolo, più sicuro e posato da grande.

**Chiara.** L'amica immaginaria di Flavio: una piccola creatura di luce dalla forma di bambina stilizzata, con una scia luminosa. All'inizio del gioco l'Incubo la porta via, ma resta con Flavio una scintilla: **l'eco di Chiara**. L'eco lo accompagna per tutto il gioco, fa da guida nel tutorial, dà suggerimenti e indica i segreti. A ogni mondo diventa più tenue, perché Flavio crescendo crede sempre meno in lei.

**La crescita.** Flavio passa per 5 stadi, uno ogni due mondi: 6 anni, 9 anni, 14 anni, 20 anni, 30 anni. Ogni stadio ha il suo sprite e una sagoma leggermente più alta.

**Il tema.** Un amore che comincia come un'amicizia d'infanzia, e il diventare grandi senza perdere l'immaginazione. Ogni mondo rappresenta una sfida tipica di quell'età.

**Narrazione.** Leggera e senza dialoghi lunghi: brevi scene in pixel art tra un mondo e l'altro, con al massimo 3 righe di testo ciascuna.

| Momento | Scena |
| --- | --- |
| Prologo | Flavio e Chiara giocano in cameretta. Flavio si addormenta; un'ombra entra nel sogno e porta via Chiara. Resta una scintilla: l'eco. |
| Dopo il Mondo 1 | Flavio trova la ciliegia portafortuna di Chiara tra i giocattoli rotti; l'eco lo guida verso il cielo. |
| Dopo il Mondo 2 | Flavio ha 9 anni, zaino in spalla: il sogno diventa il primo giorno di scuola. |
| Dopo il Mondo 3 | Dalla finestra della biblioteca Flavio vede le stelle e decide di salire più in alto. |
| Dopo il Mondo 4 | Flavio ha 14 anni; il mondo si capovolge e l'eco inizia a sbiadire. |
| Dopo il Mondo 5 | Flavio sbotta: "Sono troppo grande per gli amici immaginari". L'eco si spegne per un istante. |
| Dopo il Mondo 6 | Gli orologi corrono: Flavio ha 20 anni e il tempo per giocare sembra finito. |
| Dopo il Mondo 7 | Negli specchi Flavio vede sé stesso da bambino che gli tende la mano. |
| Dopo il Mondo 8 | Flavio ha 30 anni; l'eco è quasi invisibile, e arriva una tempesta di paure da adulto. |
| Dopo il Mondo 9 | Flavio arriva alla porta dell'Incubo. |
| Finale | Sconfitto l'Incubo, Chiara è quasi trasparente. Flavio la chiama per nome e lei torna a brillare. Flavio si sveglia adulto: accanto al letto c'è un suo vecchio disegno di Chiara, e una lucina che si accende. Chiara è lì, adulta e vera, non più fatta di luce: Flavio si inginocchia e le chiede di sposarlo. I quattro quadri del finale non si saltano toccando lo schermo: si prosegue solo con il pulsante "Avanti" in alto a sinistra. |

## Gameplay e controlli

Movimento libero a scorrimento laterale, con controlli touch a zone pensati per due pollici e un'abilità nuova sbloccata a ogni mondo.

**Obiettivo del livello.** Raggiungere la fine del livello (un portale di luce lasciato dall'amico), evitando ostacoli e nemici e raccogliendo frammenti di sogno.

**Controlli touch (schermo orizzontale):**

| Zona | Gesto | Azione |
| --- | --- | --- |
| Metà sinistra | Tocca e trascina (joystick dinamico che appare dove tocchi) | Muoversi a destra e sinistra |
| Metà destra | Tap | Salto (più a lungo tieni premuto, più in alto salti) |
| Metà destra | Swipe | Abilità attiva del mondo (nel Mondo 10: quella scelta nel selettore) |
| Angolo in alto | Tap | Pausa |

**Principi di comodità:**

- Nessun pulsante fisso piccolo da centrare: le zone sono ampie e il joystick appare sotto il dito.
- Coyote time (salto concesso per pochi istanti dopo aver lasciato una piattaforma) e jump buffering (il tap appena prima dell'atterraggio viene ricordato), per un feeling permissivo.
- Vibrazione leggera su salto, danno e raccolta (disattivabile).
- Layout dei controlli personalizzabile e opzione per mancini nelle impostazioni.
- Supporto opzionale ai controller Bluetooth.

**Abilità.** Ogni mondo sblocca un'abilità che resta disponibile da lì in poi. Nei mondi 2–9 i livelli richiedono le abilità passive già sbloccate più l'abilità attiva di quel mondo; solo il Mondo 10 le combina tutte, con il selettore descritto sotto.

### Abilità e selettore

Le abilità sono di due tipi: le **passive** funzionano sempre dopo lo sblocco, le **attive** si usano con lo swipe nella metà destra dello schermo.

| Mondo | Abilità | Tipo | Attivazione | Durata e ricarica | Uso nei livelli |
| --- | --- | --- | --- | --- | --- |
| 1 | Corsa e salto | Base | Joystick e tap | – | Tutto |
| 2 | Doppio salto | Passiva | Secondo tap in aria | Un doppio salto per salto | Piattaforme alte, buchi larghi |
| 3 | Scatto | Attiva | Swipe orizzontale | 0,2 s; ricarica 1 s; anche in aria | Passare sotto soglie basse, attraversare raffiche |
| 4 | Bolla di sogno | Attiva | Swipe | Fluttua fino a 3 s; ricarica 3 s | Salire lentamente, attraversare zone senza appigli |
| 5 | Inversione gravità | Attiva | Swipe | Istantanea; ricarica 0,5 s | Camminare sul soffitto, aggirare ostacoli |
| 6 | Rallentare il tempo | Attiva | Swipe | Mondo al 40% per 2 s; ricarica 5 s | Piattaforme veloci, lame, proiettili |
| 7 | Schianto | Attiva | Swipe in aria | Picchiata istantanea; ricarica 0,5 s | Rompere casse, rimbalzare altissimo sulle superfici morbide |
| 8 | Riflesso | Attiva | Swipe | Clone che ripete le tue mosse con 2 s di ritardo, per 6 s; ricarica 6 s | Premere due interruttori, fare da piattaforma |
| 9 | Planata | Passiva | Tenere premuto il salto mentre cadi | Finché tieni premuto | Discese lunghe, correnti d'aria |

**Nei mondi 2–9** lo swipe attiva sempre l'abilità attiva di quel mondo, senza scelte da fare. Le abilità passive restano sempre disponibili.

**Selettore (Mondo 10).** Le 6 abilità attive sono tutte disponibili:

- un'icona nell'angolo in basso a destra, sopra la zona del salto, mostra l'abilità selezionata;
- **tap breve** sull'icona: passa all'abilità successiva;
- **tenere premuto** sull'icona: si apre una ruota con le 6 abilità e il gioco rallenta al 25% finché la ruota è aperta; si sceglie scorrendo il dito sull'abilità e sollevandolo;
- lo swipe usa l'abilità selezionata;
- ogni abilità ha la sua ricarica indipendente, mostrata sull'icona.

Nei livelli rigiocati dopo aver finito il gioco, il selettore resta disponibile anche nei mondi precedenti.

### Parametri di movimento

Valori di partenza in pixel della risoluzione base (480×270, tile da 16 px), da affinare nel prototipo della fase 1.

| Parametro | Valore iniziale |
| --- | --- |
| Velocità massima di corsa | 110 px/s (circa 7 tile/s) |
| Accelerazione a terra | 900 px/s² |
| Decelerazione a terra | 1200 px/s² |
| Controllo in aria | 70% dell'accelerazione a terra |
| Gravità | 900 px/s² |
| Velocità massima di caduta | 300 px/s |
| Salto massimo (tenendo premuto) | 4 tile di altezza (velocità iniziale circa 340 px/s) |
| Salto minimo (tap breve) | 1,5 tile (al rilascio la velocità verso l'alto si dimezza) |
| Doppio salto | 3 tile di altezza |
| Salto orizzontale massimo senza abilità | 4 tile di vuoto |
| Planata | Caduta limitata a 60 px/s |
| Coyote time | 0,10 s |
| Jump buffer | 0,12 s |
| Invincibilità dopo un danno | 1,5 s |
| Joystick dinamico | Raggio 60 dp, zona morta 10% |

I valori di salto definiscono anche le regole dei blocchi: nessun salto obbligatorio senza abilità può superare 4 tile in altezza o 4 tile di vuoto.

### Tutorial

Il tutorial è il livello 1 del Mondo 1, fatto a mano: insegna giocando, in circa 3 minuti, senza schermate di testo.

**Regole.**

- Ogni concetto si introduce da solo, in uno spazio sicuro, e poi si mette subito alla prova.
- L'eco di Chiara parla con fumetti di massimo 6 parole.
- Una mano fantasma semitrasparente mostra il gesto da fare sulla zona giusta dello schermo.
- Un suggerimento si ripete solo se il giocatore resta bloccato per più di 8 secondi.
- Nel tutorial non si perdono vite: le cadute riportano all'ultimo punto sicuro.
- Nelle partite successive (nuovo slot o nuovo seed) il tutorial si può saltare.

**Sequenza.**

1. **Risveglio.** Flavio si alza nella cameretta del sogno; l'eco appare. *"Flavio! Seguimi!"* La mano fantasma trascina sulla metà sinistra: si impara a muoversi.
2. **Primo salto.** Un cuscino basso blocca la strada. *"Tocca a destra per saltare!"*
3. **Salto alto.** Una pila di libri più alta. *"Tieni premuto: salti più in alto!"*
4. **Frammenti di sogno.** Un arco di frammenti sopra un piccolo buco: saltando si raccolgono. *"Raccogli i frammenti di sogno!"*
5. **Primo checkpoint.** Un carillon si accende al passaggio. *"Qui il sogno si ricorda di te."*
6. **Primo nemico.** Un soldatino di piombo lento in uno spazio largo. *"Saltagli in testa!"*
7. **Il vuoto.** Un buco con una rete di lana sotto (si rimbalza su); subito dopo, un buco vero ma facile. *"Attento a non cadere!"*
8. **Primo segreto.** Un muro con una crepa ben visibile nasconde una stanzetta con l'oggetto segreto. L'eco brilla vicino al muro. *"Qui c'è qualcosa..."*
9. **Mini prova.** Un tratto breve che combina salto alto, nemico e buco, senza suggerimenti.
10. **Portale.** Il portale di luce chiude il livello. *"Chiara è più avanti. Andiamo!"*

**Tutorial delle abilità.** Il livello 1 di ogni mondo dal 2 al 9 inizia con una breve stanza fatta a mano che presenta la nuova abilità con la stessa logica: spazio sicuro, gesto mostrato dalla mano fantasma, una battuta dell'eco, una piccola prova. Poi il livello prosegue con i blocchi generati. Il Mondo 10 si apre con una stanza che insegna il selettore.

## Difficoltà e vite

La modalità si sceglie una volta, prima della generazione dei mondi, e non si può più cambiare per quella partita.

| Modalità | Vite | Se perdi una vita | Se finisci le vite | Disponibilità |
| --- | --- | --- | --- | --- |
| Sogno lucido | Infinite | Riparti dall'ultimo checkpoint | Non succede | Da subito |
| Sonno agitato | 5 iniziali, vite extra raccoglibili | Riparti dall'ultimo checkpoint | "Ti svegli": riparti dall'inizio del mondo corrente | Da subito |
| Incubo | 1 | Game over | La partita termina | Sbloccata finendo il gioco |

**Difficoltà incrementale.** Indipendente dalla modalità: cresce con il numero del livello, come in Super Mario Bros. Livello per livello aumentano la densità di ostacoli, il numero e l'aggressività dei nemici e la precisione richiesta nei salti, mentre diminuiscono i checkpoint.

**Danno.** Il protagonista ha 3 punti salute per vita. Le cadute nel vuoto e alcune trappole tolgono subito la vita intera.

- [ ] Validare con playtest il numero di vite iniziali in Sonno agitato

### Curva di difficoltà

La difficoltà obiettivo D di un livello va da 1 a 10 e dipende dal livello globale L (da 1 a 100, cioè (mondo − 1) × 10 + livello).

```latex
D = 1 + 9 \cdot \left(\frac{L - 1}{99}\right)^{0.8}
```

Nei primi 2 livelli di ogni mondo D scende di 1, per lasciare spazio alla nuova abilità. La tabella riassume i valori per fasce:

| Mondi | Difficoltà dei blocchi | Lunghezza del livello | Checkpoint | Nemici per schermata |
| --- | --- | --- | --- | --- |
| 1–2 | 1–3 | 6–8 schermate | Ogni 2 schermate | 0–1 |
| 3–4 | 2–5 | 8–10 schermate | Ogni 3 schermate | 1 |
| 5–6 | 4–7 | 10–12 schermate | Ogni 3 schermate | 1–2 |
| 7–8 | 6–8 | 12–14 schermate | Ogni 4 schermate | 2 |
| 9–10 | 7–10 | 14–16 schermate | Ogni 5 schermate | 2–3 |

**Regole di assemblaggio.**

- I blocchi scelti hanno difficoltà compresa tra D − 2 e D + 1; al massimo un blocco per livello vale D + 1.
- Lo stesso blocco non compare due volte nello stesso livello, né in più di 3 livelli dello stesso mondo.
- Dopo un blocco con difficoltà D + 1 segue sempre un blocco più facile o un checkpoint.

### Game over e ripartenza

- **Sogno lucido:** nessun game over.
- **Sonno agitato:** finite le vite, Flavio "si sveglia" e riparte dal livello 1 del mondo corrente con 5 vite. Le abilità restano. Frammenti e oggetti segreti raccolti in quel mondo tornano allo stato di inizio mondo; i livelli restano gli stessi (stesso seed).
- **Incubo:** alla prima morte la partita finisce; restano solo le statistiche e i contenuti già sbloccati nella galleria.

## I 10 mondi

Ogni mondo ha 5 livelli: i livelli 1–4 sono generati, il livello 5 è il boss fatto a mano. (In origine erano 10 per mondo: ridotti a 5 con una curva di difficoltà più ripida.) Ogni mondo introduce un'abilità e corrisponde a una fase della vita.

| # | Mondo | Abilità sbloccata | Fase di vita | Stadio sprite |
| --- | --- | --- | --- | --- |
| 1 | La Cameretta (giocattoli giganti, tutorial) | Corsa e salto | Prima infanzia | Bambino |
| 2 | Prati di Nuvole | Doppio salto | Infanzia, il gioco | Bambino |
| 3 | Biblioteca Infinita (libri volanti) | Scatto | La scuola | Ragazzino |
| 4 | Oceano di Stelle | Bolla di sogno | La curiosità, i grandi sogni | Ragazzino |
| 5 | Città Capovolta | Inversione della gravità | Adolescenza, tutto sottosopra | Adolescente |
| 6 | L'Orologeria | Rallentare il tempo | Il tempo che corre | Adolescente |
| 7 | Regno dei Dolci | Schianto (su superfici rimbalzanti) | Le tentazioni | Giovane adulto |
| 8 | Sala degli Specchi | Riflesso | Chi sono davvero? | Giovane adulto |
| 9 | La Tempesta | Planata con l'ombrello | Le crisi | Adulto |
| 10 | L'Incubo | Selettore di abilità (tutte insieme) | Le paure da adulto, boss finale | Adulto |

Ogni mondo ha una palette di colori propria, un tileset, 2–3 nemici tipici e un tema musicale.

## Generazione procedurale

I livelli si generano assemblando blocchi disegnati a mano, guidati da un seed: ogni nuova partita è diversa, ma ogni livello è sempre giocabile.

**Il seed.** All'inizio di una nuova partita il gioco crea un seed numerico. Da quel seed derivano in modo deterministico tutti i 40 livelli generati. Si salva solo il seed, non i livelli. Il seed è visibile e condivisibile, e si può anche inserirne uno a mano per giocare gli stessi livelli di un amico.

**I blocchi (chunk).** Pezzi di livello creati a mano, larghi per esempio 1–2 schermate. Ogni blocco ha:

- mondo di appartenenza (tileset e nemici);
- valore di difficoltà da 1 a 10;
- abilità richieste (es. doppio salto, gravità);
- punti di ingresso e uscita compatibili (altezza del terreno), così i blocchi si incastrano;
- slot opzionali per nemici, collezionabili, vite extra e oggetto segreto.

**Assemblaggio di un livello:**

1. Calcola la difficoltà obiettivo dal numero del livello (curva crescente lungo i 50 livelli).
2. Sceglie la lunghezza del livello (cresce con la difficoltà).
3. Inizia con un blocco di partenza sicuro e termina con il blocco portale.
4. In mezzo pesca blocchi compatibili, con difficoltà vicina all'obiettivo e solo con le abilità consentite in quel mondo.
5. Inserisce i checkpoint (più frequenti all'inizio del gioco, più radi verso la fine).
6. Distribuisce frammenti di sogno, nemici e un oggetto segreto in un punto nascosto.

**Garanzia di giocabilità.** Ogni blocco viene testato a mano una volta, e i punti di raccordo sono standardizzati. In più, un validatore automatico controlla che il percorso dall'inizio alla fine sia percorribile con le abilità disponibili.

**Fatti a mano.** Tutorial (Mondo 1, livello 1) e i 10 livelli boss.

**Contenuto necessario.** Indicativamente 15–25 blocchi per mondo per avere varietà sufficiente.

### Specifiche dei blocchi

**Dimensioni.** Altezza fissa di 17 tile; larghezza di 30 tile (una schermata) o 60 tile (due schermate). Nei mondi con molta verticalità (Oceano, Tempesta) sono ammessi blocchi alti 34 tile, con telecamera che segue anche in verticale.

**Raccordi.** Ogni blocco ha un'altezza del suolo in ingresso e in uscita, scelta tra 3 quote standard: bassa (riga 3 dal basso), media (riga 6), alta (riga 9). Le prime e le ultime 2 colonne di ogni blocco sono piane e sicure. Il generatore abbina uscita e ingresso uguali, oppure inserisce un blocco rampa di transizione.

**Metadati.** Ogni blocco è una scena Godot con TileMap, più una risorsa (.tres) con:

| Campo | Esempio |
| --- | --- |
| id | cameretta\_014 |
| mondo | 1 |
| difficoltà | 3 |
| larghezza | 30 |
| quota ingresso / uscita | media / alta |
| abilità richieste | doppio\_salto |
| tag | salto, nemici, verticale |

**Slot.** Nodi Marker2D con nomi tipizzati che il generatore riempie in base alla difficoltà: `EnemySlot`, `CollectiblePath` (percorso di frammenti), `SecretSlot`, `CheckpointSlot`, `ExtraLifeSlot`. Il blocco portale e quello di partenza sono speciali, uno per mondo.

**Validatore.** Costruisce una griglia delle celle calpestabili e un grafo di raggiungibilità usando i parametri di movimento (4 tile in alto e 4 di vuoto senza abilità; valori estesi con le abilità consentite). Verifica che esista un percorso dall'ingresso all'uscita e che ogni oggetto segreto sia raggiungibile. Gira in due momenti:

1. in fase di creazione, come strumento nell'editor e nei test automatici, su ogni blocco;
2. a ogni nuova partita, su ogni livello generato: se un livello fallisce, viene rigenerato con un sotto-seed diverso, in modo deterministico.

**Momento della generazione.** All'avvio della nuova partita si generano e validano tutti i 40 livelli in memoria e si salva solo il seed. Ai caricamenti successivi ogni livello si ricostruisce dal seed, identico.

## Nemici, boss e collezionabili

I nemici sono creature del sogno legate al tema di ogni mondo; i boss chiudono ogni mondo e mettono alla prova l'abilità appena imparata.

**Nemici.** 2–3 tipi per mondo, con comportamenti semplici e leggibili: pattugliatore (va avanti e indietro), volante (traiettoria fissa), inseguitore (si attiva quando ti avvicini), sparatore (lancia proiettili). Si sconfiggono saltandoci sopra; alcuni solo con l'abilità del mondo. Esempi: soldatini di piombo nella Cameretta, libri che mordono nella Biblioteca, ingranaggi impazziti nell'Orologeria.

**Boss.** Un boss per mondo al livello 5, disegnato a mano, con 2–3 fasi. Ogni boss richiede di usare l'abilità sbloccata in quel mondo. Il boss finale è l'Incubo, che usa tutte le abilità contro il giocatore.

**Collezionabili:**

| Oggetto | Dove | A cosa serve |
| --- | --- | --- |
| Frammenti di sogno | Sparsi in ogni livello | Punteggio; ogni 100 frammenti una vita extra (in Sonno agitato) |
| Oggetto segreto | Uno per livello, nascosto | Completismo; sbloccano scene extra sull'infanzia del protagonista |
| Vite extra | Rare, in punti difficili | Solo in Sonno agitato |

**Rigiocabilità.** Ogni livello mostra a fine partita: frammenti raccolti, oggetto segreto trovato e tempo impiegato. Finire il gioco sblocca la modalità Incubo.

### Nemici per mondo

Tre nemici per mondo, introdotti uno alla volta: il primo nel livello 1, il secondo dal 2, il terzo dal 3.

| Mondo | Nemico 1 | Nemico 2 | Nemico 3 |
| --- | --- | --- | --- |
| 1 Cameretta | Soldatino di piombo: pattuglia | Pallina: rimbalza su e giù | Trottola: insegue lentamente |
| 2 Nuvole | Pecora-nuvola: pattuglia, ti respinge al contatto | Nuvoletta: vola e lancia un fulmine sotto di sé | Chicco di grandine: cade dall'alto |
| 3 Biblioteca | Libro mordace: insegue | Segnalibro: vola a onda | Calamaio: spara gocce d'inchiostro |
| 4 Oceano di Stelle | Medusa cometa: sale e scende | Pesce lanterna: insegue nel buio | Stella cadente: attraversa lo schermo |
| 5 Città Capovolta | Lampione: pattuglia sul soffitto | Piccione al contrario: vola | Tombino: sbuca e risucchia |
| 6 Orologeria | Ingranaggio: rotola su binari | Cucù: spara a intervalli regolari | Pendolo: ostacolo che oscilla |
| 7 Regno dei Dolci | Gommoso: rimbalza | Cupcake: spara confettini | Caramella appiccicosa: rallenta al contatto |
| 8 Sala degli Specchi | Frammento di vetro: vola | Riflesso oscuro: copia le tue mosse in ritardo | Specchio deformante: inverte i comandi per 2 s se ti tocca |
| 9 Tempesta | Raffica: ti spinge di lato | Corvo: piomba in picchiata | Ombrello rotto: cade e rimbalza |
| 10 Incubo | Ombre dei nemici precedenti | Mano d'ombra: sbuca dal pavimento | Occhio: segue e spara raggi |

Si sconfiggono saltandoci sopra; eccezioni: pendolo e raffica sono invulnerabili, calamaio e cucù sono vulnerabili solo nella pausa tra un colpo e l'altro.

### I 10 boss

Ogni boss ha 3 fasi, servono 3 colpi per fase, e ogni fase diventa più veloce. Ogni boss mette alla prova l'abilità appena imparata.

| Mondo | Boss | Come si sconfigge |
| --- | --- | --- |
| 1 | Re dei Giocattoli, un robot di latta gigante | Carica da una parte all'altra; quando sbatte contro il muro resta stordito e gli si salta in testa. |
| 2 | Il Cumulonembo | Nuvola enorme che lancia fulmini; col doppio salto si raggiungono le nuvole alte e gli si salta sugli occhi. |
| 3 | Il Grande Tomo, un libro gigante | Spara raffiche di pagine; con lo scatto si attraversano i varchi per colpire il segnalibro, il suo punto debole. |
| 4 | Il Leviatano di Stelle | Serpente cosmico che nuota attorno all'arena; con la bolla si fluttua fino alla gemma sulla sua schiena. |
| 5 | Il Sindaco Sottosopra | Salta tra pavimento e soffitto; invertendo la gravità lo si insegue e gli si piomba addosso. |
| 6 | Il Grande Orologio | Le lancette spazzano l'arena; rallentando il tempo si passa tra loro e si colpisce il meccanismo centrale. |
| 7 | La Regina Glassata, una torta a piani | Con lo schianto sulle superfici morbide si rimbalza fino in cima e si rompe un piano alla volta. |
| 8 | Flavio Oscuro, il riflesso adolescente di Flavio | Copia ogni mossa; col proprio riflesso si premono due interruttori insieme e crollano gli specchi su di lui. |
| 9 | L'Occhio del Ciclone | Arena verticale piena di correnti; planando tra i venti si colpiscono i 3 nuclei della tempesta. |
| 10 | L'Incubo, un'ombra enorme | Fase 1: scatto e gravità. Fase 2: tempo e bolla. Fase 3: riflesso, schianto e planata, cambiando abilità col selettore. L'ultimo colpo è una scena: Flavio chiama Chiara. |

**Checkpoint nei boss.** In Sogno lucido si riparte dall'inizio della fase in cui si è morti; in Sonno agitato dall'inizio del combattimento.

### Segreti e dopo il finale

**Oggetti segreti.** Uno per livello, 5 per mondo (quello del boss è nell'arena). Trovare tutti i segreti di un mondo sblocca una **scena dei ricordi**: un breve momento di Flavio e Chiara da piccoli, legato al tema di quel mondo. Trovare tutti i 100 segreti sblocca un epilogo esteso del finale.

**Galleria.** Dal menu principale, comune a tutti gli slot: scene della storia viste, scene dei ricordi sbloccate, bestiario di nemici e boss incontrati, statistiche complessive. Ciò che si sblocca resta anche iniziando nuove partite.

**Dopo i titoli di coda.**

- Si sblocca la modalità Incubo.
- Si può rigiocare ogni livello di quella partita dalla mappa del mondo, con il selettore di abilità disponibile ovunque, per trovare i segreti mancanti.
- **Nuovo sogno:** una nuova partita con un nuovo seed (o uno inserito a mano), in qualunque modalità sbloccata. Ripartono storia e abilità; la galleria resta.
- Per ogni livello restano i record: miglior tempo, frammenti raccolti, segreto trovato.

## Salvataggio e pausa

Il gioco salva in automatico a ogni checkpoint e a fine livello; la pausa è sempre disponibile e l'app chiusa di colpo riprende dall'ultimo salvataggio.

**Cosa si salva:** seed, modalità di difficoltà, mondo e livello correnti, ultimo checkpoint raggiunto, vite e salute, abilità sbloccate, frammenti e oggetti segreti raccolti, statistiche (tempi, morti).

**Quando si salva:**

- a ogni checkpoint raggiunto;
- a fine livello;
- quando l'app va in background (telefonata, cambio app), con ripresa dal checkpoint.

**Slot.** 3 slot di salvataggio, ognuno con la sua partita, il suo seed e la sua modalità.

**Pausa.** Pulsante in alto e pausa automatica quando l'app perde il focus. Menu di pausa: Riprendi, Ricomincia dal checkpoint, Impostazioni, Torna alla mappa del mondo, Esci.

**Mappa del mondo.** Tra un livello e l'altro, una mappa mostra i livelli completati e permette di rigiocarli per trovare segreti mancanti.

**Backup.** Opzionale in futuro: salvataggio su cloud con Google Play Games Services.

## Grafica, audio e interfaccia

Pixel art con tile da 16×16 pixel su una risoluzione base di 480×270, scalata a pixel interi sugli schermi dei telefoni.

**Grafica.**

- Tile 16×16, personaggi circa 16×24 (bambino) fino a 16×32 (adulto).
- Palette limitata per mondo, dai colori caldi della Cameretta a quelli cupi dell'Incubo.
- Sfondi con parallasse a 2–3 livelli.
- Fonte degli asset: pacchetti pixel art gratuiti o a basso costo (es. itch.io) come base, poi personalizzati; in seguito eventualmente un artista per protagonista, amico e boss.

**Audio.**

- Un tema musicale per mondo in stile chiptune, più un tema per menu, boss e finale.
- Effetti sonori per salto, atterraggio, raccolta, danno, checkpoint e abilità.
- Fonti: librerie gratuite o royalty-free; strumenti come jsfxr per generare effetti retrò.

**Interfaccia.**

- HUD minimale: salute, vite (solo Sonno agitato), frammenti raccolti.
- Menu principale: Continua, Nuova partita (scelta difficoltà e seed), Impostazioni, Crediti.
- Impostazioni: volume musica ed effetti, vibrazione, layout controlli, lingua (italiano e inglese come minimo).

### Accessibilità

Opzioni nelle impostazioni, disponibili in ogni modalità salvo dove indicato:

- **Daltonismo:** filtri per protanopia, deuteranopia e tritanopia; pericoli e nemici distinguibili anche per forma, non solo per colore.
- **Effetti visivi:** riduzione di lampi e scuotimento dello schermo.
- **Velocità di gioco:** 100%, 85%, 70% (solo Sogno lucido e Sonno agitato, non in Incubo).
- **Controlli:** dimensione e opacità del joystick e delle zone regolabili; layout per mancini; salto alto automatico (ogni tap esegue il salto massimo).
- **Testo:** dimensione dei fumetti regolabile; indicatori visivi per i suoni importanti (es. un nemico che arriva fuori schermo).

## Tecnologia e roadmap

Motore Godot 4 con GDScript, sviluppo con Claude Code su Mac, e un primo traguardo piccolo: un mondo da 5 livelli completamente giocabile su telefono.

**Stack tecnico.**

- Motore: Godot 4.x (gratuito, ottimo per il 2D, export Android integrato).
- Linguaggio: GDScript.
- Versionamento: Git, con un repository dedicato.
- Blocchi di livello: scene Godot con TileMap, più metadati (difficoltà, abilità, raccordi) in un file di risorsa.
- Generatore: RNG con seed (RandomNumberGenerator di Godot), completamente deterministico.
- Salvataggi: file JSON o risorsa Godot in `user://`.
- Export: Android SDK e JDK sul Mac; firma con keystore per il Play Store (formato AAB).
- Acquisto in-app: plugin Google Play Billing per Godot (solo dalla fase 5).

**Roadmap per fasi:**

1. **Prototipo di movimento.** Personaggio con corsa, salto variabile, coyote time e controlli touch a zone, provato su telefono reale. È la fase più importante: se muoversi non è piacevole, il resto non conta.
2. **MVP: Mondo 1.** Tileset Cameretta, 2 nemici, checkpoint, pausa, salvataggio, 5 livelli fatti a mano, amico immaginario che guida il tutorial.
3. **Generatore.** Sistema di blocchi, seed, curva di difficoltà, validatore; il Mondo 1 passa a 9 livelli generati + boss.
4. **Contenuti.** Mondi da 2 a 10, uno alla volta, ciascuno con abilità, nemici, blocchi, boss e scena narrativa.
5. **Rifinitura e pubblicazione.** Modalità di difficoltà, audio completo, localizzazione, acquisto in-app per sbloccare il gioco, test chiusi su Google Play, pubblicazione.

**Indicazioni per Claude Code.** Usare questo documento come specifica. Procedere una fase alla volta, con una build Android testabile alla fine di ogni fase. Tenere separati il codice di gioco (giocatore, nemici, abilità) dal generatore di livelli e dal sistema di salvataggio, così ciascuno si testa da solo.

**Pubblicazione: cosa serve.** Account sviluppatore Google Play (quota una tantum), privacy policy, icona e screenshot per la scheda, e i test chiusi richiesti da Google per i nuovi account personali prima della pubblicazione.

### Requisiti tecnici

| Voce | Requisito |
| --- | --- |
| Android minimo | 7.0 (API 24) come punto di partenza, da verificare con la versione di Godot usata |
| Target SDK | Quello richiesto da Google Play al momento della pubblicazione |
| Renderer Godot | Compatibility (OpenGL ES 3), il più adatto al 2D su mobile |
| Prestazioni | 60 fps stabili su un telefono di fascia media di qualche anno fa |
| Dimensione | Pacchetto AAB sotto i 100 MB |
| Schermo | Solo orizzontale; scalatura a pixel interi; formati da 16:9 a 21:9 allargando la visuale in orizzontale; HUD dentro l'area sicura (notch e bordi curvi) |
| Batteria | Limite a 60 fps; gioco fermo in background |
| Dispositivi di test | Almeno un telefono economico, uno di fascia media e un tablet |

### Prezzo

Mondo 1 gratuito come demo; sblocco del gioco completo con un unico acquisto in-app a un prezzo indicativo di 3,99 €, da confrontare con giochi simili prima del lancio. Nessuna pubblicità e nessun altro acquisto.

### Licenze degli asset

Un file `ASSETS.md` nel repository elenca per ogni asset esterno (grafica, musica, effetti, font): nome, autore, fonte, licenza e link. Preferire licenze CC0 o commerciali esplicite; evitare licenze "non commerciali" (NC), incompatibili con un gioco a pagamento. I crediti nel gioco si generano da questo elenco.

### Dati e privacy

Nessuna raccolta di dati, nessun account, nessun SDK di analytics. Crash ed errori si monitorano con gli strumenti già inclusi nella Google Play Console (Android vitals), senza codice aggiuntivo. La privacy policy dichiara che il gioco non raccoglie dati personali; l'acquisto in-app è gestito interamente da Google Play.
