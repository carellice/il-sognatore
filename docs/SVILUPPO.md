# Il Sognatore: note per lo sviluppo

Platform 2D in pixel art per Android: 10 mondi da 5 livelli (4 generati da un seed più il boss),
in cui Flavio cresce da bambino ad adulto inseguendo Chiara: all'inizio la sua amica immaginaria, alla fine l'amore della sua vita.

La specifica completa è in [GDD.md](GDD.md).

## Provarlo subito (Mac)

Serve [Godot 4](https://godotengine.org) (`brew install --cask godot`).

```bash
godot --path .
```

| Azione | Tastiera | Controller | Touch |
| --- | --- | --- | --- |
| Muoversi | A/D o frecce | stick o croce | trascina sulla metà sinistra |
| Saltare (tieni premuto = più in alto) | Spazio, Z, W | A | tap sulla metà destra |
| Abilità del mondo | X, Maiusc | X / B | swipe sulla metà destra |
| Cambiare abilità (Mondo 10) | C, Q | dorsali | tap sull'icona; tieni premuto per la ruota |
| Pausa | Esc, P | Start | angolo in alto |

Con il mouse si provano anche i controlli touch (il clic vale come un dito).

Per saltare direttamente a un livello:

```bash
godot --path . -- --go=game --world=5 --level=3
```

## Struttura

| Cartella | Contenuto |
| --- | --- |
| `src/game/` | Gioco: fisica (`Phys.gd`), protagonista, nemici, boss, controlli, HUD |
| `src/gen/` | Generatore di livelli, libreria dei blocchi, validatore |
| `src/core/` | Dati globali, salvataggi, testi IT/EN, grafica e audio generati dal codice |
| `src/ui/` | Menu, mappa del mondo, scene narrative, impostazioni, galleria |
| `data/chunks/` | I blocchi di livello disegnati a mano, un file per mondo |
| `data/handmade.txt` | Tutorial, stanze delle abilità e arene dei boss (generato da `tools/make_handmade.py`) |
| `tests/`, `tools/` | Test automatici e script di supporto |

Codice di gioco, generatore e salvataggi sono separati: ciascuno si prova da solo.

## Blocchi di livello

Il GDD prevede blocchi come scene Godot con TileMap più una risorsa di metadati.
Qui i blocchi sono **griglie di testo** (`data/chunks/wN.txt`): stesse informazioni
(difficoltà, abilità richieste, raccordi, slot), ma si scrivono e si confrontano in Git
molto più facilmente e il validatore li controlla tutti in pochi secondi.
La legenda dei caratteri è in cima a `src/gen/ChunkLib.gd`.

Le quote di ingresso e uscita (bassa, media, alta) si ricavano dalla prima e
dall'ultima colonna del blocco. Un blocco può comparire anche nei mondi successivi
(con tileset e nemici di quel mondo) se non richiede abilità non disponibili lì.

## Test

```bash
godot --headless --path . -- --test
```

Controlla formato e raccordi di ogni blocco, che ogni blocco sia percorribile con le
abilità del suo mondo (il validatore simula i salti con la stessa fisica del gioco),
che i livelli fatti a mano siano completabili e che il generatore sia deterministico
su più seed. Dopo aver modificato i blocchi, rigenerare la cache di validazione:

```bash
godot --headless --path . -- --test --write
```

Altri strumenti: `tools/check.sh` (compilazione degli script), `tools/smoke.sh`
(avvia tutti i mondi senza finestra con un bot), `tools/shot.sh` (screenshot).

## Android

Il preset di export è in `export_presets.cfg` (pacchetto `com.flaviocecca.ilsognatore`).
Servono i modelli di export di Godot (Editor → Gestisci modelli d'esportazione) e, nelle
impostazioni dell'editor, i percorsi di Android SDK e JDK. Poi:

```bash
godot --headless --path . --export-debug "Android" build/il-sognatore.apk
```

Per il Play Store serve il formato AAB (build con Gradle) e una keystore di rilascio:
è il lavoro della fase 5 della roadmap, insieme all'acquisto in-app.

## Stato rispetto alla roadmap del GDD

Fatto: movimento e controlli touch, 10 mondi con abilità, 30 nemici, 10 boss, generatore
con seed e validatore, tutorial e stanze delle abilità, tre modalità di difficoltà,
3 slot di salvataggio, mappa, scene narrative, galleria, accessibilità, IT/EN.

Da fare: prova su telefono reale e taratura dei valori (fase 1), playtest delle vite in
Sonno agitato, acquisto in-app e demo del Mondo 1 (fase 5), pubblicazione.
