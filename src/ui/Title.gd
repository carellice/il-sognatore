extends Control
## Menu principale: Continua, Nuova partita, Galleria, Impostazioni, Crediti.

const UI = preload("res://src/ui/UI.gd")
const Background = preload("res://src/game/Background.gd")

var bg
var t := 0.0
var menu: Control
var sub: Control
var logo: Control
var settings_btn: Button
var hold_t := 0.0
var holding := false

const HOLD_MOD := 10.0


func _ready() -> void:
	G.full(self)
	Save.run = {}
	Save.slot_idx = -1
	bg = Background.new()
	bg.setup(1 + (int(Save.gallery.get("finished", 0)) * 3 + Save.gallery["bestiary"].size()) % 10)
	bg.show_behind_parent = true
	add_child(bg)
	Snd.music("menu")
	logo = UI.Heading.new()
	logo.logo = true
	logo.text = T.t("title")
	G.top_wide(logo, 10, 50)
	add_child(logo)
	var subt := UI.Heading.new()
	subt.scale_k = 1
	subt.color = Color("fff3b0")
	subt.text = T.t("subtitle")
	G.top_wide(subt, 58, 12)
	add_child(subt)
	_main_menu()
	if int(G.params.get("mod", 0)) == 1:
		_mod_menu()


func _process(dt: float) -> void:
	t += dt
	# menu segreto: "Impostazioni" tenuto premuto per 10 secondi
	if holding and settings_btn != null and is_instance_valid(settings_btn):
		hold_t += dt
		if hold_t >= HOLD_MOD:
			settings_btn = null
			holding = false
			Snd.play("secret")
			_mod_menu()
	else:
		hold_t = 0.0
	bg.cam_x = t * 14.0
	queue_redraw()


func _draw() -> void:
	var c := Art.tex("chiara")
	var half: float = logo.custom_minimum_size.x * 0.5
	var p := Vector2(size.x * 0.5 - half - 34 + sin(t * 1.3) * 4.0, 24 + sin(t * 2.1) * 4.0)
	draw_texture(c, p.round(), Color(1, 1, 1, 0.9))
	var fl: Texture2D = Art.player_frames(0)["run%d" % (int(t * 8.0) % 4)]
	draw_texture(fl, Vector2(size.x * 0.5 + half + 12, 16))


func _has_slots() -> bool:
	for i in range(Save.SLOTS):
		if not Save.peek_slot(i).is_empty():
			return true
	return false


func _clear() -> void:
	if menu != null:
		menu.queue_free()
		menu = null


func _column(items: Array) -> void:
	_clear()
	var cc := CenterContainer.new()
	G.full(cc)
	cc.offset_top = 76
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	for it in items:
		vb.add_child(it)
	cc.add_child(vb)
	add_child(cc)
	menu = cc
	UI.focus_first(vb)


func _main_menu() -> void:
	var items: Array = []
	if _has_slots():
		items.append(UI.button(T.t("continue"), _slots.bind(false), 150, true))
	items.append(UI.button(T.t("new_game"), _slots.bind(true), 150, true))
	items.append(UI.button(T.t("gallery"), func(): G.goto("gallery"), 150, true))
	settings_btn = UI.button(T.t("settings"), func(): G.goto("settings"), 150, true)
	hold_t = 0.0
	holding = false
	settings_btn.button_down.connect(func(): holding = true)
	settings_btn.button_up.connect(func(): holding = false)
	items.append(settings_btn)
	items.append(UI.button(T.t("credits"), func(): G.goto("credits", {"then": "title"}), 150, true))
	_column(items)


## Menu di prova: immortalità, tutti i livelli aperti, salto al finale.
func _mod_menu() -> void:
	var toggle := func(key: String):
		Save.settings[key] = not Save.settings[key]
		Save.save_global()
		_mod_menu()
	var items: Array = []
	for key in ["mod_god", "mod_unlock"]:
		items.append(UI.button("%s: %s" % [T.t(key), T.t("on") if Save.settings[key] else T.t("off")], toggle.bind(key), 220))
	items.append(UI.plate(UI.label(T.t("mod_unlock_d"), false, Color("c9d6ff"))))
	items.append(UI.button(T.t("mod_finale"), func(): G.goto("cutscene", {"ids": ["finale"], "then": "credits", "preview": true}), 220))
	items.append(UI.button(T.t("back"), _main_menu, 220))
	_column(items)


func slot_text(i: int, d: Dictionary) -> String:
	if d.is_empty():
		return "%s %d: %s" % [T.t("slot"), i + 1, T.t("empty")]
	var state := "%d-%d" % [d["world"], d["level"]]
	if d.get("over", false):
		state = T.t("ended")
	elif d.get("finished", false):
		state = T.t("finished")
	return "%s %d: %s, %s" % [T.t("slot"), i + 1, T.t("mode_" + d["mode"]), state]


func _slots(for_new: bool) -> void:
	var items: Array = [UI.label(T.t("choose_slot"))]
	for i in range(Save.SLOTS):
		var d := Save.peek_slot(i)
		var b := UI.button(slot_text(i, d), _pick.bind(i, for_new, d), 220)
		if not for_new and (d.is_empty() or d.get("over", false)):
			b.disabled = true
		items.append(b)
	items.append(UI.button(T.t("back"), _main_menu, 220))
	_column(items)


func _pick(i: int, for_new: bool, d: Dictionary) -> void:
	if for_new:
		if d.is_empty():
			G.goto("newgame", {"slot": i})
		else:
			_column([
				UI.label(slot_text(i, d)),
				UI.label(T.t("overwrite")),
				UI.button(T.t("yes"), func(): G.goto("newgame", {"slot": i})),
				UI.button(T.t("no"), _slots.bind(true)),
			])
		return
	if Save.load_slot(i):
		var cp: Dictionary = Save.run.get("cp", {})
		if not cp.is_empty():
			G.goto("game", {"world": int(cp["world"]), "level": int(cp["level"]), "from_cp": true})
		else:
			G.goto("map", {"world": Save.run["world"]})
