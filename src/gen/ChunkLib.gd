extends RefCounted
## Libreria dei blocchi (chunk) disegnati a mano.
##
## I blocchi sono griglie di testo in data/chunks/wN.txt (più facili da scrivere,
## confrontare in Git e validare in automatico rispetto a scene con TileMap):
##
##   @ id d=3 req=scatto tags=salto,nemici [noflip]
##   righe della griglia (quelle mancanti in alto sono vuote)
##
## Legenda:  # solido   = piattaforma passante   ^ v spine (pavimento/soffitto)
##   B cassa   M morbido/rimbalzante   C muro crepato (finto)   D porta   ~ corrente d'aria
##   o frammento   S segreto   L vita extra   E nemico a terra   F nemico in volo
##   a b c nemico 1/2/3 del mondo   T interruttore   H V piattaforma mobile (oriz./vert.)
##   Z N lama (oriz./vert.)   P partenza   X portale   K checkpoint   Q boss   1-9 suggerimento

const TILE_CHARS := {
	"#": G.T_SOLID, "=": G.T_ONEWAY, "^": G.T_SPIKE, "v": G.T_SPIKE_D, "B": G.T_CRATE,
	"M": G.T_BOUNCY, "C": G.T_FAKE, "D": G.T_DOOR, "~": G.T_UPDRAFT,
}
const QUOTES := {3: "L", 6: "M", 9: "H"}
const QUOTE_ROWS := {"L": 3, "M": 6, "H": 9}

static var _by_world := {}
static var _hand := {}
static var errors: Array = []


static func chunks_of(world: int) -> Array:
	if not _by_world.has(world):
		_by_world[world] = _load_file("res://data/chunks/w%d.txt" % world, world)
	return _by_world[world]


static func handmade(id: String) -> Dictionary:
	if _hand.is_empty():
		for c in _load_file("res://data/handmade.txt", 0):
			_hand[c["id"]] = c
	return _hand.get(id, {})


static func _load_file(path: String, world: int) -> Array:
	var out: Array = []
	if not FileAccess.file_exists(path):
		return out
	var txt := FileAccess.get_file_as_string(path)
	var cur := {}
	var rows: Array = []
	for line in txt.split("\n"):
		if line.begins_with(";"):
			continue
		if line.begins_with("@"):
			if not cur.is_empty():
				_finish(cur, rows, out)
			cur = _parse_header(line, world)
			rows = []
		elif not cur.is_empty() and line.strip_edges() != "":
			var row := line.strip_edges().replace("|", "")
			if row.begins_with("+"):
				# "+N": ripete N volte la riga precedente
				for i in range(maxi(1, int(row.substr(1)))):
					rows.append(rows[rows.size() - 1])
			else:
				rows.append(row)
	if not cur.is_empty():
		_finish(cur, rows, out)
	return out


static func _parse_header(line: String, world: int) -> Dictionary:
	var parts := line.substr(1).strip_edges().split(" ", false)
	var c := {"id": parts[0], "world": world, "d": 1, "req": [], "tags": [], "noflip": false, "hints": []}
	for i in range(1, parts.size()):
		var p: String = parts[i]
		if p == "noflip":
			c["noflip"] = true
		elif p.begins_with("d="):
			c["d"] = int(p.substr(2))
		elif p.begins_with("req="):
			c["req"] = Array(p.substr(4).split(",", false))
		elif p.begins_with("tags="):
			c["tags"] = Array(p.substr(5).split(",", false))
		elif p.begins_with("hints="):
			c["hints"] = Array(p.substr(6).split(",", false))
	return c


static func _finish(c: Dictionary, rows: Array, out: Array) -> void:
	if rows.is_empty():
		return
	var width := 0
	for r in rows:
		width = maxi(width, r.length())
	for r in rows:
		if r.length() != width:
			errors.append("%s: riga di %d caratteri invece di %d: %s" % [c["id"], r.length(), width, r])
	var height := G.ROWS if rows.size() <= G.ROWS else maxi(rows.size(), G.ROWS * 2)
	var grid: Array = []
	for i in range(height - rows.size()):
		grid.append(".".repeat(width))
	for r in rows:
		grid.append(r + ".".repeat(width - r.length()))
	c["rows"] = grid
	c["w"] = width
	c["h"] = height
	c["qin"] = _quote(grid, 0)
	c["qout"] = _quote(grid, width - 1)
	c["has_secret"] = false
	for r in grid:
		if "S" in r:
			c["has_secret"] = true
	out.append(c)


## Quota del suolo di una colonna: L (riga 3 dal basso), M (6) o H (9); "" se non standard.
static func _quote(grid: Array, col: int) -> String:
	var n := grid.size()
	for i in range(n):
		if grid[i][col] == "#":
			return QUOTES.get(n - i, "")
	return ""


## Scrive il blocco nel livello a partire dalla colonna x0 (allineato in basso).
## Ritorna i marcatori trovati: [{"c": carattere, "x": col, "y": riga}].
static func stamp(lv, c: Dictionary, x0: int, flip: bool) -> Array:
	var marks: Array = []
	var rows: Array = c["rows"]
	var cw: int = c["w"]
	var y0: int = lv.h - rows.size()
	for ry in range(rows.size()):
		var row: String = rows[ry]
		for rx in range(cw):
			var ch := row[cw - 1 - rx] if flip else row[rx]
			if ch == "." or ch == " ":
				continue
			var tx := x0 + rx
			var ty := y0 + ry
			if TILE_CHARS.has(ch):
				lv.set_tile(tx, ty, TILE_CHARS[ch])
			else:
				marks.append({"c": ch, "x": tx, "y": ty})
	return marks
