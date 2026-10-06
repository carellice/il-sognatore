extends Control
## Impostazioni e accessibilità. Ogni voce è un pulsante che cambia valore al tocco.

signal closed

const UI = preload("res://src/ui/UI.gd")

const ITEMS := [
	["music", "set_music", [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]],
	["sfx", "set_sfx", [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]],
	["vibra", "set_vibra", [true, false]],
	["lang", "set_lang", ["it", "en"]],
	["lefty", "set_lefty", [false, true]],
	["joy_size", "set_joy_size", [0.8, 1.0, 1.25, 1.5]],
	["joy_alpha", "set_joy_alpha", [0.25, 0.5, 0.75, 1.0]],
	["auto_high", "set_auto_high", [false, true]],
	["speed", "set_speed", [1.0, 0.85, 0.7]],
	["cb", "set_cb", [0, 1, 2, 3]],
	["reduce_fx", "set_reduce", [false, true]],
	["big_text", "set_big_text", [false, true]],
	["sound_cues", "set_cues", [true, false]],
	["smooth", "set_smooth", [true, false]],
	["hd2d", "set_hd2d", [true, false]],
]

var embedded := false
var root: Control


func _ready() -> void:
	G.full(self)
	if not embedded:
		var bg = preload("res://src/game/Background.gd").new()
		bg.setup(4)
		add_child(bg)
	_build()


func _fmt(key: String, v) -> String:
	if v is bool:
		return T.t("on") if v else T.t("off")
	if key == "cb":
		return T.t("cb_%d" % int(v))
	if key == "lang":
		return "Italiano" if v == "it" else "English"
	return "%d%%" % int(round(float(v) * 100.0))


func _build() -> void:
	if root != null:
		root.queue_free()
	var grid := GridContainer.new()
	grid.columns = 3
	for it in ITEMS:
		var key: String = it[0]
		var b := UI.button("%s: %s" % [T.t(it[1]), _fmt(key, Save.settings[key])], _cycle.bind(it), 124)
		grid.add_child(b)
	var arr := UI.panel(self, [UI.label(T.t("settings"), true), grid, UI.button(T.t("back"), _close, 180)], 0.6 if embedded else 0.0)
	root = arr[0]
	UI.focus_first(grid)


func _cycle(it: Array) -> void:
	var key: String = it[0]
	var vals: Array = it[2]
	var cur = Save.settings[key]
	var idx := 0
	for i in range(vals.size()):
		if typeof(vals[i]) == typeof(cur) and vals[i] == cur:
			idx = i
		elif (vals[i] is float or vals[i] is int) and (cur is float or cur is int) and is_equal_approx(float(vals[i]), float(cur)):
			idx = i
	Save.settings[key] = vals[(idx + 1) % vals.size()]
	Save.save_global()
	G.main.apply_settings()
	var focus_i := ITEMS.find(it)
	_build()
	var grid: Node = root.get_child(root.get_child_count() - 1).get_child(0).get_child(0).get_child(1)
	grid.get_child(focus_i).grab_focus.call_deferred()


func _close() -> void:
	if embedded:
		closed.emit()
		queue_free()
	else:
		G.goto("title")
