extends Control
## Scene narrative in pixel art tra un mondo e l'altro: poche righe di testo,
## Flavio che cresce e l'eco di Chiara che sbiadisce.

const UI = preload("res://src/ui/UI.gd")
const Background = preload("res://src/game/Background.gd")

# attori: [tipo, x (0..1), parametri...]
const SCENES := {
	"prologue": [
		{"bg": 1, "text": "prologue_1", "act": [["flavio", 0.42, 0, "run"], ["chiara", 0.56, 1.0]]},
		{"bg": 1, "text": "prologue_2", "act": [["bed", 0.3], ["flavio", 0.3, 0, "sleep"], ["chiara", 0.62, 0.8], ["shadow", 0.78]]},
		{"bg": 1, "text": "prologue_3", "act": [["flavio", 0.4, 0, "idle"], ["echo", 0.52, 1.0]]},
	],
	"after_1": [{"bg": 2, "text": "after_1", "act": [["flavio", 0.42, 0, "idle"], ["cherry", 0.5], ["echo", 0.6, 1.0]]}],
	"after_2": [{"bg": 3, "text": "after_2", "act": [["flavio", 0.42, 1, "run"], ["echo", 0.56, 0.9]]}],
	"after_3": [{"bg": 4, "text": "after_3", "act": [["flavio", 0.42, 1, "idle"], ["echo", 0.55, 0.8]]}],
	"after_4": [{"bg": 5, "text": "after_4", "act": [["flavio", 0.42, 2, "idle"], ["echo", 0.56, 0.55]]}],
	"after_5": [{"bg": 6, "text": "after_5", "act": [["flavio", 0.42, 2, "idle"], ["echo", 0.6, 0.25, "blink"]]}],
	"after_6": [{"bg": 7, "text": "after_6", "act": [["clock", 0.7], ["flavio", 0.42, 3, "run"], ["echo", 0.3, 0.35]]}],
	"after_7": [{"bg": 8, "text": "after_7", "act": [["mirror", 0.62], ["flavio", 0.42, 3, "idle"], ["echo", 0.52, 0.28]]}],
	"after_8": [{"bg": 9, "text": "after_8", "act": [["flavio", 0.42, 4, "idle"], ["echo", 0.54, 0.15]]}],
	"after_9": [{"bg": 10, "text": "after_9", "act": [["door", 0.68], ["flavio", 0.36, 4, "idle"], ["echo", 0.46, 0.12]]}],
	"finale": [
		{"bg": 10, "text": "finale_1", "act": [["flavio", 0.4, 4, "idle"], ["chiara", 0.58, 0.18]], "lock": true},
		{"bg": 4, "text": "finale_2", "act": [["flavio", 0.4, 4, "idle"], ["chiara", 0.58, 1.0, "glow"]], "lock": true},
		{"bg": 1, "text": "finale_3", "act": [["bed", 0.3], ["flavio", 0.3, 4, "idle"], ["drawing", 0.55], ["echo", 0.62, 1.0]], "lock": true},
		{"bg": 1, "text": "finale_4", "act": [["bed", 0.2], ["drawing", 0.36], ["proposal", 0.5]], "lock": true, "delay": 3.4},
	],
	"epilogue": [{"bg": 1, "text": "epilogue", "act": [["flavio", 0.4, 4, "idle"], ["drawing", 0.55], ["chiara", 0.66, 1.0, "glow"]]}],
}

var ids: Array = []
var panels: Array = []
var pi := 0
var bg
var t := 0.0
var label: Label
var box: PanelContainer
var chars := 0.0
var done := false
var skip_btn: Button
var next_btn: Button


