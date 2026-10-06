extends Node
## Costanti globali e dati di gioco (vedi docs/GDD.md).

const EnemyDefs = preload("res://src/game/EnemyDefs.gd")

const TILE := 16
const VIEW_W := 480
const VIEW_H := 270
const ROWS := 17

# Livelli per mondo: l'ultimo è sempre il boss (quindi LEVELS - 1 livelli generati)
const LEVELS := 5
const SCREEN_COLS := 30

# Codici dei tile nella griglia di un livello
const T_EMPTY := 0
const T_SOLID := 1
const T_ONEWAY := 2
const T_SPIKE := 3
const T_SPIKE_D := 4
const T_CRATE := 5
const T_BOUNCY := 6
const T_FAKE := 7
const T_DOOR := 8
const T_UPDRAFT := 9

# --- Parametri di movimento (GDD, "Parametri di movimento") ---
const RUN_SPEED := 110.0
const ACC_GROUND := 900.0
const DEC_GROUND := 1200.0
const AIR_CONTROL := 0.7
const GRAVITY := 900.0
const MAX_FALL := 300.0
const JUMP_V := 340.0
const DJUMP_V := 294.0
const GLIDE_FALL := 60.0
const COYOTE := 0.10
const JUMP_BUFFER := 0.12
const INVULN := 1.5
const MAX_HP := 3

# Abilità
const DASH_TIME := 0.2
const DASH_SPEED := 360.0
const DASH_CD := 1.0
const BUBBLE_TIME := 3.0
const BUBBLE_RISE := 40.0
const BUBBLE_SPEED := 80.0
const BUBBLE_CD := 3.0
const FLIP_CD := 0.5
const SLOW_TIME := 2.0
const SLOW_SCALE := 0.4
const SLOW_CD := 5.0
const SLAM_SPEED := 420.0
const SLAM_CD := 0.5
const SLAM_BOUNCE := 540.0
const BOUNCE_V := 300.0
const BOUNCE_HELD_V := 400.0
const CLONE_DELAY := 2.0
const CLONE_TIME := 6.0
const CLONE_CD := 6.0
const UPDRAFT_V := 120.0

const ACTIVES := ["scatto", "bolla", "gravita", "tempo", "schianto", "riflesso"]
const ABILITY_CD := {"scatto": DASH_CD, "bolla": BUBBLE_CD, "gravita": FLIP_CD, "tempo": SLOW_CD, "schianto": SLAM_CD, "riflesso": CLONE_CD}
const ABILITY_COLOR := {
	"scatto": Color("ffd65a"), "bolla": Color("7fd4ff"), "gravita": Color("c08cff"),
	"tempo": Color("e6c15a"), "schianto": Color("f08fc0"), "riflesso": Color("d6ecff"),
	"doppio_salto": Color("ffffff"), "planata": Color("ffe45e"),
}

# Altezza dell'hitbox per stadio di crescita (6, 9, 14, 20, 30 anni)
const STAGE_H := [18.0, 20.0, 22.0, 25.0, 28.0]
const BODY_HW := 5.0
const CROUCH_H := 12.0

const MODES := ["lucido", "agitato", "incubo"]

