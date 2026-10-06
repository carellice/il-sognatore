extends Control
## Controlli a zone (GDD, "Gameplay e controlli"): joystick dinamico su metà schermo,
## tap = salto e swipe = abilità sull'altra metà, pausa nell'angolo in alto.
## Tastiera e controller Bluetooth sono sempre attivi in parallelo.

const SWIPE_DIST := 14.0
const SWIPE_TIME := 0.3
const HOLD_WHEEL := 0.3

var game
var joy_id := -1
var joy_origin := Vector2.ZERO
var joy_pos := Vector2.ZERO
var jump_id := -1
var jump_start := Vector2.ZERO
var jump_t0 := 0.0
var swiped := false
var sel_id := -1
var sel_t0 := 0.0
var wheel_open := false
var wheel_pick := -1
var show_selector := false

var _move := 0.0
var _jh := false
var _jp := false
var _ab := false
var _abx := 0.0
var _undo := false
var _pause := false
var _prev := {}

# mano fantasma del tutorial: "", "drag", "tap", "hold", "swipe"
var ghost := ""
var ghost_t := 0.0
var used_touch := false


func _ready() -> void:
	G.full(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	used_touch = DisplayServer.is_touchscreen_available()


func _lefty() -> bool:
	return Save.settings["lefty"]


func _joy_side(p: Vector2) -> bool:
	return (p.x < size.x * 0.5) != _lefty()


func pause_rect() -> Rect2:
	var m: float = game.safe_margin
	if _lefty():
		return Rect2(m, 0, 30, 26)
	return Rect2(size.x - 30 - m, 0, 30, 26)


func selector_rect() -> Rect2:
	var m: float = game.safe_margin
	if _lefty():
		return Rect2(m + 6, size.y - 112, 30, 30)
	return Rect2(size.x - 36 - m, size.y - 112, 30, 30)


func _input(ev: InputEvent) -> void:
	if game == null or game.state != "play":
		return
	if ev is InputEventScreenTouch:
		used_touch = true
		var p: Vector2 = ev.position
		if ev.pressed:
			if pause_rect().grow(6).has_point(p):
				_pause = true
			elif show_selector and selector_rect().grow(8).has_point(p):
				sel_id = ev.index
				sel_t0 = _now()
			elif _joy_side(p):
				if joy_id == -1:
					joy_id = ev.index
					joy_origin = p
					joy_pos = p
			elif jump_id == -1:
				jump_id = ev.index
				jump_start = p
				jump_t0 = _now()
				swiped = false
				_jp = true
				_jh = true
		else:
			if ev.index == joy_id:
				joy_id = -1
				_move = 0.0
			elif ev.index == jump_id:
				jump_id = -1
				_jh = false
			elif ev.index == sel_id:
				sel_id = -1
				if wheel_open:
					wheel_open = false
					if wheel_pick >= 0:
						game.player.sel = wheel_pick
						Snd.play("select")
				else:
					game.cycle_ability()
	elif ev is InputEventScreenDrag:
		var p: Vector2 = ev.position
		if ev.index == joy_id:
			joy_pos = p
			var radius: float = 34.0 * Save.settings["joy_size"]
			var dx := p.x - joy_origin.x
			# il joystick segue il dito se esce dal raggio
			if absf(dx) > radius:
				joy_origin.x = p.x - signf(dx) * radius
				dx = signf(dx) * radius
			var v := dx / radius
			_move = 0.0 if absf(v) < 0.1 else clampf(v * 1.6, -1.0, 1.0)
		elif ev.index == jump_id:
			var d := p - jump_start
			if not swiped and d.length() > SWIPE_DIST and _now() - jump_t0 < SWIPE_TIME:
				swiped = true
				_ab = true
				_abx = signf(d.x) if absf(d.x) > absf(d.y) else 0.0
				_undo = _now() - jump_t0 < 0.16
				_jh = false
		elif ev.index == sel_id and wheel_open:
			var c := selector_rect().get_center() + _wheel_offset()
			var d := p - c
			wheel_pick = -1
			if d.length() > 12.0:
				var n: int = game.player.actives.size()
				wheel_pick = int(round(fposmod(d.angle() + PI * 0.5, TAU) / TAU * n)) % n


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_pause = true


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _wheel_offset() -> Vector2:
	return Vector2(60 if _lefty() else -60, -30)


func _edge(name: String, down: bool) -> bool:
	var was: bool = _prev.get(name, false)
	_prev[name] = down
	return down and not was


## Stato dei comandi per questo tick (tocco + tastiera + controller).
func poll() -> Dictionary:
	if sel_id != -1 and not wheel_open and _now() - sel_t0 > HOLD_WHEEL and game.player.actives.size() > 1:
		wheel_open = true
		wheel_pick = -1
	var mx := _move
	var kl := Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A)
	var kr := Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D)
	if kl != kr:
		mx = -1.0 if kl else 1.0
	var kjump := Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_Z) or Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W)
	var kab := Input.is_physical_key_pressed(KEY_X) or Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_K)
	var kcyc := Input.is_physical_key_pressed(KEY_C) or Input.is_physical_key_pressed(KEY_Q)
	var kpause := Input.is_physical_key_pressed(KEY_ESCAPE) or Input.is_physical_key_pressed(KEY_P)
	for pad in Input.get_connected_joypads():
		var ax := Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)
		if absf(ax) > 0.25:
			mx = clampf(ax * 1.3, -1.0, 1.0)
		if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_LEFT):
			mx = -1.0
		if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_RIGHT):
			mx = 1.0
		kjump = kjump or Input.is_joy_button_pressed(pad, JOY_BUTTON_A)
		kab = kab or Input.is_joy_button_pressed(pad, JOY_BUTTON_X) or Input.is_joy_button_pressed(pad, JOY_BUTTON_B)
		kcyc = kcyc or Input.is_joy_button_pressed(pad, JOY_BUTTON_RIGHT_SHOULDER) or Input.is_joy_button_pressed(pad, JOY_BUTTON_LEFT_SHOULDER)
		kpause = kpause or Input.is_joy_button_pressed(pad, JOY_BUTTON_START)
	if not G.debug_keys.is_empty():
		if G.debug_keys.has("right"):
			mx = 1.0
		if G.debug_keys.has("left"):
			mx = -1.0
		if G.debug_keys.has("jump"):
			kjump = Engine.get_physics_frames() % 50 < 30
		if G.debug_keys.has("ab"):
			kab = Engine.get_physics_frames() % 90 < 5
	var out := {
		"mx": mx,
		"jp": _jp or _edge("jump", kjump),
		"jh": _jh or kjump,
		"ab_swipe": _ab or _edge("ab", kab),
		"abx": _abx,
		"undo": _undo,
		"pause": _pause or _edge("pause", kpause),
	}
	if _edge("cycle", kcyc):
		game.cycle_ability()
	_jp = false
	_ab = false
	_abx = 0.0
	_undo = false
	_pause = false
	return out


