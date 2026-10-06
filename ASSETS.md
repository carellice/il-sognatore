# Asset del gioco

Elenco degli asset esterni (grafica, musica, effetti, font) con autore, fonte e licenza,
come richiesto dal GDD. I crediti nel gioco riprendono questo elenco.

## Asset esterni

Nessuno, per ora. Tutto ciò che si vede e si sente è **generato dal codice del gioco**
ed è originale di questo progetto:

| Cosa | Dove nasce | Note |
| --- | --- | --- |
| Font pixel 5×7 | `src/core/Art.gd` | Glifi classici 5×7 (dominio pubblico), accenti italiani aggiunti a mano |
| Tileset dei 10 mondi | `src/core/ArtTiles.gd` | Materiali procedurali + palette per mondo (`src/core/G.gd`) |
| Decorazioni del terreno | `src/core/ArtDecor.gd` | Pixel art scritta come testo, originale |
| Sprite di Flavio (5 età) | `src/core/ArtPlayer.gd` | Disegnati dal codice, uno stadio ogni due mondi |
| Nemici, oggetti, icone | `src/core/Sprites.gd` | Pixel art scritta come testo, originale |
| Boss | `src/game/bosses/*.gd` | Disegnati con primitive nel metodo `_draw` |
| Musiche (14 brani) | `audio/*.mp3` (originali in `musica/`) | Generate da Flavio Ceccarelli con Suno AI; verificare la licenza d'uso commerciale del piano Suno prima di pubblicare |
| Sfondi a parallasse | `src/core/ArtBG.gd` | Procedurali |
| Musica ed effetti | `src/core/Snd.gd` | Sintesi chiptune a runtime (onde quadre, triangolari, rumore) |
| Icona dell'app | `godot --headless --path . -- --make-icon` | Generata dagli sprite |

## Software

| Nome | Autore | Fonte | Licenza |
| --- | --- | --- | --- |
| Godot Engine 4 | Juan Linietsky, Ariel Manzur e contributori | https://godotengine.org | MIT |

## Regole per gli asset futuri

Se in seguito si sostituisce la grafica o l'audio con pacchetti esterni o con il lavoro
di un artista, aggiungere qui una riga per asset con: nome, autore, fonte, licenza e link.
Preferire CC0 o licenze commerciali esplicite; evitare le licenze "non commerciali" (NC),
incompatibili con un gioco a pagamento.
