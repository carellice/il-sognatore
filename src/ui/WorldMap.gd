extends Control
## Mappa del mondo: i livelli del mondo, quelli completati e i segreti trovati.
## Da qui si rigiocano i livelli per cercare i segreti mancanti.

const UI = preload("res://src/ui/UI.gd")
const Background = preload("res://src/game/Background.gd")

var world := 1
var sel := 1
var bg
var t := 0.0
var nodes: Array = []
var info: Label
var title: Control
var holder: Control


func _ready() -> void:
	G.full(self)
	world = clampi(int(G.params.get("world", Save.run.get("world", 1))), 1, Save.max_world())
	bg = Background.new()
	bg.show_behind_parent = true
	add_child(bg)
	Snd.music("menu")
	_build()


func _build() -> void:
	if holder != null:
		holder.queue_free()
	holder = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	G.full(holder)
	add_child(holder)
	bg.setup(world)
	nodes.clear()
	var run: Dictionary = Save.run
	title = UI.label("%d. %s" % [world, T.t("world_" + str(world))], true, Color("fff3b0"))
	G.top_wide(title, 10, 22)
	holder.add_child(title)
	var ab: String = G.WORLDS[world - 1]["ability"]
	var sub_txt := "%s: %d/%d" % [T.t("secrets_n"), Save.world_secrets(world), G.LEVELS]
	if ab != "":
		sub_txt = "%s: %s   %s" % [T.t("new_ability"), T.t("abn_" + ab), sub_txt]
	var sub := UI.plate(UI.label(sub_txt))
	G.top_wide(sub, 36, 18)
	holder.add_child(sub)
	var first_open := 1
	for l in range(1, G.LEVELS + 1):
		var b: Button = UI.FancyButton.new()
		b.text = "B" if l == G.LEVELS else str(l)
		b.custom_minimum_size = Vector2(30, 26)
		b.size = Vector2(30, 26)
		b.disabled = not Save.unlocked(world, l)
		b.pressed.connect(_play.bind(l))
		b.focus_entered.connect(_select.bind(l))
		holder.add_child(b)
		nodes.append(b)
		if not b.disabled:
			first_open = l
	sel = first_open if world == Save.max_world() else 1
	info = UI.label("")
	var info_plate := UI.plate(info)
	G.bottom_wide(info_plate, -78, -40)
	holder.add_child(info_plate)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	G.bottom_wide(hb, -30, -10)
	var prev := UI.button("<", func(): _switch(-1), 22)
	prev.disabled = world <= 1
	var next := UI.button(">", func(): _switch(1), 22)
	next.disabled = world >= Save.max_world()
	hb.add_child(UI.button(T.t("back"), func(): G.goto("title"), 80))
	hb.add_child(prev)
	hb.add_child(UI.button(T.t("play"), func(): _play(sel), 110))
	hb.add_child(next)
	holder.add_child(hb)
	_layout()
	nodes[sel - 1].grab_focus.call_deferred()
	_select(sel)


func _layout() -> void:
	var w := size.x if size.x > 0 else 480.0
	var n := nodes.size()
	var step := minf(64.0, (w - 60.0) / n)
	var x0 := (w - step * (n - 1)) * 0.5
	for i in range(n):
		nodes[i].position = Vector2(x0 + i * step - 15.0, 112.0 + (18.0 if i % 2 == 1 else 0.0) - (10.0 if i == n - 1 else 0.0))


func _switch(d: int) -> void:
	world = clampi(world + d, 1, Save.max_world())
	Snd.play("select")
	_build()


func _select(l: int) -> void:
	sel = l
	var rec: Dictionary = Save.run["records"].get(G.key(world, l), {})
	var name := T.t("boss_" + str(world)) if l == G.LEVELS else "%s %d-%d" % [T.t("level"), world, l]
	if rec.is_empty():
		info.text = name
	else:
		info.text = "%s\n%s %s   %s %d   %s %s" % [name, T.t("best"), G.fmt_time(rec.get("t", 0.0)), T.t("fragments"), int(rec.get("f", 0)), T.t("secret"), T.t("found") if rec.get("s", false) else T.t("not_found")]


func _play(l: int) -> void:
	if not Save.unlocked(world, l):
		return
	Snd.play("select")
	G.goto("game", {"world": world, "level": l})


func _process(dt: float) -> void:
	t += dt
	bg.cam_x = t * 10.0
	queue_redraw()


func _draw() -> void:
	# sentiero tra i livelli, stelline dei segreti e Flavio sul livello selezionato
	for i in range(nodes.size() - 1):
		var a: Vector2 = nodes[i].position + Vector2(15, 13)
		var b: Vector2 = nodes[i + 1].position + Vector2(15, 13)
		var done: bool = Save.run["records"].has(G.key(world, i + 1))
		draw_line(a, b, Color("fff3b0") if done else Color(1, 1, 1, 0.3), 2.0)
	for i in range(nodes.size()):
		var p: Vector2 = nodes[i].position
		if Save.has_secret(world, i + 1):
			draw_texture(Art.tex("secret"), p + Vector2(9, 27))
		if i + 1 == sel:
			var fr: Texture2D = Art.player_frames(G.stage_of(world))["idle" if int(t * 2.0) % 2 == 0 else "run1"]
			draw_texture(fr, p + Vector2(3, -37))
			draw_texture(Art.tex("echo"), p + Vector2(28, -20 + sin(t * 3.0) * 3.0), Color(1, 1, 1, 0.9))


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.physical_keycode == KEY_PAGEUP or ev.physical_keycode == KEY_Q:
			_switch(-1)
		elif ev.physical_keycode == KEY_PAGEDOWN or ev.physical_keycode == KEY_E:
			_switch(1)
		elif ev.physical_keycode == KEY_ESCAPE:
			G.goto("title")