func reset() -> void:
	joy_id = -1
	jump_id = -1
	sel_id = -1
	wheel_open = false
	_move = 0.0
	_jh = false
	_jp = false
	_ab = false
	_pause = false


func show_ghost(kind: String) -> void:
	ghost = kind
	ghost_t = 0.0


func _process(dt: float) -> void:
	ghost_t += dt
	queue_redraw()


func _draw() -> void:
	if game == null or game.state != "play":
		return
	var alpha: float = Save.settings["joy_alpha"]
	# joystick
	if joy_id != -1:
		var radius: float = 34.0 * Save.settings["joy_size"]
		draw_circle(joy_origin, radius, Color(0.04, 0.05, 0.13, alpha * 0.3))
		draw_arc(joy_origin, radius, 0.0, TAU, 32, Color(1, 1, 1, alpha * 0.75), 1.5)
		draw_rect(Rect2(joy_origin + Vector2(-radius + 5, 0), Vector2(3, 1)), Color(1, 1, 1, alpha * 0.6))
		draw_rect(Rect2(joy_origin + Vector2(radius - 8, 0), Vector2(3, 1)), Color(1, 1, 1, alpha * 0.6))
		var knob := joy_origin + Vector2(clampf(joy_pos.x - joy_origin.x, -radius, radius), 0)
		var kr: float = 10.0 * Save.settings["joy_size"]
		draw_circle(knob + Vector2(0, 1), kr, Color(0, 0, 0, alpha * 0.25))
		draw_circle(knob, kr, Color(1, 1, 1, alpha * 0.75))
		draw_circle(knob - Vector2(kr * 0.25, kr * 0.3), kr * 0.4, Color(1, 1, 1, alpha * 0.5))
	# pausa
	var pr := pause_rect()
	draw_style_box(Art.hud_box(), Rect2(pr.position.x + 6, 3, 18, 16))
	draw_texture(Art.tex("pause"), Vector2(pr.position.x + 13, 8).round(), Color(1, 1, 1, 0.9))
	# selettore di abilità
	if show_selector and not game.player.actives.is_empty():
		var r := selector_rect()
		var ab: String = game.player.ability()
		draw_style_box(Art.hud_box(G.ABILITY_COLOR[ab]), r)
		var icon := Art.tex("ic_" + ab)
		draw_texture(icon, (r.get_center() - icon.get_size() * 0.5).round())
		var cd: float = game.player.b.cd.get(ab, 0.0)
		if cd > 0.0:
			var k := clampf(cd / maxf(0.1, game.cd_total(ab)), 0.0, 1.0)
			draw_rect(Rect2(r.position.x + 2, r.position.y + 2 + (r.size.y - 4) * (1.0 - k), r.size.x - 4, (r.size.y - 4) * k), Color(0, 0, 0, 0.6))
		if wheel_open:
			var c := r.get_center() + _wheel_offset()
			draw_circle(c, 44.0, Color(0.04, 0.05, 0.13, 0.8))
			draw_arc(c, 44.0, 0.0, TAU, 40, Color(1, 1, 1, 0.3), 1.0)
			var n: int = game.player.actives.size()
			for i in range(n):
				var a := i * TAU / n - PI * 0.5
				var p := c + Vector2(cos(a), sin(a)) * 30.0
				var name: String = game.player.actives[i]
				var ic := Art.tex("ic_" + name)
				if i == wheel_pick:
					draw_circle(p, 11.0, Color(1, 1, 1, 0.3))
				draw_texture(ic, (p - ic.get_size() * 0.5).round())
				var c2: float = game.player.b.cd.get(name, 0.0)
				if c2 > 0.0:
					draw_arc(p, 9.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(c2 / game.cd_total(name), 0.0, 1.0), 16, Color(1, 1, 1, 0.7), 1.0)
	# mano fantasma
	if ghost != "":
		_draw_ghost()


