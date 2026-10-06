extends RefCounted
## Dati dei 30 nemici (GDD, "Nemici per mondo"). Il comportamento è in Enemy.gd.
## slot: g = a terra, a = in aria, c = appeso al soffitto.

const DEFS := {
	# 1 Cameretta
	"soldatino": {"beh": "patrol", "slot": "g", "w": 10, "h": 14, "speed": 26.0},
	"pallina": {"beh": "hop", "slot": "g", "w": 10, "h": 10, "jump": 250.0},
	"trottola": {"beh": "chase", "slot": "g", "w": 12, "h": 12, "speed": 36.0},
	# 2 Prati di Nuvole
	"pecora": {"beh": "patrol", "slot": "g", "w": 14, "h": 11, "speed": 30.0, "knock": true},
	"nuvoletta": {"beh": "fly", "path": "h", "slot": "a", "w": 14, "h": 9, "speed": 30.0, "shoot": "down", "rate": 2.6},
	"grandine": {"beh": "drop", "slot": "a", "w": 8, "h": 8},
	# 3 Biblioteca
	"libro": {"beh": "chase", "slot": "g", "w": 12, "h": 12, "speed": 46.0, "hop": true},
	"segnalibro": {"beh": "fly", "path": "sine", "slot": "a", "w": 8, "h": 14, "speed": 38.0},
	"calamaio": {"beh": "shooter", "slot": "g", "w": 12, "h": 12, "rate": 2.4, "guard": true, "shot": "arc"},
	# 4 Oceano di Stelle
	"medusa": {"beh": "fly", "path": "v", "slot": "a", "w": 12, "h": 12, "speed": 30.0},
	"pesce": {"beh": "chase", "slot": "a", "w": 14, "h": 10, "speed": 42.0, "fly": true},
	"stella": {"beh": "cross", "slot": "a", "w": 10, "h": 10, "speed": 170.0, "invuln": true},
	# 5 Città Capovolta
	"lampione": {"beh": "patrol", "slot": "c", "w": 8, "h": 20, "speed": 30.0, "ceiling": true},
	"piccione": {"beh": "fly", "path": "h", "slot": "a", "w": 12, "h": 10, "speed": 52.0},
	"tombino": {"beh": "pop", "slot": "g", "w": 14, "h": 8, "pull": true, "invuln": true},
	# 6 Orologeria
	"ingranaggio": {"beh": "patrol", "slot": "g", "w": 14, "h": 14, "speed": 68.0, "spin": true},
	"cucu": {"beh": "shooter", "slot": "g", "w": 12, "h": 16, "rate": 1.7, "guard": true, "shot": "straight"},
	"pendolo": {"beh": "pendulum", "slot": "a", "w": 12, "h": 12, "invuln": true},
	# 7 Regno dei Dolci
	"gommoso": {"beh": "hop", "slot": "g", "w": 12, "h": 10, "jump": 270.0, "speed": 30.0},
	"cupcake": {"beh": "shooter", "slot": "g", "w": 12, "h": 13, "rate": 2.2, "shot": "spread"},
	"caramella": {"beh": "patrol", "slot": "g", "w": 12, "h": 10, "speed": 14.0, "sticky": true},
	# 8 Sala degli Specchi
	"vetro": {"beh": "fly", "path": "circle", "slot": "a", "w": 10, "h": 10, "speed": 48.0},
	"riflesso_oscuro": {"beh": "copy", "slot": "g", "w": 10, "h": 20, "invuln": true},
	"specchio": {"beh": "fly", "path": "v", "slot": "a", "w": 12, "h": 16, "speed": 18.0, "mirror": true},
	# 9 Tempesta
	"raffica": {"beh": "gust", "slot": "g", "w": 44, "h": 60, "invuln": true},
	"corvo": {"beh": "dive", "slot": "a", "w": 12, "h": 10, "speed": 150.0},
	"ombrello": {"beh": "drop", "slot": "a", "w": 12, "h": 12, "bounce": true},
	# 10 Incubo
	"ombra": {"beh": "shadow", "slot": "*"},
	"mano": {"beh": "pop", "slot": "g", "w": 10, "h": 18, "invuln": true},
	"occhio": {"beh": "chase", "slot": "a", "w": 14, "h": 12, "speed": 24.0, "fly": true, "shoot": "aim", "rate": 2.8},
}


static func fits(kind: String, slot: String) -> bool:
	var s: String = DEFS[kind]["slot"]
	if s == "*":
		return true
	if slot == "E":
		return s == "g"
	return s == "a" or s == "c"
