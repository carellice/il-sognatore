extends RefCounted
## Generatore procedurale: assembla i blocchi di ChunkLib in un livello, in modo
## completamente deterministico a partire da (seed, mondo, livello).
## Si salva solo il seed: ogni livello si ricostruisce identico a ogni caricamento.

const ChunkLib = preload("res://src/gen/ChunkLib.gd")
const LevelData = preload("res://src/gen/LevelData.gd")
const Validator = preload("res://src/gen/Validator.gd")
const EnemyDefs = preload("res://src/game/EnemyDefs.gd")

const START_W := 10
const END_W := 12
const MAX_ATTEMPTS := 8

static var _pools := {}


static func rng_for(seed: int, world: int, level: int, attempt: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	var s: int = (seed * 73856093) ^ (world * 19349663) ^ (level * 83492791) ^ (attempt * 2654435761)
	r.seed = s & 0x7FFFFFFFFFFF
	return r


static func new_seed() -> int:
	return randi_range(100000, 999999999)


static func _req_ok(req: Array, ab: Dictionary) -> bool:
	for r in req:
		if r == "doppio_salto":
			if not ab["double"]:
				return false
		elif r == "planata":
			if not ab["glide"]:
				return false
		elif not (r in ab["actives"]):
			return false
	return true


## Varianti di blocco utilizzabili in un mondo (già validate, anche specchiate).
static func pool_for(world: int) -> Array:
	if _pools.has(world):
		return _pools[world]
	var ab := G.abilities_for(world)
	var out: Array = []
	for cw in range(1, world + 1):
		for c in ChunkLib.chunks_of(cw):
			if not _req_ok(c["req"], ab):
				continue
			var eff: float = minf(10.0, c["d"] + (world - cw) * 0.75)
			for flip in [false, true]:
				if flip and c["noflip"]:
					continue
				var v := Validator.chunk_ok(c, flip, world)
				if not v["ok"]:
					continue
				out.append({
					"c": c, "flip": flip, "eff": eff, "own": cw == world,
					"qin": c["qout"] if flip else c["qin"],
					"qout": c["qin"] if flip else c["qout"],
					"secret": c["has_secret"] and v["secret"],
				})
	_pools[world] = out
	return out


static func screens_for(world: int, level: int) -> int:
	var b: Dictionary = G.band(world)
	return int(round(lerpf(b["len"][0], b["len"][1], (level - 1) / maxf(1.0, G.LEVELS - 2.0))))


## Sceglie la sequenza di blocchi di un livello (regole di assemblaggio del GDD).
## usage: quante volte ogni blocco è già comparso nei livelli precedenti del mondo.
static func plan_level(seed: int, world: int, level: int, attempt: int, usage: Dictionary) -> Dictionary:
	var rng := rng_for(seed, world, level, attempt)
	var d := G.difficulty(world, level)
	var dr := int(round(d))
	var target := screens_for(world, level) * G.SCREEN_COLS
	var pool := pool_for(world)
	var seq: Array = []
	var used := {}
	var q := "M"
	var cols := 0
	var plus_used := false
	var prev_plus := false
	var has_secret := false
	var intro := {}
	if level == 1 and world >= 2:
		intro = ChunkLib.handmade("intro_%d" % world)
		if not intro.is_empty():
			q = intro["qout"]
			cols += intro["w"]
	var guard := 0
	while cols < target and guard < 64:
		guard += 1
		var remaining := target - cols
		var cands: Array = []
		var weights: Array = []
		for relax in range(4):
			var need_secret := not has_secret and remaining <= 75 and relax == 0
			for v in pool:
				var id: String = v["c"]["id"]
				if used.has(id) and relax < 3:
					continue
				var eff: float = v["eff"]
				if eff < dr - 2 - relax * 2 or eff > dr + 1 + relax:
					continue
				var plus := eff >= dr + 0.6
				if plus and (plus_used or prev_plus) and relax == 0:
					continue
				if need_secret and not v["secret"]:
					continue
				var wgt := 1.0
				if v["own"]:
					wgt *= 3.0
				if v["qin"] == q:
					wgt *= 4.0
				var u: int = usage.get(id, 0)
				wgt *= 0.05 if u >= 3 else 1.0 / (1.0 + u)
				wgt /= 1.0 + absf(eff - d)
				if v["c"]["w"] > remaining + 15:
					wgt *= 0.3
				cands.append(v)
				weights.append(wgt)
			if not cands.is_empty():
				break
		if cands.is_empty():
			break
		var pick: Dictionary = cands[_weighted(rng, weights)]
		seq.append(pick)
		used[pick["c"]["id"]] = true
		cols += pick["c"]["w"]
		q = pick["qout"]
		prev_plus = pick["eff"] >= dr + 0.6
		plus_used = plus_used or prev_plus
		has_secret = has_secret or pick["secret"]
	for id in used:
		usage[id] = usage.get(id, 0) + 1
	return {"seq": seq, "intro": intro, "rng": rng, "d": d}


static func _weighted(rng: RandomNumberGenerator, weights: Array) -> int:
	var tot := 0.0
	for w in weights:
		tot += w
	var r := rng.randf() * tot
	for i in range(weights.size()):
		r -= weights[i]
		if r <= 0.0:
			return i
	return weights.size() - 1


## Costruisce il livello. opts: {"skip_tut": bool, "attempts": {"m-l": n}, "mode": String}
static func build(seed: int, world: int, level: int, opts := {}) -> LevelData:
	if level == G.LEVELS:
		return _handmade("boss_%d" % world, seed, world, level)
	if world == 1 and level == 1 and not opts.get("skip_tut", false):
		return _handmade("tutorial", seed, world, level)
	var attempts: Dictionary = opts.get("attempts", {})
	var usage := {}
	var plan := {}
	for l in range(1, level + 1):
		if world == 1 and l == 1 and not opts.get("skip_tut", false):
			continue
		plan = plan_level(seed, world, l, int(attempts.get(G.key(world, l), 0)), usage)
	return _assemble(plan, world, level)


## Genera tutti i livelli di una partita, rigenerando con un sotto-seed quelli
## che non superano i controlli. Ritorna i tentativi diversi da zero.
static func prepare(seed: int, skip_tut: bool, progress := Callable()) -> Dictionary:
	var attempts := {}
	var n := 0
	for world in range(1, 11):
		for level in range(1, G.LEVELS):
			var k := G.key(world, level)
			for a in range(MAX_ATTEMPTS):
				if a > 0:
					attempts[k] = a
				var lv := build(seed, world, level, {"skip_tut": skip_tut, "attempts": attempts})
				if sane(lv):
					break
			n += 1
			if progress.is_valid():
				progress.call(n, 10 * (G.LEVELS - 1))
	return attempts


static func sane(lv: LevelData) -> bool:
	var portal := false
	var secret := false
	for e in lv.ents:
		if e["t"] == "portal":
			portal = true
		elif e["t"] == "secret":
			secret = true
	return portal and secret and lv.w > 40


static func _flat(lv: LevelData, x0: int, width: int, q: String) -> void:
	for tx in range(x0, x0 + width):
		for ty in range(lv.h - ChunkLib.QUOTE_ROWS[q], lv.h):
			lv.set_tile(tx, ty, G.T_SOLID)


static func _ramp_w(a: String, b: String) -> int:
	return absi(ChunkLib.QUOTE_ROWS[a] - ChunkLib.QUOTE_ROWS[b]) * 2 + 2


## Rampa a gradini tra due quote diverse.
static func _ramp(lv: LevelData, x0: int, a: String, b: String) -> void:
	var ha: int = ChunkLib.QUOTE_ROWS[a]
	var hb: int = ChunkLib.QUOTE_ROWS[b]
	var width := _ramp_w(a, b)
	for i in range(width):
		var hgt := ha + signi(hb - ha) * mini(absi(hb - ha), i / 2)
		for ty in range(lv.h - hgt, lv.h):
			lv.set_tile(x0 + i, ty, G.T_SOLID)


static func _assemble(plan: Dictionary, world: int, level: int) -> LevelData:
	var rng: RandomNumberGenerator = plan["rng"]
	var seq: Array = plan["seq"]
	var intro: Dictionary = plan["intro"]
	var lv := LevelData.new()
	lv.world = world
	lv.level = level
	# prima passata: larghezza e altezza
	var total := START_W + END_W
	var tall := false
	var q := "M"
	if not intro.is_empty():
		total += intro["w"]
		q = intro["qout"]
		tall = tall or intro["h"] > G.ROWS
	for v in seq:
		if v["qin"] != q:
			total += _ramp_w(q, v["qin"])
		total += v["c"]["w"]
		q = v["qout"]
		tall = tall or v["c"]["h"] > G.ROWS
	lv.init(total, G.ROWS * 2 if tall else G.ROWS)
	# seconda passata: scrittura
	var x := 0
	q = "M" if intro.is_empty() else intro["qin"]
	if q == "":
		q = "M"
	_flat(lv, 0, START_W, q)
	lv.start = Vector2i(2, lv.h - ChunkLib.QUOTE_ROWS[q] - 1)
	x = START_W
	var marks: Array = []
	if not intro.is_empty():
		for m in ChunkLib.stamp(lv, intro, x, false):
			m["fixed"] = true
			marks.append(m)
		lv.hints = intro["hints"]
		lv.spans.append([x, x + intro["w"], intro["id"]])
		x += intro["w"]
		q = intro["qout"]
	var b: Dictionary = G.band(world)
	var cp_every: float = b["cp"]
	var since: float = 0.0 if intro.is_empty() else intro["w"] / float(G.SCREEN_COLS)
	var cp_n := 0
	for v in seq:
		if v["qin"] != q:
			_ramp(lv, x, q, v["qin"])
			x += _ramp_w(q, v["qin"])
			q = v["qin"]
		if since >= cp_every - 0.01 or (cp_n == 0 and not intro.is_empty()):
			cp_n += 1
			lv.ents.append({"t": "cp", "x": x + 1, "y": lv.h - ChunkLib.QUOTE_ROWS[q] - 1, "idx": cp_n})
			since = 0.0
		var cw: int = v["c"]["w"]
		for m in ChunkLib.stamp(lv, v["c"], x, v["flip"]):
			m["x0"] = x
			m["x1"] = x + cw
			m["secret_ok"] = v["secret"]
			marks.append(m)
		lv.spans.append([x, x + cw, v["c"]["id"]])
		x += cw
		since += cw / float(G.SCREEN_COLS)
		q = v["qout"]
	_flat(lv, x, END_W, q)
	lv.exit_x = x + END_W - 4
	lv.ents.append({"t": "portal", "x": lv.exit_x, "y": lv.h - ChunkLib.QUOTE_ROWS[q] - 1})
	var screens := maxf(1.0, (total - START_W - END_W) / float(G.SCREEN_COLS))
	var dens: float = lerpf(b["en"][0], b["en"][1], (level - 1) / maxf(1.0, G.LEVELS - 2.0))
	_place(lv, marks, rng, int(round(dens * screens)), true)
	return lv


static func _handmade(id: String, seed: int, world: int, level: int) -> LevelData:
	var c := ChunkLib.handmade(id)
	var lv := LevelData.new()
	lv.world = world
	lv.level = level
	lv.boss = level == G.LEVELS
	lv.tutorial = id == "tutorial"
	if c.is_empty():
		lv.init(30, G.ROWS)
		_flat(lv, 0, 30, "L")
		lv.start = Vector2i(2, lv.h - 4)
		lv.ents.append({"t": "portal", "x": 26, "y": lv.h - 4})
		lv.ents.append({"t": "secret", "x": 14, "y": lv.h - 6})
		return lv
	lv.init(c["w"], c["h"])
	var marks := ChunkLib.stamp(lv, c, 0, false)
	for m in marks:
		m["fixed"] = true
	lv.hints = c["hints"]
	lv.spans.append([0, c["w"], id])
	_place(lv, marks, rng_for(seed, world, level, 0), 999, false)
	return lv


## Trasforma i marcatori dei blocchi in entità, riempiendo gli slot.
static func _place(lv: LevelData, marks: Array, rng: RandomNumberGenerator, enemy_target: int, generated: bool) -> void:
	var kinds := G.enemies_for(lv.world, lv.level)
	var all_kinds: Array = G.WORLDS[lv.world - 1]["enemies"]
	var secrets: Array = []
	var slots: Array = []
	var frags: Array = []
	var cp_n := 100
	for m in marks:
		var ch: String = m["c"]
		var x: int = m["x"]
		var y: int = m["y"]
		match ch:
			"o":
				frags.append(m)
				lv.ents.append({"t": "frag", "x": x, "y": y})
			"S":
				if m.get("fixed", false) or m.get("secret_ok", false):
					secrets.append(m)
				else:
					lv.ents.append({"t": "frag", "x": x, "y": y})
			"L":
				if m.get("fixed", false) or rng.randf() < 0.3:
					lv.ents.append({"t": "life", "x": x, "y": y})
				else:
					lv.ents.append({"t": "frag", "x": x, "y": y})
			"E", "F":
				slots.append(m)
			"a", "b", "c":
				var idx := mini(ch.unicode_at(0) - 97, kinds.size() - 1)
				if m.get("fixed", false):
					idx = ch.unicode_at(0) - 97
				_add_enemy(lv, all_kinds[idx], x, y, rng)
			"T":
				lv.ents.append({"t": "switch", "x": x, "y": y, "x0": m.get("x0", 0), "x1": m.get("x1", lv.w)})
			"H":
				lv.ents.append({"t": "mover", "x": x, "y": y, "axis": "h"})
			"V":
				lv.ents.append({"t": "mover", "x": x, "y": y, "axis": "v"})
			"Z":
				lv.ents.append({"t": "blade", "x": x, "y": y, "axis": "h"})
			"N":
				lv.ents.append({"t": "blade", "x": x, "y": y, "axis": "v"})
			"K":
				cp_n += 1
				lv.ents.append({"t": "cp", "x": x, "y": y, "idx": cp_n})
			"Q":
				lv.ents.append({"t": "boss", "x": x, "y": y})
			"X":
				lv.exit_x = x
				lv.ents.append({"t": "portal", "x": x, "y": y})
			"P":
				lv.start = Vector2i(x, y)
			_:
				if ch >= "1" and ch <= "9":
					lv.ents.append({"t": "hint", "x": x, "y": y, "n": int(ch)})
	# un solo oggetto segreto per livello
	if not secrets.is_empty():
		var pick: int = rng.randi_range(0, secrets.size() - 1)
		for i in range(secrets.size()):
			var m: Dictionary = secrets[i]
			lv.ents.append({"t": "secret" if i == pick else "frag", "x": m["x"], "y": m["y"]})
	elif not frags.is_empty():
		var best: Dictionary = frags[0]
		for m in frags:
			if m["y"] < best["y"]:
				best = m
		lv.ents.append({"t": "secret", "x": best["x"], "y": best["y"] - 1})
	elif generated or not lv.boss:
		lv.ents.append({"t": "secret", "x": maxi(2, lv.exit_x - 4), "y": maxi(1, lv.ground_row(maxi(2, lv.exit_x - 4)) - 4)})
	# nemici negli slot
	for i in range(slots.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = slots[i]
		slots[i] = slots[j]
		slots[j] = tmp
	var placed := 0
	var counts := {}
	var want := enemy_target
	if generated:
		want = mini(enemy_target, int(round(lv.w / float(G.SCREEN_COLS) * 2.0)))
	var taken: Array = []
	for e in lv.ents:
		if e["t"] == "enemy":
			taken.append(int(e["x"]))
	for m in slots:
		if placed >= enemy_target:
			break
		if _fill_slot(lv, m, kinds, counts, want, rng):
			taken.append(int(m["x"]))
			placed += 1
	if not generated:
		return
	# i blocchi non hanno sempre abbastanza posti: se ne cercano altri sul terreno
	# piano e nell'aria sopra, lontano da partenza, checkpoint e altri nemici
	if placed >= want:
		return
	var keep_off: Array = []
	for e in lv.ents:
		if e["t"] in ["cp", "portal", "switch", "secret"]:
			keep_off.append(int(e["x"]))
	var extra: Array = _auto_slots(lv)
	for i in range(extra.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = extra[i]
		extra[i] = extra[j]
		extra[j] = tmp
	for m in extra:
		if placed >= want:
			break
		var ok := true
		for tx in taken:
			if absi(tx - int(m["x"])) < 6:
				ok = false
				break
		for tx in keep_off:
			if absi(tx - int(m["x"])) < 4:
				ok = false
				break
		if ok and _fill_slot(lv, m, kinds, counts, want, rng):
			taken.append(int(m["x"]))
			placed += 1


## Mette un nemico nello slot, variando i tipi: nessun tipo oltre il 60% del totale
## (30% per i pericoli invulnerabili come la raffica). Se a terra non c'è un tipo
## adatto, si prova con un nemico volante poco sopra.
static func _fill_slot(lv: LevelData, m: Dictionary, kinds: Array, counts: Dictionary, target: int, rng: RandomNumberGenerator) -> bool:
	var slot: String = m["c"]
	var x: int = m["x"]
	var y: int = m["y"]
	var opts: Array = _kinds_under_cap(kinds, slot, counts, target)
	if opts.is_empty() and slot == "E":
		var free := true
		for dy in range(1, 5):
			if lv.tile(x, y - dy) != G.T_EMPTY:
				free = false
		if free:
			slot = "F"
			y -= 3
			opts = _kinds_under_cap(kinds, slot, counts, target)
	if opts.is_empty():
		return false
	# il nemico più recente del mondo compare un po' più spesso
	var kind: String = opts[opts.size() - 1] if rng.randf() < 0.45 else opts[rng.randi_range(0, opts.size() - 1)]
	if not _add_enemy(lv, kind, x, y, rng, slot):
		return false
	counts[kind] = counts.get(kind, 0) + 1
	return true


static func _kinds_under_cap(kinds: Array, slot: String, counts: Dictionary, target: int) -> Array:
	var opts: Array = []
	for k in kinds:
		if not EnemyDefs.fits(k, slot):
			continue
		var share := 0.3 if EnemyDefs.DEFS[k].get("invuln", false) else 0.6
		if kinds.size() > 1 and counts.get(k, 0) >= maxi(1, int(ceil(target * share))):
			continue
		opts.append(k)
	return opts


## Posti aggiuntivi per i nemici: al centro di tratti piani larghi almeno 5 caselle
## (a terra) e nell'aria libera 4 caselle sopra.
static func _auto_slots(lv: LevelData) -> Array:
	var out: Array = []
	var tops: Array = []
	for tx in range(lv.w):
		var top := -1
		for ty in range(4, lv.h):
			if lv.tile(tx, ty) == G.T_SOLID and lv.tile(tx, ty - 1) == G.T_EMPTY and lv.tile(tx, ty - 2) == G.T_EMPTY and lv.tile(tx, ty - 3) == G.T_EMPTY:
				top = ty
				break
			if lv.tile(tx, ty) != G.T_EMPTY:
				break
		tops.append(top)
	for tx in range(START_W + 5, lv.w - END_W - 3):
		var top: int = tops[tx]
		if top < 0:
			continue
		var flat := true
		for dx in range(-2, 3):
			if tops[tx + dx] != top:
				flat = false
		if not flat:
			continue
		out.append({"c": "E", "x": tx, "y": top - 1})
		var open := top >= 8
		for dy in range(1, 7):
			for dx in range(-1, 2):
				if open and lv.tile(tx + dx, top - dy) != G.T_EMPTY:
					open = false
		if open:
			out.append({"c": "F", "x": tx, "y": top - 4})
	return out


static func _add_enemy(lv: LevelData, kind: String, x: int, y: int, rng: RandomNumberGenerator, slot := "") -> bool:
	var e := {"t": "enemy", "kind": kind, "x": x, "y": y}
	if kind == "ombra":
		var opts: Array = []
		for w in range(9):
			for k in G.WORLDS[w]["enemies"]:
				if slot == "" or EnemyDefs.fits(k, slot):
					opts.append(k)
		kind = opts[rng.randi_range(0, opts.size() - 1)]
		e["kind"] = kind
		e["shadow"] = true
	if EnemyDefs.DEFS[kind]["slot"] == "c":
		var ty := y
		while ty >= 0 and not lv.solid(x, ty):
			ty -= 1
		if ty < 0 or y - ty > 12:
			return false
		e["y"] = ty + 1
	lv.ents.append(e)
	return true