func _draw_ghost() -> void:
	var hand := Art.tex("hand")
	var col := Color(1, 1, 1, 0.55)
	var left := Vector2(size.x * 0.22, size.y * 0.66)
	var right := Vector2(size.x * 0.78, size.y * 0.66)
	if _lefty():
		var tmp := left
		left = right
		right = tmp
	var k := fmod(ghost_t, 1.6) / 1.6
	var p := right
	var pressed := true
	match ghost:
		"drag":
			p = left + Vector2(sin(k * TAU) * 26.0, 0)
			draw_arc(left, 30.0, 0.0, TAU, 24, Color(1, 1, 1, 0.3), 1.0)
		"tap":
			pressed = k < 0.25
		"hold":
			pressed = k < 0.75
			if pressed:
				draw_arc(p, 6.0 + k * 14.0, 0.0, TAU, 20, Color(1, 1, 1, 0.4), 1.0)
		"swipe":
			p = right + Vector2(-22.0 + clampf(k * 2.2, 0.0, 1.0) * 44.0, 0)
			pressed = k < 0.5
			draw_line(right + Vector2(-22, 12), right + Vector2(22, 12), Color(1, 1, 1, 0.3), 1.0)
		"swipe_up":
			p = right + Vector2(0, 22.0 - clampf(k * 2.2, 0.0, 1.0) * 44.0)
			pressed = k < 0.5
		"icon":
			p = selector_rect().get_center()
			pressed = k < 0.3
	if pressed:
		draw_circle(p, 5.0, Color(1, 1, 1, 0.35))
	draw_texture(hand, (p + Vector2(-5, 0 if pressed else -4)).round(), col)
	if not used_touch:
		var keys := {"drag": "A D / ← →", "tap": "SPAZIO", "hold": "SPAZIO (tieni)", "swipe": "X", "swipe_up": "X", "icon": "C"}
		var txt: String = keys.get(ghost, "")
		draw_string(Art.font, Vector2(size.x * 0.5 - 30, size.y - 14), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.85))