# --- I 10 mondi ---
const WORLDS := [
	{"id": "cameretta", "ability": "", "style": "wood",
		"enemies": ["soldatino", "pallina", "trottola"], "boss": "re_giocattoli",
		"pal": {"sky1": "f6d6a8", "sky2": "f2b98a", "far": "e9a878", "mid": "c97a5a", "ground": "b5713c", "dark": "7a4526", "top": "e8c170", "accent": "d9534f"},
		"music": {"root": 60, "minor": false, "bpm": 112}},
	{"id": "nuvole", "ability": "doppio_salto", "style": "cloud",
		"enemies": ["pecora", "nuvoletta", "grandine"], "boss": "cumulonembo",
		"pal": {"sky1": "5fb4ee", "sky2": "c9ecff", "far": "e6f6ff", "mid": "ffffff", "ground": "eef4ff", "dark": "a9bfe3", "top": "ffffff", "accent": "ffd65a"},
		"music": {"root": 65, "minor": false, "bpm": 124}},
	{"id": "biblioteca", "ability": "scatto", "style": "books",
		"enemies": ["libro", "segnalibro", "calamaio"], "boss": "grande_tomo",
		"pal": {"sky1": "2e2018", "sky2": "5a3d2b", "far": "4a3324", "mid": "6b4a33", "ground": "7a5236", "dark": "3f281a", "top": "c9a36b", "accent": "b33a3a"},
		"music": {"root": 57, "minor": true, "bpm": 120}},
	{"id": "oceano", "ability": "bolla", "style": "stars",
		"enemies": ["medusa", "pesce", "stella"], "boss": "leviatano",
		"pal": {"sky1": "070b30", "sky2": "1b2a7a", "far": "24348f", "mid": "3147b0", "ground": "2a3f9e", "dark": "141d5c", "top": "7fd4ff", "accent": "ffe27a"},
		"music": {"root": 62, "minor": false, "bpm": 96}},
	{"id": "citta", "ability": "gravita", "style": "brick",
		"enemies": ["lampione", "piccione", "tombino"], "boss": "sindaco",
		"pal": {"sky1": "f08a5d", "sky2": "6a2c70", "far": "4d2a66", "mid": "3b2552", "ground": "5b5f7a", "dark": "303246", "top": "a9adc6", "accent": "ffd166"},
		"music": {"root": 59, "minor": true, "bpm": 132}},
	{"id": "orologeria", "ability": "tempo", "style": "brass",
		"enemies": ["ingranaggio", "cucu", "pendolo"], "boss": "grande_orologio",
		"pal": {"sky1": "241c10", "sky2": "5a4420", "far": "4a3818", "mid": "6e5422", "ground": "a67c2e", "dark": "5a4014", "top": "e6c15a", "accent": "d9d9d9"},
		"music": {"root": 64, "minor": true, "bpm": 140}},
	{"id": "dolci", "ability": "schianto", "style": "wafer",
		"enemies": ["gommoso", "cupcake", "caramella"], "boss": "regina_glassata",
		"pal": {"sky1": "ffc4e2", "sky2": "fff0c9", "far": "ffd9a8", "mid": "f7a8c8", "ground": "e58fb1", "dark": "a3507a", "top": "fff5f0", "accent": "7ad6c8"},
		"music": {"root": 67, "minor": false, "bpm": 128}},
	{"id": "specchi", "ability": "riflesso", "style": "glass",
		"enemies": ["vetro", "riflesso_oscuro", "specchio"], "boss": "flavio_oscuro",
		"pal": {"sky1": "161c2b", "sky2": "3a4a6b", "far": "2b3852", "mid": "44567a", "ground": "6f86a8", "dark": "37455e", "top": "d6ecff", "accent": "c08cff"},
		"music": {"root": 61, "minor": true, "bpm": 108}},
	{"id": "tempesta", "ability": "planata", "style": "rock",
		"enemies": ["raffica", "corvo", "ombrello"], "boss": "occhio_ciclone",
		"pal": {"sky1": "1a1d26", "sky2": "3d4656", "far": "2c323f", "mid": "39414f", "ground": "4a5263", "dark": "232733", "top": "8c98ad", "accent": "ffe45e"},
		"music": {"root": 55, "minor": true, "bpm": 136}},
	{"id": "incubo", "ability": "selettore", "style": "void",
		"enemies": ["ombra", "mano", "occhio"], "boss": "incubo",
		"pal": {"sky1": "07040d", "sky2": "2a0f33", "far": "1c0c26", "mid": "2a1238", "ground": "2b1b3d", "dark": "0f0818", "top": "7b3fa0", "accent": "ff3b6b"},
		"music": {"root": 54, "minor": true, "bpm": 144}},
]

