extends RefCounted
## Validatore di giocabilità (GDD, "Specifiche dei blocchi").
##
## Costruisce un grafo di raggiungibilità sulle celle calpestabili. Gli archi non sono
## stimati "a occhio": ogni salto è una traiettoria simulata con la stessa fisica del
## protagonista (Phys.gd) nello spazio vuoto, e poi confrontata con la griglia reale.
## Se una traiettoria passa, il giocatore può rifarla tenendo premuti gli stessi tasti:
## il validatore è prudente (può scartare un blocco giocabile, mai accettarne uno rotto).
##
## I risultati per blocco sono messi in cache (data/chunk_valid.json, rigenerato dai test),
## così a una nuova partita la validazione dei 90 livelli è immediata.

const Phys = preload("res://src/game/Phys.gd")
const LevelData = preload("res://src/gen/LevelData.gd")
const ChunkLib = preload("res://src/gen/ChunkLib.gd")

const DT := 1.0 / 60.0
const PAD := 4
const CACHE_PATH := "res://data/chunk_valid.json"

static var _tpl := {}
static var _table := {}
static var _table_loaded := false
static var table_dirty := false


class OpenSpace:
	var platforms: Array = []
	var floor_on := true

	func tile(tx: int, ty: int) -> int:
		return G.T_SOLID if (floor_on and tx == 0 and ty == 1) else G.T_EMPTY

	func solid(tx: int, ty: int) -> bool:
		return floor_on and tx == 0 and ty == 1

	func break_crate(_tx: int, _ty: int) -> void:
		pass


# ---------------------------------------------------------------- contesto

static func ctx_for(world: int) -> Dictionary:
	var ab := G.abilities_for(world)
	var act := {}
	for a in ab["actives"]:
		act[a] = true
	return {"world": world, "h": G.STAGE_H[G.stage_of(world)], "double": ab["double"], "glide": ab["glide"], "act": act}


# ---------------------------------------------------------------- traiettorie

static func _spec(d: Dictionary) -> Dictionary:
	var s := {"dir": 0, "delay": 0, "steer": 9999, "hold": 9999, "jump": true, "dj": -1, "dash": -1, "bub": [], "vy0": 0.0, "air": false}
	s.merge(d, true)
	return s


static func _templates(ctx: Dictionary) -> Dictionary:
	var key: int = ctx["world"]
	if _tpl.has(key):
		return _tpl[key]
	var act: Dictionary = ctx["act"]
	var jump: Array = []
	var bounce: Array = []
	var sbounce: Array = []
	var updraft: Array = []
	for d in [-1, 1]:
		jump.append(_spec({"dir": d, "jump": false}))
		jump.append(_spec({"dir": d, "jump": false, "steer": 14}))
		for delay in [0, 6, 12, 18]:
			for hold in [9999, 5]:
				for steer in [9999, 10, 22]:
					jump.append(_spec({"dir": d, "delay": delay, "hold": hold, "steer": steer}))
		if ctx["double"]:
			for delay in [0, 12]:
				for dj in [22, 36]:
					for steer in [9999, 24, 44]:
						jump.append(_spec({"dir": d, "delay": delay, "dj": dj, "steer": steer}))
			jump.append(_spec({"dir": d, "delay": 30, "dj": 22}))
			jump.append(_spec({"dir": d, "delay": 42, "dj": 22}))
		if ctx["glide"]:
			for delay in [0, 12]:
				jump.append(_spec({"dir": d, "delay": delay, "hold": 30}))
				for steer in [40, 80, 140]:
					jump.append(_spec({"dir": d, "delay": delay, "steer": steer}))
		if act.has("scatto"):
			for delay in [0, 12]:
				jump.append(_spec({"dir": d, "delay": delay, "dash": 22}))
			if ctx["double"]:
				jump.append(_spec({"dir": d, "dj": 22, "dash": 46}))
		if act.has("bolla"):
			for blen in [60, 120, 178]:
				for delay in [0, 30, 70]:
					jump.append(_spec({"dir": d, "delay": delay, "bub": [20, blen]}))
			jump.append(_spec({"dir": d, "delay": 0, "bub": [20, 178], "dj": 204}))
			for delay in [110, 150]:
				jump.append(_spec({"dir": d, "delay": delay, "bub": [20, 178]}))
		for delay in [0, 10]:
			bounce.append(_spec({"dir": d, "delay": delay, "vy0": -G.BOUNCE_V, "hold": 0, "jump": false}))
			bounce.append(_spec({"dir": d, "delay": delay, "vy0": -G.BOUNCE_HELD_V, "jump": false}))
		for delay in [0, 15, 30]:
			sbounce.append(_spec({"dir": d, "delay": delay, "vy0": -G.SLAM_BOUNCE, "jump": false}))
		updraft.append(_spec({"dir": d, "air": true, "vy0": -G.UPDRAFT_V, "jump": false}))
		updraft.append(_spec({"dir": d, "air": true, "vy0": -G.UPDRAFT_V, "jump": false, "steer": 40}))
	jump.append(_spec({}))
	jump.append(_spec({"hold": 5}))
	if ctx["double"]:
		jump.append(_spec({"dj": 22}))
	if act.has("bolla"):
		for blen in [60, 120, 178]:
			jump.append(_spec({"bub": [20, blen]}))
	bounce.append(_spec({"vy0": -G.BOUNCE_HELD_V, "jump": false}))
	sbounce.append(_spec({"vy0": -G.SLAM_BOUNCE, "jump": false}))
	updraft.append(_spec({"air": true, "vy0": -G.UPDRAFT_V, "jump": false}))
	var out := {"jump": [], "bounce": [], "sbounce": [], "updraft": []}
	for s in jump:
		out["jump"].append(_sim(s, ctx))
	for s in bounce:
		out["bounce"].append(_sim(s, ctx))
	if act.has("schianto"):
		for s in sbounce:
			out["sbounce"].append(_sim(s, ctx))
	if ctx["glide"]:
		for s in updraft:
			out["updraft"].append(_sim(s, ctx))
	_tpl[key] = out
	return out


