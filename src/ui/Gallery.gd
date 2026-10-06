extends Control
## Galleria comune a tutti gli slot: scene della storia, ricordi, bestiario, statistiche.

const UI = preload("res://src/ui/UI.gd")
const EnemyDefs = preload("res://src/game/EnemyDefs.gd")

var tab := "story"
var body: Control
var best: Control


func _ready() -> void:
	G.full(self)
	var bg = preload("res://src/game/Background.gd").new()
	bg.setup(2)
	bg.tint = Color(0.6, 0.6, 0.8)
	add_child(bg)
	Snd.music("menu")
	tab = str(G.params.get("tab", "story"))
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	G.top_wide(hb, 8, 18)
	for tname in ["story", "memories", "bestiary", "stats"]:
		hb.add_child(UI.button(T.t("gal_" + tname), _tab.bind(tname), 70))
	hb.add_child(UI.button(T.t("back"), func(): G.goto("title"), 56))
	add_child(hb)
	UI.focus_first(hb)
	_tab(tab)


func _scene_name(id: String) -> String:
	if id.begins_with("after_"):
		return "%s %s" % [T.t("sc_after"), id.substr(6)]
	if id.begins_with("memory_"):
		return T.t("world_" + id.substr(7))
	return T.t("sc_" + id)


func _tab(name: String) -> void:
	tab = name
	if body != null:
		body.queue_free()
	body = Control.new()
	G.full(body)
	body.offset_top = 34
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	var cc := CenterContainer.new()
	G.full(cc)
	body.add_child(cc)
	match name:
		"story", "memories":
			var grid := GridContainer.new()
			grid.columns = 3
			var all: Array = ["prologue"]
			for i in range(1, 10):
				all.append("after_%d" % i)
			all.append_array(["finale", "epilogue"])
			if name == "memories":
				all.clear()
				for i in range(1, 11):
					all.append("memory_%d" % i)
			var list: Array = Save.gallery["scenes" if name == "story" else "memories"]
			if Save.settings["mod_unlock"]:
				list = all
			for id in all:
				var b := UI.button(_scene_name(id) if id in list else "???", func(): G.goto("cutscene", {"ids": [id], "then": "gallery", "tab": name}), 124)
				b.disabled = not (id in list)
				grid.add_child(b)
			cc.add_child(grid)
		"bestiary":
			best = preload("res://src/ui/BestiaryView.gd").new()
			best.custom_minimum_size = Vector2(420, 190)
			cc.add_child(best)
		"stats":
			var g: Dictionary = Save.gallery
			var pc := PanelContainer.new()
			var vb := VBoxContainer.new()
			pc.add_child(vb)
			vb.add_child(UI.label("%s: %s" % [T.t("gal_time"), G.fmt_time(g["time"])]))
			vb.add_child(UI.label("%s: %d" % [T.t("fragments"), g["fragments"]]))
			vb.add_child(UI.label("%s: %d" % [T.t("deaths"), g["deaths"]]))
			vb.add_child(UI.label("%s: %d" % [T.t("gal_finished"), g["finished"]]))
			vb.add_child(UI.label("%s: %d/30" % [T.t("gal_bestiary"), g["bestiary"].size()]))
			vb.add_child(UI.label("%s: %d/10" % [T.t("gal_memories"), g["memories"].size()]))
			cc.add_child(pc)