# Fasce della curva di difficoltà (GDD, "Curva di difficoltà")
const BANDS := [
	{"len": [6, 8], "cp": 2, "en": [0.8, 1.3]},
	{"len": [8, 10], "cp": 3, "en": [1.2, 1.6]},
	{"len": [10, 12], "cp": 3, "en": [1.0, 2.0]},
	{"len": [12, 14], "cp": 4, "en": [2.0, 2.2]},
	{"len": [14, 16], "cp": 5, "en": [2.0, 3.0]},
]

# Richiesta di livello passata tra una schermata e l'altra
var req := {"world": 1, "level": 1, "from_cp": false}
var params := {}
var main: Node
var debug_keys := {}


func goto(screen: String, p := {}) -> void:
	if main != null:
		main.goto(screen, p)


func pal(world: int, key: String) -> Color:
	return Color(WORLDS[world - 1]["pal"][key])


func stage_of(world: int) -> int:
	return clampi((world - 1) / 2, 0, 4)


func global_level(world: int, level: int) -> int:
	return (world - 1) * LEVELS + level


## Difficoltà obiettivo D (1..10) del livello.
func difficulty(world: int, level: int) -> float:
	var l := float(global_level(world, level))
	# con 5 livelli per mondo la salita è più ripida (esponente 0.7) e parte più in alto:
	# solo il primo livello di un mondo è un po' più morbido, per presentare l'abilità
	var d := 1.6 + 8.4 * pow((l - 1.0) / (10.0 * LEVELS - 1.0), 0.7)
	if level <= 1:
		d -= 0.6
	return clampf(d, 1.0, 10.0)


func band(world: int) -> Dictionary:
	return BANDS[clampi((world - 1) / 2, 0, 4)]


## Abilità disponibili in un mondo: passive sempre, attiva solo quella del mondo
## (tutte nel Mondo 10 e nei livelli rigiocati dopo il finale).
func abilities_for(world: int, postgame := false) -> Dictionary:
	var actives: Array = []
	if world >= 10 or postgame:
		actives = ACTIVES.duplicate()
	else:
		var ab: String = WORLDS[world - 1]["ability"]
		if ab in ACTIVES:
			actives = [ab]
	return {"double": world >= 2 or postgame, "glide": world >= 9 or postgame, "actives": actives}


## Nemici disponibili nel livello: il primo dai livelli 1-3, il secondo dal 4, il terzo dal 7.
func enemies_for(world: int, level: int) -> Array:
	var all: Array = WORLDS[world - 1]["enemies"]
	var n := 1 if level <= 1 else (2 if level <= 2 else 3)
	# se il primo "nemico" è solo un pericolo invulnerabile (es. la raffica), serve
	# subito anche un nemico vero, altrimenti i primi livelli restano vuoti
	if n == 1 and EnemyDefs.DEFS[all[0]].get("invuln", false):
		n = 2
	return all.slice(0, n)


func key(world: int, level: int) -> String:
	return "%d-%d" % [world, level]


func fmt_time(t: float) -> String:
	var s := int(t)
	return "%d:%02d" % [s / 60, s % 60]


# --- layout dei Control (ancore esplicite: non dipendono dalla dimensione del genitore) ---

func full(n: Control) -> void:
	n.anchor_left = 0.0
	n.anchor_top = 0.0
	n.anchor_right = 1.0
	n.anchor_bottom = 1.0
	n.offset_left = 0.0
	n.offset_top = 0.0
	n.offset_right = 0.0
	n.offset_bottom = 0.0


func top_wide(n: Control, y: float, h: float) -> void:
	full(n)
	n.anchor_bottom = 0.0
	n.offset_top = y
	n.offset_bottom = y + h


func bottom_wide(n: Control, top: float, bottom: float) -> void:
	full(n)
	n.anchor_top = 1.0
	n.offset_top = top
	n.offset_bottom = bottom


## Fissa un Control a un angolo: ax/ay 0 o 1, poi posizione e dimensione relative.
func pin(n: Control, ax: float, ay: float, x: float, y: float, w: float, h: float) -> void:
	n.anchor_left = ax
	n.anchor_right = ax
	n.anchor_top = ay
	n.anchor_bottom = ay
	n.offset_left = x
	n.offset_top = y
	n.offset_right = x + w
	n.offset_bottom = y + h