## Simula una traiettoria nello spazio vuoto e registra le celle attraversate
## e i punti in cui i piedi oltrepassano il bordo di una riga (possibili atterraggi).
static func _sim(s: Dictionary, ctx: Dictionary) -> Dictionary:
	var sp := OpenSpace.new()
	var b := Phys.new()
	b.full_h = ctx["h"]
	b.hh = b.full_h * 0.5
	b.has_double = ctx["double"]
	b.has_glide = ctx["glide"]
	b.x = 8.0
	b.y = 16.0 - b.hh
	b.on_ground = true
	if s["air"]:
		sp.floor_on = false
		b.on_ground = false
		b.y = 8.0
		b.vy = s["vy0"]
	elif s["vy0"] != 0.0:
		b.on_ground = false
		b.vy = s["vy0"]
	var sx := PackedInt32Array()
	var sy := PackedInt32Array()
	var cross: Array = []
	var seen := {}
	for cx in range(int(floor((b.x - b.hw) / 16.0)), int(floor((b.x + b.hw - 0.01) / 16.0)) + 1):
		for cy in range(int(floor((b.y - b.hh) / 16.0)), int(floor((b.y + b.hh - 0.01) / 16.0)) + 1):
			seen[Vector2i(cx, cy)] = true
	var bub: Array = s["bub"]
	for t in range(480):
		var st: int = t - s["delay"]
		var inp := {}
		inp["mx"] = float(s["dir"]) if (st >= 0 and st < s["steer"]) else 0.0
		inp["jp"] = (s["jump"] and t == 0) or t == s["dj"] or (bub.size() > 0 and t == bub[0] + bub[1])
		inp["jh"] = t < s["hold"] or (s["dj"] >= 0 and t >= s["dj"])
		if t == s["dash"]:
			inp["ab"] = "scatto"
			inp["abx"] = float(s["dir"])
		elif bub.size() > 0 and t == bub[0]:
			inp["ab"] = "bolla"
		var prev_row := int(floor((b.y + b.hh - 0.01) / 16.0))
		b.step(inp, DT, sp)
		if b.on_ground and t > 1:
			break
		var l := int(floor((b.x - b.hw) / 16.0))
		var r := int(floor((b.x + b.hw - 0.01) / 16.0))
		var top := int(floor((b.y - b.hh) / 16.0))
		var bot := int(floor((b.y + b.hh - 0.01) / 16.0))
		var crossed := bot > prev_row
		for pass_i in range(2):
			for cy in range(top, bot + 1):
				if crossed and ((pass_i == 0) == (cy >= bot)):
					continue
				if not crossed and pass_i == 1:
					continue
				for cx in range(l, r + 1):
					var c := Vector2i(cx, cy)
					if not seen.has(c):
						seen[c] = true
						sx.append(cx)
						sy.append(cy)
			if crossed and pass_i == 0:
				cross.append([sx.size(), bot, l, r])
		if bot > 24 or absf(b.x) > 16.0 * 26.0:
			break
	return {"sx": sx, "sy": sy, "cross": cross, "glide": ctx["glide"] and s["hold"] > 100}