func _ready() -> void:
	G.full(self)
	var want = G.params.get("ids", ["prologue"])
	ids = want if want is Array else [want]
	pi = int(G.params.get("panel", 0))
	# rivedere una scena dalla galleria o dal menu di prova non sblocca nulla
	var preview: bool = G.params.get("then", "") == "gallery" or G.params.get("preview", false)
	for id in ids:
		if not preview:
			Save.unlock_gallery("scenes", id)
		if SCENES.has(id):
			panels.append_array(SCENES[id])
		elif str(id).begins_with("memory_"):
			var w := int(str(id).substr(7))
			panels.append({"bg": w, "text": id, "act": [["flavio", 0.42, 0, "run"], ["chiara", 0.56, 1.0, "glow"]], "memory": true})
	bg = Background.new()
	bg.show_behind_parent = true
	add_child(bg)
	Snd.music("story")
	box = PanelContainer.new()
	G.bottom_wide(box, -62, -8)
	box.offset_left = 30
	box.offset_right = -30
	label = UI.label("")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(label)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	skip_btn = UI.button(T.t("skip"), _skip, 44)
	G.pin(skip_btn, 1.0, 0.0, -76, 8, 66, 26)
	skip_btn.focus_mode = Control.FOCUS_NONE
	add_child(skip_btn)
	# nei quadri "bloccati" (tutto il finale) si va avanti solo con questo pulsante
	next_btn = UI.button(T.t("next"), _next_locked, 52)
	G.pin(next_btn, 0.0, 0.0, 12, 8, 72, 26)
	next_btn.focus_mode = Control.FOCUS_NONE
	add_child(next_btn)
	pi = clampi(pi, 0, panels.size() - 1)
	_show_panel()


func _show_panel() -> void:
	var p: Dictionary = panels[pi]
	bg.setup(p["bg"])
	bg.tint = Color(1.0, 0.92, 0.8) if p.get("memory", false) else Color.WHITE
	label.text = T.t(p["text"])
	label.visible_characters = 0
	chars = 0.0
	t = 0.0
	var locked: bool = p.get("lock", false)
	next_btn.visible = locked
	skip_btn.visible = not locked


func _process(dt: float) -> void:
	t += dt
	bg.cam_x = t * 6.0
	var delay: float = panels[pi].get("delay", 0.0) if not panels.is_empty() else 0.0
	if t >= delay:
		chars += dt * 34.0
	label.visible_characters = int(chars)
	if not panels.is_empty() and panels[pi].get("lock", false):
		next_btn.visible = t >= delay
	queue_redraw()


func _advance() -> void:
	if done:
		return
	if t < panels[pi].get("delay", 0.0):
		return
	if label.visible_characters < label.text.length():
		chars = 9999.0
		return
	if panels[pi].get("lock", false):
		return
	Snd.play("select")
	if pi + 1 >= panels.size():
		_finish()
	else:
		pi += 1
		_show_panel()


## "Salta" non scavalca un quadro bloccato: ci si ferma lì.
func _skip() -> void:
	for i in range(pi + 1, panels.size()):
		if panels[i].get("lock", false):
			pi = i
			_show_panel()
			return
	_finish()


func _next_locked() -> void:
	if done:
		return
	if pi + 1 >= panels.size():
		_finish()
	else:
		pi += 1
		_show_panel()


func _finish() -> void:
	if done:
		return
	done = true
	var then: String = G.params.get("then", "map")
	if then == "game":
		G.goto("game", {"world": int(G.params.get("world", 1)), "level": int(G.params.get("level", 1))})
	elif then == "map":
		G.goto("map", {"world": int(Save.run.get("world", 1))})
	else:
		G.goto(then, {"then": "title", "tab": G.params.get("tab", "story")})


func _gui_input(ev: InputEvent) -> void:
	if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
		_advance()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		_advance()
	elif ev is InputEventJoypadButton and ev.pressed:
		_advance()


