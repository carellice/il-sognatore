extends RefCounted
## Test automatici (headless):  godot --headless --path . -- --test [--write]
## Controllano i blocchi (formato, raccordi, giocabilità) e il generatore
## (determinismo, livelli completi per più seed).

const ChunkLib = preload("res://src/gen/ChunkLib.gd")
const Validator = preload("res://src/gen/Validator.gd")
const LevelGen = preload("res://src/gen/LevelGen.gd")


static func run(write: bool, diag := false, levels := false) -> int:
	var fails := 0
	var t0 := Time.get_ticks_msec()
	print("== Blocchi ==")
	for world in range(1, 11):
		var chunks := ChunkLib.chunks_of(world)
		var ok_n := 0
		for c in chunks:
			var errs: Array = []
			if c["w"] != 30 and c["w"] != 60:
				errs.append("larghezza %d" % c["w"])
			if c["qin"] == "" or c["qout"] == "":
				errs.append("raccordo non standard (in=%s out=%s)" % [c["qin"], c["qout"]])
			else:
				errs.append_array(_flat_edges(c))
			var any := false
			for flip in [false, true]:
				if flip and c["noflip"]:
					continue
				var r := Validator.chunk_ok(c, flip, world)
				if r["ok"]:
					any = true
					if c["has_secret"] and not r["secret"]:
						errs.append("segreto non raggiungibile (flip=%s)" % flip)
				elif not flip:
					errs.append("non percorribile")
			if not any:
				errs.append("nessuna variante valida")
			if errs.is_empty():
				ok_n += 1
			else:
				fails += 1
				print("  ERRORE %s: %s" % [c["id"], ", ".join(PackedStringArray(errs))])
		var pool := LevelGen.pool_for(world)
		var sec := 0
		for v in pool:
			if v["secret"]:
				sec += 1
		print("  Mondo %d: %d/%d blocchi ok, %d varianti nel pool (%d con segreto)" % [world, ok_n, chunks.size(), pool.size(), sec])
	# i blocchi con "req" devono essere davvero impossibili senza quell'abilità
	if diag:
		for world in range(2, 11):
			for c in ChunkLib.chunks_of(world):
				if c["req"].is_empty():
					continue
				var prev: int = world - 1
				if world == 10:
					prev = 9
				if Validator.check_chunk(c, false, prev)["ok"]:
					print("  nota: %s (req=%s) si supera anche con le abilità del mondo %d" % [c["id"], ",".join(PackedStringArray(c["req"])), prev])
	for e in ChunkLib.errors:
		fails += 1
		print("  ERRORE formato: ", e)
	print("  (%d ms)" % (Time.get_ticks_msec() - t0))

	print("== Livelli fatti a mano ==")
	for w in range(1, 11):
		for l in [1, G.LEVELS]:
			if l == 1 and w > 1:
				var c := ChunkLib.handmade("intro_%d" % w)
				if c.is_empty():
					fails += 1
					print("  MANCA intro_%d" % w)
					continue
				var r := Validator.check_chunk(c, false, w)
				if not r["ok"]:
					fails += 1
					print("  intro_%d: non percorribile" % w)
				continue
			var lv = LevelGen.build(1, w, l)
			var r := Validator.check_level(lv)
			var has_boss := false
			for e in lv.ents:
				if e["t"] == "boss":
					has_boss = true
			if l == G.LEVELS and not has_boss:
				fails += 1
				print("  boss_%d: manca il boss (Q)" % w)
			if not r["ok"] or not r["secret"]:
				fails += 1
				print("  livello %d-%d fatto a mano: uscita=%s segreto=%s" % [w, l, r["ok"], r["secret"]])
	# controprova: il validatore deve bocciare i blocchi impossibili
	for bad in [["vuoto di 7 tile", "##########.......#############", 1], ["muro di 6 tile", "", 1]]:
		var rows: Array = []
		for i in range(6):
			rows.append(bad[1] if bad[1] != "" else "#" .repeat(30))
		if bad[1] == "":
			for i in range(6):
				rows.push_front("............###...............")
		var c := {"id": "test_bad", "rows": [], "w": 30, "h": 17, "qin": "M", "qout": "M", "noflip": false}
		for i in range(17 - rows.size()):
			c["rows"].append(".".repeat(30))
		c["rows"].append_array(rows)
		if Validator.check_chunk(c, false, bad[2])["ok"]:
			fails += 1
			print("  il validatore accetta un blocco impossibile: ", bad[0])

	print("== Generatore ==")
	for sd in [12345, 777, 20261002]:
		t0 = Time.get_ticks_msec()
		var attempts := LevelGen.prepare(sd, false)
		var bad := 0
		var repeats := 0
		for world in range(1, 11):
			for level in range(1, G.LEVELS):
				var opts := {"attempts": attempts}
				var a = LevelGen.build(sd, world, level, opts)
				var b = LevelGen.build(sd, world, level, opts)
				if a.cells != b.cells or str(a.ents) != str(b.ents):
					bad += 1
					print("  NON deterministico: seed %d livello %d-%d" % [sd, world, level])
				if not LevelGen.sane(a):
					bad += 1
					print("  livello incompleto: seed %d livello %d-%d (larghezza %d)" % [sd, world, level, a.w])
				var want := LevelGen.screens_for(world, level) * 30
				if a.w < want:
					bad += 1
					print("  livello corto: seed %d livello %d-%d: %d colonne invece di %d" % [sd, world, level, a.w, want])
				var seen := {}
				for s in a.spans:
					if seen.has(s[2]):
						repeats += 1
					seen[s[2]] = true
		fails += bad
		print("  seed %d: 40 livelli, %d problemi, %d blocchi ripetuti, %d rigenerati (%d ms)" % [sd, bad, repeats, attempts.size(), Time.get_ticks_msec() - t0])
	if levels:
		print("== Livelli completi (validatore sull'intero livello) ==")
		for world in [1, 2, 3, 4, 6, 7, 8, 9]:
			for level in [2, 3, 4]:
				t0 = Time.get_ticks_msec()
				var lv = LevelGen.build(12345, world, level)
				var r := Validator.check_level(lv)
				if not r["ok"] or not r["secret"]:
					fails += 1
				print("  %d-%d: uscita=%s segreto=%s (%d colonne, %d nodi, %d ms)" % [world, level, r["ok"], r["secret"], lv.w, r["nodes"], Time.get_ticks_msec() - t0])
	if write:
		Validator.save_table()
		print("Tabella di validazione salvata in ", Validator.CACHE_PATH)
	print("RISULTATO: %s (%d errori)" % ["OK" if fails == 0 else "FALLITO", fails])
	return fails


static func _flat_edges(c: Dictionary) -> Array:
	var errs: Array = []
	var rows: Array = c["rows"]
	var n: int = rows.size()
	for side in [0, 1]:
		var cols := [0, 1] if side == 0 else [c["w"] - 1, c["w"] - 2]
		var q: String = c["qin"] if side == 0 else c["qout"]
		var top: int = n - ChunkLib.QUOTE_ROWS[q]
		for col in cols:
			for ry in range(n):
				var ch: String = rows[ry][col]
				if ry >= top and ch != "#":
					errs.append("bordo non pieno (col %d)" % col)
					break
				if ry < top and ry >= top - 2 and ch in "#^vBMD":
					errs.append("bordo non sgombro (col %d)" % col)
					break
	return errs