# ---------------------------------------------------------------- grafo

class Search:
	var lv
	var ctx: Dictionary
	var tpl: Dictionary
	var overlay := {}  # cella -> id piattaforma mobile (trattata come passante)
	var rides := {}  # id -> celle di appoggio
	var visited := {}
	var queue: Array = []
	var slam := false
	var dash := false
	var grav := false

	func blocked(tx: int, ty: int) -> bool:
		var t: int = lv.tile(tx, ty)
		return t == G.T_SOLID or t == G.T_CRATE or t == G.T_BOUNCY or t == G.T_DOOR or t == G.T_SPIKE or t == G.T_SPIKE_D

	func floor_ok(tx: int, ty: int, g: int) -> bool:
		var t: int = lv.tile(tx, ty)
		if t == G.T_SOLID or t == G.T_CRATE or t == G.T_BOUNCY or t == G.T_DOOR:
			return true
		return g == 1 and (t == G.T_ONEWAY or overlay.has(Vector2i(tx, ty)))

	func push(cx: int, cy: int, g: int, crouch: bool) -> void:
		if cx < 0 or cx >= lv.w or cy < -3 or cy > lv.h:
			return
		var k := Vector4i(cx, cy, g, 1 if crouch else 0)
		if not visited.has(k):
			visited[k] = true
			queue.append(k)

	func push_updraft(cx: int, cy: int) -> void:
		while lv.tile(cx, cy - 1) == G.T_UPDRAFT:
			cy -= 1
		var k := Vector4i(cx, cy, 0, 2)
		if not visited.has(k):
			visited[k] = true
			queue.append(k)

	func run(start: Vector2i) -> void:
		push(start.x, start.y, 1, false)
		while not queue.is_empty():
			var k: Vector4i = queue.pop_back()
			if k.w == 2:
				for tp in tpl["updraft"]:
					fly(tp, k.x, k.y, 1)
			else:
				expand(k.x, k.y, k.z, k.w == 1)

	func expand(cx: int, cy: int, g: int, crouch: bool) -> void:
		# camminata
		for d in [-1, 1]:
			var nx: int = cx + d
			if blocked(nx, cy) or not floor_ok(nx, cy + g, g):
				continue
			if not blocked(nx, cy - g):
				push(nx, cy, g, false)
			elif dash or crouch:
				push(nx, cy, g, true)
		if crouch:
			return
		var ft: int = lv.tile(cx, cy + g)
		if ft == G.T_BOUNCY:
			for tp in tpl["bounce"]:
				fly(tp, cx, cy, g)
			for tp in tpl["sbounce"]:
				fly(tp, cx, cy, g)
		else:
			for tp in tpl["jump"]:
				fly(tp, cx, cy, g)
		if ft == G.T_CRATE and slam:
			var ty := cy + g
			while ty >= 0 and ty < lv.h:
				var t: int = lv.tile(cx, ty)
				if t == G.T_ONEWAY and g == 1:
					break
				if t == G.T_CRATE or not blocked(cx, ty):
					ty += g
				else:
					break
			if ty >= 0 and ty < lv.h and floor_ok(cx, ty, g):
				push(cx, ty - g, g, false)
		if lv.tile(cx, cy) == G.T_UPDRAFT and ctx["glide"]:
			push_updraft(cx, cy)
		var ov = overlay.get(Vector2i(cx, cy + 1))
		if ov != null and g == 1:
			for c in rides[ov]:
				if not blocked(c.x, c.y - 1):
					push(c.x, c.y - 1, 1, false)
		if grav:
			flips(cx, cy, g)

	## Segue una traiettoria precalcolata partendo dalla cella (ax, ay).
	func fly(tp: Dictionary, ax: int, ay: int, g: int) -> void:
		var sx: PackedInt32Array = tp["sx"]
		var sy: PackedInt32Array = tp["sy"]
		var glide: bool = tp["glide"]
		var i := 0
		for cr in tp["cross"]:
			var n: int = cr[0]
			while i < n:
				var cx := ax + sx[i]
				var cy := ay + sy[i] * g
				var t: int = lv.tile(cx, cy)
				if t != G.T_EMPTY and t != G.T_ONEWAY and t != G.T_FAKE:
					if t == G.T_UPDRAFT:
						if glide and g == 1:
							push_updraft(cx, cy)
					else:
						return
				i += 1
			var fr: int = ay + cr[1] * g
			var landed := false
			for c in range(cr[2], cr[3] + 1):
				if floor_ok(ax + c, fr, g) and not blocked(ax + c, fr - g):
					push(ax + c, fr - g, g, false)
					landed = true
			if landed:
				return

	## Inversione della gravità: simulata direttamente sulla griglia reale.
	func flips(cx: int, cy: int, g: int) -> void:
		for pre in [0, 20]:
			for steer in [0, -1, 1]:
				var b := Phys.new()
				b.full_h = ctx["h"]
				b.hh = b.full_h * 0.5
				b.g = g
				b.has_double = ctx["double"]
				b.set_feet(cx * 16.0 + 8.0, (cy + 1) * 16.0 if g == 1 else cy * 16.0)
				b.on_ground = true
				var ok := true
				for t in range(240):
					var inp := {"mx": float(steer) if t >= pre else 0.0, "jp": pre > 0 and t == 0, "jh": true}
					if t == pre:
						inp["ab"] = "gravita"
					b.step(inp, DT, lv)
					if b.y < -48.0 or b.y > lv.h * 16.0 + 48.0:
						ok = false
						break
					if _touches_spike(b):
						ok = false
						break
					if b.on_ground and t > pre:
						break
				if ok and b.on_ground and b.g != g:
					var ry := int(floor((b.feet() - b.g) / 16.0))
					var rx := int(floor(b.x / 16.0))
					if not floor_ok(rx, ry + b.g, b.g):
						rx = int(floor((b.x - b.hw) / 16.0))
						if not floor_ok(rx, ry + b.g, b.g):
							rx = int(floor((b.x + b.hw - 0.01) / 16.0))
					if floor_ok(rx, ry + b.g, b.g) and not blocked(rx, ry):
						push(rx, ry, b.g, false)

	func _touches_spike(b) -> bool:
		for tx in range(int(floor((b.x - b.hw) / 16.0)), int(floor((b.x + b.hw - 0.01) / 16.0)) + 1):
			for ty in range(int(floor((b.y - b.hh) / 16.0)), int(floor((b.y + b.hh - 0.01) / 16.0)) + 1):
				var t: int = lv.tile(tx, ty)
				if t == G.T_SPIKE or t == G.T_SPIKE_D:
					return true
		return false

	func stands_near(p: Vector2i, rad: int) -> bool:
		for k in visited:
			if k.w != 2 and absi(k.x - p.x) <= rad and absi(k.y - p.y) <= rad:
				return true
		return false