func _draw() -> void:
	if panels.is_empty():
		return
	var p: Dictionary = panels[pi]
	var world: int = p["bg"]
	var gy := size.y - 86.0
	# pavimento con i colori del mondo
	draw_rect(Rect2(0, gy, size.x, size.y - gy), G.pal(world, "ground"))
	draw_rect(Rect2(0, gy, size.x, 3), G.pal(world, "top"))
	draw_rect(Rect2(0, gy + 3, size.x, 1), G.pal(world, "dark"))
	for a in p["act"]:
		var x: float = size.x * float(a[1])
		match a[0]:
			"flavio":
				var fr: Dictionary = Art.player_frames(int(a[2]))
				var pose: String = a[3]
				if pose == "sleep":
					draw_set_transform(Vector2(x + 14, gy - 16), PI * 0.5)
					draw_texture(fr["idle"], Vector2(-12, -18))
					draw_set_transform(Vector2.ZERO, 0.0)
					draw_string(Art.font, Vector2(x + 16, gy - 34 - fmod(t * 6.0, 10.0)), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.8))
				else:
					var name := "idle"
					if pose == "run":
						name = "run%d" % (int(t * 7.0) % 4)
						x += sin(t * 0.8) * 14.0
					draw_texture(fr[name], Vector2(round(x) - 12, gy - 35))
			"chiara":
				var al: float = a[2]
				if a.size() > 3:
					al = clampf(al * (0.3 + t * 0.5), 0.0, 1.0)
					draw_circle(Vector2(x, gy - 22), 14.0 + sin(t * 3.0) * 3.0, Color(1, 0.95, 0.6, 0.18 * al))
				draw_texture(Art.tex("chiara"), Vector2(round(x) - 6, gy - 30 + sin(t * 2.4) * 3.0).round(), Color(1, 1, 1, al))
			"echo":
				var al: float = a[2]
				if a.size() > 3 and fmod(t, 1.6) > 1.1:
					al = 0.0
				draw_texture(Art.tex("echo"), Vector2(round(x) - 3, gy - 30 + sin(t * 3.0) * 3.0).round(), Color(1, 1, 1, clampf(al + 0.1, 0.0, 1.0)))
			"proposal":
				_draw_proposal(x, gy)
			"shadow":
				var sx := x - minf(t * 14.0, 60.0)
				draw_circle(Vector2(sx, gy - 26), 22.0, Color(0.08, 0.03, 0.14, 0.92))
				draw_circle(Vector2(sx - 12, gy - 12), 14.0, Color(0.08, 0.03, 0.14, 0.92))
				draw_rect(Rect2(sx - 12, gy - 32, 4, 3), Color("ff3b6b"))
				draw_rect(Rect2(sx - 2, gy - 32, 4, 3), Color("ff3b6b"))
			"cherry":
				# la ciliegia portafortuna di Chiara: dondola piano, con un piccolo alone
				var cy := gy - 22.0 + sin(t * 2.2) * 2.0
				draw_circle(Vector2(x, cy + 2), 11.0 + sin(t * 3.0), Color(1.0, 0.5, 0.5, 0.16))
				var ct := Art.tex("cherry")
				draw_texture(ct, Vector2(round(x) - ct.get_width() * 0.5, round(cy) - ct.get_height() * 0.5))
				if fmod(t, 1.4) < 0.5:
					draw_rect(Rect2(round(x) + 7, round(cy) - 7, 1, 3), Color.WHITE)
					draw_rect(Rect2(round(x) + 6, round(cy) - 6, 3, 1), Color.WHITE)
			"bed":
				draw_rect(Rect2(x - 26, gy - 12, 60, 12), Color("8a5a36"))
				draw_rect(Rect2(x - 26, gy - 22, 6, 22), Color("5e3b20"))
				draw_rect(Rect2(x - 18, gy - 17, 16, 6), Color("f2f4ff"))
				draw_rect(Rect2(x - 2, gy - 16, 36, 6), Color("7fb7e6"))
			"door":
				draw_rect(Rect2(x - 20, gy - 70, 40, 70), Color("0f0818"))
				draw_rect(Rect2(x - 20, gy - 70, 40, 70), Color("7b3fa0"), false, 2.0)
				draw_circle(Vector2(x, gy - 44), 6.0 + sin(t * 2.0), Color("ff3b6b"))
				draw_rect(Rect2(x - 1, gy - 47, 2, 6), Color("0f0818"))
			"mirror":
				draw_rect(Rect2(x - 20, gy - 62, 40, 62), Color("c9962e"))
				draw_rect(Rect2(x - 17, gy - 59, 34, 56), Color("7fb7e6"))
				draw_texture(Art.player_frames(0)["idle"], Vector2(x - 12, gy - 38), Color(1, 1, 1, 0.85))
				draw_line(Vector2(x - 14, gy - 12), Vector2(x + 6, gy - 56), Color(1, 1, 1, 0.5), 1.0)
			"clock":
				draw_circle(Vector2(x, gy - 60), 22.0, Color("e6c15a"))
				draw_circle(Vector2(x, gy - 60), 19.0, Color("fff5f0"))
				draw_line(Vector2(x, gy - 60), Vector2(x, gy - 60) + Vector2(cos(t * 6.0), sin(t * 6.0)) * 16.0, Color("1a1423"), 1.0)
				draw_line(Vector2(x, gy - 60), Vector2(x, gy - 60) + Vector2(cos(t * 1.1), sin(t * 1.1)) * 10.0, Color("1a1423"), 2.0)
			"drawing":
				draw_rect(Rect2(x - 12, gy - 64, 24, 30), Color("fffbe6"))
				draw_rect(Rect2(x - 12, gy - 64, 24, 30), Color("8a5a36"), false, 1.0)
				draw_texture(Art.tex("chiara"), Vector2(x - 6, gy - 57))


