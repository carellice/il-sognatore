extends Control
## Nuova partita: modalità di difficoltà, seed (casuale o inserito a mano),
## poi generazione e validazione dei livelli.

const UI = preload("res://src/ui/UI.gd")
const LevelGen = preload("res://src/gen/LevelGen.gd")
const Background = preload("res://src/game/Background.gd")

var slot := 0
var mode := "lucido"
var seed_val := 0
var skip_tut := false
var content: Control
var gen_world := 0
var bar: ColorRect
var attempts := {}
var typing := ""
var keypad_open := false


func _ready() -> void:
	G.full(self)
	slot = int(G.params.get("slot", 0))
	seed_val = LevelGen.new_seed()
	var bg = Background.new()
	bg.setup(1)
	bg.tint = Color(0.5, 0.5, 0.7)
	add_child(bg)
	_menu()


func _show(items: Array) -> void:
	if content != null:
		content.queue_free()
	content = UI.panel(self, items)[0]


func _menu() -> void:
	var modes: Array = []
	for m in G.MODES:
		var locked: bool = m == "incubo" and not (Save.gallery.get("incubo", false) or Save.settings["mod_unlock"])
		var b := UI.button(("> " if m == mode else "") + T.t("mode_" + m), func():
			mode = m
			_menu(), 92)
		b.disabled = locked
		modes.append(b)
	var mrow := HBoxContainer.new()
	mrow.alignment = BoxContainer.ALIGNMENT_CENTER
	for b in modes:
		mrow.add_child(b)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(UI.button(T.t("seed_random"), func():
		seed_val = LevelGen.new_seed()
		_menu(), 90))
	hb.add_child(UI.button(T.t("seed_manual"), _keypad, 90))
	var items: Array = [UI.label(T.t("new_game"), true, Color("fff3b0"))]
	items.append(mrow)
	var desc := T.t("mode_%s_d" % mode)
	if not (Save.gallery.get("incubo", false) or Save.settings["mod_unlock"]):
		desc += "\n(%s: %s)" % [T.t("mode_incubo"), T.t("mode_locked")]
	items.append(UI.label(desc, false, Color("c9d6ff")))
	items.append(UI.label("%s: %d" % [T.t("seed"), seed_val], false, Color("fff3b0")))
	items.append(hb)
	if Save.gallery.get("tut_done", false) or Save.settings["mod_unlock"]:
		items.append(UI.button("%s: %s" % [T.t("skip_tut"), T.t("on") if skip_tut else T.t("off")], func():
			skip_tut = not skip_tut
			_menu(), 200))
	items.append(UI.button(T.t("start_dream"), _start, 200))
	items.append(UI.button(T.t("back"), func(): G.goto("title"), 200))
	_show(items)


func _keypad() -> void:
	typing = ""
	keypad_open = true
	_draw_keypad()


func _draw_keypad() -> void:
	var grid := GridContainer.new()
	grid.columns = 3
	for k in ["1", "2", "3", "4", "5", "6", "7", "8", "9", T.t("delete"), "0", T.t("ok")]:
		grid.add_child(UI.button(k, _key.bind(k), 44))
	var cc := CenterContainer.new()
	cc.add_child(grid)
	_show([UI.label(T.t("seed"), true), UI.label(typing if typing != "" else "_", false, Color("fff3b0")), cc, UI.label(T.t("seed_hint"), false, Color("c9d6ff"))])


func _key(k: String) -> void:
	if k == T.t("ok"):
		if typing != "":
			seed_val = maxi(1, int(typing))
		keypad_open = false
		_menu()
		return
	if k == T.t("delete"):
		typing = typing.substr(0, typing.length() - 1)
	elif typing.length() < 9:
		typing += k
	_draw_keypad()


func _unhandled_key_input(ev: InputEvent) -> void:
	var e := ev as InputEventKey
	if keypad_open and e != null and e.pressed and e.unicode >= 48 and e.unicode <= 57 and typing.length() < 9:
		typing += char(e.unicode)
		_draw_keypad()


func _start() -> void:
	Save.new_run(slot, seed_val, mode, skip_tut)
	bar = ColorRect.new()
	bar.color = Color("ffd65a")
	bar.custom_minimum_size = Vector2(2, 6)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(180, 8)
	holder.add_child(bar)
	_show([UI.label(T.t("generating")), holder, UI.label("%s: %d" % [T.t("seed"), seed_val], false, Color("fff3b0"))])
	gen_world = 1


func _process(_dt: float) -> void:
	if gen_world < 1 or gen_world > 10:
		return
	# un mondo per fotogramma, così la barra avanza
	for level in range(1, G.LEVELS):
		var k := G.key(gen_world, level)
		for a in range(LevelGen.MAX_ATTEMPTS):
			if a > 0:
				attempts[k] = a
			if LevelGen.sane(LevelGen.build(seed_val, gen_world, level, {"skip_tut": skip_tut, "attempts": attempts})):
				break
	bar.size = Vector2(18.0 * gen_world, 6)
	gen_world += 1
	if gen_world > 10:
		Save.run["attempts"] = attempts
		Save.save_run()
		G.goto("cutscene", {"ids": ["prologue"], "then": "game", "world": 1, "level": 1})