## Verifica un livello (o un blocco isolato). marks: marcatori di ChunkLib.stamp.
## Ritorna {"ok": uscita raggiungibile, "secret": tutti i segreti raggiungibili}.
static func check(lv, ctx: Dictionary, marks: Array, start: Vector2i, exit_from: int) -> Dictionary:
	var work = LevelData.new()
	work.w = lv.w
	work.h = lv.h
	work.cells = lv.cells.duplicate()
	var secrets: Array = []
	var switches: Array = []
	var s := Search.new()
	s.lv = work
	s.ctx = ctx
	s.tpl = _templates(ctx)
	s.slam = ctx["act"].has("schianto")
	s.dash = ctx["act"].has("scatto")
	s.grav = ctx["act"].has("gravita")
	var mid := 0
	for m in marks:
		var p := Vector2i(m["x"], m["y"])
		match m["c"]:
			"S":
				secrets.append(p)
			"T":
				switches.append([p, int(m.get("x0", 0)), int(m.get("x1", lv.w))])
			"H":
				mid += 1
				s.rides[mid] = []
				for tx in range(p.x - 3, p.x + 5):
					if not s.blocked(tx, p.y):
						s.overlay[Vector2i(tx, p.y)] = mid
						s.rides[mid].append(Vector2i(tx, p.y))
			"V":
				mid += 1
				s.rides[mid] = []
				for ty in range(p.y - 3, p.y + 4):
					for tx in [p.x, p.x + 1]:
						if not s.blocked(tx, ty):
							s.overlay[Vector2i(tx, ty)] = mid
							s.rides[mid].append(Vector2i(tx, ty))
	var res := {"ok": false, "secret": true}
	for round_i in range(12):
		s.visited = {}
		s.queue = []
		s.run(start)
		var opened := false
		if ctx["act"].has("riflesso"):
			# le porte di un blocco si aprono se tutti i suoi interruttori sono raggiungibili
			var groups := {}
			for sw in switches:
				if not groups.has(sw[1]):
					groups[sw[1]] = [true, sw[2]]
				if not s.stands_near(sw[0], 0):
					groups[sw[1]][0] = false
			for x0 in groups:
				if not groups[x0][0]:
					continue
				for tx in range(x0, groups[x0][1]):
					for ty in range(work.h):
						if work.tile(tx, ty) == G.T_DOOR:
							work.set_tile(tx, ty, G.T_EMPTY)
							opened = true
		if not opened:
			break
	for k in s.visited:
		if k.w == 0 and k.z == 1 and k.x >= exit_from:
			res["ok"] = true
			break
	for sec in secrets:
		if not s.stands_near(sec, 1):
			res["secret"] = false
	res["nodes"] = s.visited.size()
	return res