## Finale: Flavio adulto entra, si ferma davanti a Chiara, si inginocchia, tende
## la scatolina e la apre. Tempi in secondi dall'inizio del quadro (t).
const PROP_WALK := 1.6
const PROP_KNEEL := 2.0
const PROP_ARM := 2.6
const PROP_OPEN := 3.2


func _draw_proposal(x: float, gy: float) -> void:
	x = round(x)
	var fx := x - 22.0
	var cx := x + 16.0
	var opened := t >= PROP_OPEN
	# la luce di Chiara, che ora la circonda (più forte quando la scatolina si apre)
	var pulse := 0.5 + 0.5 * sin(t * 2.2)
	var glow := 1.0 + (0.6 * clampf((t - PROP_OPEN) * 2.0, 0.0, 1.0) if opened else 0.0)
	draw_circle(Vector2(cx, gy - 16), (26.0 + pulse * 3.0) * glow, Color(1, 0.95, 0.6, 0.10))
	draw_circle(Vector2(cx, gy - 16), (17.0 + pulse * 2.0) * glow, Color(1, 0.95, 0.6, 0.14))
	var ch := Art.tex("chiara_adult")
	draw_texture(ch, Vector2(cx - 6, gy - ch.get_height() + 1))
	var frames: Dictionary = Art.player_frames(4)
	if t < PROP_WALK:
		# entra camminando da sinistra
		var k := t / PROP_WALK
		k = 1.0 - (1.0 - k) * (1.0 - k)
		var wx: float = round(lerpf(fx - 70.0, fx, k))
		draw_texture(frames["run%d" % (int(t * 9.0) % 4)], Vector2(wx - 12, gy - 35))
		return
	if t < PROP_KNEEL:
		draw_texture(frames["idle"], Vector2(fx - 12, gy - 35))
		return
	# si inginocchia in tre pose: in piedi, accovacciato, in ginocchio
	var stage := 2
	if t < PROP_KNEEL + 0.18:
		stage = 1
	_draw_kneel(frames["idle"], fx, gy, stage)
	if t < PROP_ARM:
		return
	# il braccio si allunga verso Chiara
	var top := gy - 28.0
	var hy := top + 15.0
	var reach := clampf((t - PROP_ARM) / 0.35, 0.0, 1.0)
	var arm := roundf(lerpf(2.0, 7.0, reach))
	var ink := Color("1a1423")
	draw_rect(Rect2(fx + 3, hy - 1, arm + 2, 3), ink)
	draw_rect(Rect2(fx + 3, hy, arm, 1), Color("e8e8f0"))
	draw_rect(Rect2(fx + 3 + arm, hy, 1, 1), Color("f2c6a0"))
	if reach < 1.0:
		return
	# la scatolina: chiusa, poi il coperchio si alza e appare l'anello
	var bx := fx + 4 + arm
	draw_rect(Rect2(bx, hy - 3, 6, 5), ink)
	draw_rect(Rect2(bx + 1, hy - 1, 4, 2), Color("8f2d3a"))
	if not opened:
		draw_rect(Rect2(bx + 1, hy - 2, 4, 1), Color("b04050"))
		return
	draw_rect(Rect2(bx, hy - 6, 6, 3), ink)
	draw_rect(Rect2(bx + 1, hy - 5, 4, 1), Color("b04050"))
	draw_rect(Rect2(bx + 2, hy - 2, 2, 1), Color("ffd65a"))
	# scintilla dell'anello: un lampo all'apertura, poi intermittente
	var since := t - PROP_OPEN
	if since < 0.5 or fmod(t, 1.2) < 0.6:
		var r := 3.0 + (2.0 * (1.0 - since / 0.5) if since < 0.5 else 0.0)
		draw_rect(Rect2(bx + 2, hy - 3 - r, 1, r * 2 - 1), Color.WHITE)
		draw_rect(Rect2(bx + 3 - r, hy - 4, r * 2 - 1, 1), Color.WHITE)
	# cuori che salgono
	var heart := Art.tex("heart")
	for i in range(4):
		if since > 0.4 + i * 0.4:
			var k := fmod((since - 0.4 - i * 0.4) * 0.35, 1.0)
			var hp := Vector2(x - 6 + sin(k * 6.0 + i * 2.0) * 10.0 + (i - 1.5) * 9.0, gy - 44 - k * 46.0)
			draw_texture(heart, hp.round(), Color(1, 1, 1, sin(k * PI)))


