extends Node
## Salvataggi in user:// (JSON): 3 slot di partita + un file comune con
## impostazioni e galleria. Dei livelli si salva solo il seed.

const SLOTS := 3
const GLOBAL_PATH := "user://global.json"

var settings := {
	"music": 0.7, "sfx": 0.8, "vibra": true, "lefty": false,
	"joy_size": 1.0, "joy_alpha": 0.5, "lang": "it",
	"cb": 0, "reduce_fx": false, "speed": 1.0, "auto_high": false,
	"big_text": false, "sound_cues": true, "smooth": true, "hd2d": true,
	# menu segreto di prova (tenere premuto "Impostazioni" 10 secondi nel titolo)
	"mod_god": false, "mod_unlock": false,
}
var gallery := {
	"scenes": [], "memories": [], "bestiary": [], "bosses": [], "tut_done": false,
	"deaths": 0, "time": 0.0, "fragments": 0, "finished": 0,
	"incubo": false, "full": true,
}
var run := {}
var slot_idx := -1


func _ready() -> void:
	load_global()


func load_global() -> void:
	var d = _read(GLOBAL_PATH)
	if d is Dictionary:
		if d.get("settings") is Dictionary:
			settings.merge(d["settings"], true)
		if d.get("gallery") is Dictionary:
			gallery.merge(d["gallery"], true)


func save_global() -> void:
	_write(GLOBAL_PATH, {"settings": settings, "gallery": gallery})


func slot_path(i: int) -> String:
	return "user://slot_%d.json" % (i + 1)


func peek_slot(i: int) -> Dictionary:
	var d = _read(slot_path(i))
	return _fix(d) if d is Dictionary and d.has("seed") else {}


func load_slot(i: int) -> bool:
	var d := peek_slot(i)
	if d.is_empty():
		return false
	run = d
	slot_idx = i
	return true


func delete_slot(i: int) -> void:
	if FileAccess.file_exists(slot_path(i)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(i)))


func new_run(i: int, seed: int, mode: String, skip_tut: bool) -> void:
	slot_idx = i
	run = {
		"v": 2, "seed": seed, "mode": mode, "skip_tut": skip_tut,
		"world": 1, "level": 1, "max_world": 1, "max_level": 1,
		"lives": 5 if mode == "agitato" else 1, "hp": G.MAX_HP,
		"fragments": 0, "frag_bank": 0,
		"secrets": {}, "records": {}, "attempts": {},
		"deaths": 0, "time": 0.0, "finished": false, "over": false,
		"cp": {}, "world_snap": {"fragments": 0, "frag_bank": 0, "secrets": []},
	}
	save_run()


func save_run() -> void:
	if slot_idx >= 0 and not run.is_empty():
		_write(slot_path(slot_idx), run)


## JSON restituisce tutti i numeri come float: riporta a int i campi interi.
func _fix(d: Dictionary) -> Dictionary:
	for k in ["seed", "world", "level", "max_world", "max_level", "lives", "hp", "fragments", "frag_bank", "deaths"]:
		if d.has(k):
			d[k] = int(d[k])
	if d.get("attempts") is Dictionary:
		for k in d["attempts"]:
			d["attempts"][k] = int(d["attempts"][k])
	if int(d.get("v", 1)) < 2:
		_to_five_levels(d)
	return d


## Partite salvate quando i mondi avevano 10 livelli: il progresso si dimezza
## (livello 7 -> 4, boss 10 -> boss 5) e si tengono solo i record dei livelli che
## esistono ancora. I livelli stessi cambiano, perché cambia la curva di difficoltà.
func _to_five_levels(d: Dictionary) -> void:
	for k in ["level", "max_level"]:
		d[k] = clampi(int(ceil(int(d.get(k, 1)) / 2.0)), 1, G.LEVELS)
	for name in ["secrets", "records"]:
		var old: Dictionary = d.get(name, {})
		for key in old.keys():
			if int(str(key).get_slice("-", 1)) > G.LEVELS:
				old.erase(key)
	d["attempts"] = {}
	d["cp"] = {}
	d["v"] = 2


## Ultimo mondo raggiungibile (tutti, se il trucco "sblocca tutto" è attivo).
func max_world() -> int:
	return 10 if settings["mod_unlock"] else int(run.get("max_world", 1))


func unlocked(world: int, level: int) -> bool:
	if run.is_empty():
		return false
	if settings["mod_unlock"]:
		return true
	return world < run["max_world"] or (world == run["max_world"] and level <= run["max_level"])


func has_secret(world: int, level: int) -> bool:
	return run.get("secrets", {}).has(G.key(world, level))


func world_secrets(world: int) -> int:
	var n := 0
	for l in range(1, G.LEVELS + 1):
		if has_secret(world, l):
			n += 1
	return n


func unlock_gallery(list: String, id: String) -> bool:
	var arr: Array = gallery[list]
	if id in arr:
		return false
	arr.append(id)
	save_global()
	return true


func _read(path: String):
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _write(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()