## Valida un blocco isolato, con due pianerottoli piatti ai lati.
static func check_chunk(c: Dictionary, flip: bool, world: int) -> Dictionary:
	var lv = LevelData.new()
	lv.init(c["w"] + PAD * 2, c["h"])
	var qin: String = c["qout"] if flip else c["qin"]
	var qout: String = c["qin"] if flip else c["qout"]
	if qin == "" or qout == "":
		return {"ok": false, "secret": false, "err": "raccordo non standard"}
	for i in range(PAD):
		for ty in range(lv.h - ChunkLib.QUOTE_ROWS[qin], lv.h):
			lv.set_tile(i, ty, G.T_SOLID)
		for ty in range(lv.h - ChunkLib.QUOTE_ROWS[qout], lv.h):
			lv.set_tile(lv.w - 1 - i, ty, G.T_SOLID)
	var marks := ChunkLib.stamp(lv, c, PAD, flip)
	var start := Vector2i(1, lv.h - ChunkLib.QUOTE_ROWS[qin] - 1)
	return check(lv, ctx_for(world), marks, start, lv.w - 2)


## Valida un livello completo (usato per i livelli fatti a mano e nei test).
static func check_level(lv) -> Dictionary:
	var marks: Array = []
	for e in lv.ents:
		match e["t"]:
			"secret":
				marks.append({"c": "S", "x": e["x"], "y": e["y"]})
			"switch":
				marks.append({"c": "T", "x": e["x"], "y": e["y"], "x0": e["x0"], "x1": e["x1"]})
			"mover":
				marks.append({"c": "H" if e["axis"] == "h" else "V", "x": e["x"], "y": e["y"]})
	return check(lv, ctx_for(lv.world), marks, lv.start, lv.exit_x - 1)


static func _sig(c: Dictionary) -> int:
	return "\n".join(PackedStringArray(c["rows"])).hash()


## Esito (in cache) della validazione di un blocco in un certo mondo.
static func chunk_ok(c: Dictionary, flip: bool, world: int) -> Dictionary:
	if not _table_loaded:
		_table_loaded = true
		if FileAccess.file_exists(CACHE_PATH):
			var d = JSON.parse_string(FileAccess.get_file_as_string(CACHE_PATH))
			if d is Dictionary:
				_table = d
	var key := "%s|%d|%d" % [c["id"], 1 if flip else 0, world]
	var sig := _sig(c)
	var e = _table.get(key)
	if e is Array and e.size() == 3 and int(e[0]) == sig:
		return {"ok": bool(e[1]), "secret": bool(e[2])}
	var r := check_chunk(c, flip, world)
	_table[key] = [sig, r["ok"], r["secret"]]
	table_dirty = true
	return r


static func save_table() -> void:
	var f := FileAccess.open(CACHE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_table, "", true))
		f.close()
	table_dirty = false