## Flavio che si inginocchia: busto e testa dello sprite, abbassati; gambe disegnate a mano.
func _draw_kneel(fr: Texture2D, fx: float, gy: float, stage: int) -> void:
	var pants := Color("2a2a3a")
	var ink := Color("1a1423")
	if stage == 1:
		# accovacciato a metà
		var top1 := gy - 32.0
		draw_rect(Rect2(fx - 6, gy - 10, 5, 10), ink)
		draw_rect(Rect2(fx - 5, gy - 9, 3, 9), pants)
		draw_rect(Rect2(fx, gy - 10, 7, 4), ink)
		draw_rect(Rect2(fx + 1, gy - 9, 5, 2), pants)
		draw_rect(Rect2(fx + 3, gy - 7, 5, 7), ink)
		draw_rect(Rect2(fx + 4, gy - 6, 3, 6), pants)
		draw_texture_rect_region(fr, Rect2(fx - 12, top1, 24, 23), Rect2(1, 1, 24, 23))
		return
	var top := gy - 28.0
	draw_rect(Rect2(fx - 9, gy - 4, 8, 4), ink)
	draw_rect(Rect2(fx - 8, gy - 3, 7, 2), pants)
	draw_rect(Rect2(fx - 4, gy - 7, 5, 7), ink)
	draw_rect(Rect2(fx - 3, gy - 6, 3, 5), pants)
	draw_rect(Rect2(fx, gy - 7, 8, 5), ink)
	draw_rect(Rect2(fx + 1, gy - 6, 6, 3), pants)
	draw_rect(Rect2(fx + 4, gy - 4, 5, 4), ink)
	draw_rect(Rect2(fx + 5, gy - 3, 3, 3), pants)
	draw_texture_rect_region(fr, Rect2(fx - 12, top, 24, 23), Rect2(1, 1, 24, 23))
