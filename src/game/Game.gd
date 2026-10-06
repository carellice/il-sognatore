extends Node2D
## Scena di un livello: costruisce la mappa dal generatore, fa avanzare il mondo
## un tick alla volta (ordine fisso: piattaforme, giocatore, nemici, oggetti)
## e gestisce vite, checkpoint, pausa e fine livello.

const LevelGen = preload("res://src/gen/LevelGen.gd")
const Player = preload("res://src/game/Player.gd")
const Enemy = preload("res://src/game/Enemy.gd")
const Controls = preload("res://src/game/Controls.gd")
const Hud = preload("res://src/game/Hud.gd")
const Background = preload("res://src/game/Background.gd")
const Fx = preload("res://src/game/Fx.gd")
const Echo = preload("res://src/game/Echo.gd")
const Bosses = preload("res://src/game/bosses/Bosses.gd")
const UI = preload("res://src/ui/UI.gd")

const GESTURES := {
	"tut_move": "drag", "tut_jump": "tap", "tut_high": "hold",
	"ab_doppio": "tap", "ab_scatto": "swipe", "ab_bolla": "swipe_up", "ab_gravita": "swipe_up",
	"ab_tempo": "swipe", "ab_schianto": "swipe", "ab_riflesso": "swipe", "ab_planata": "hold",
	"ab_selettore": "icon",
}

var lv
var world := 1
var level := 1
var postgame := false
var state := "play"
var player
var echo
var fx
var controls
var hud
var bg
var tilemap: TileMapLayer
var shade: Sprite2D
var stage3d: Node3D
var shade_dist := PackedInt32Array()
var cam: Camera2D
var ui_layer: CanvasLayer
var flash_rect: ColorRect
var overlay: Control

var enemies: Array = []
var shots: Array = []
var pickups := {}
var cps: Array = []
var movers: Array = []
var blades: Array = []
var switches: Array = []
var hint_ents: Array = []
var updrafts: Array = []
var boss = null
var portal: Node2D
var portal_rect := Rect2()
var portal_active := true
var secret_pos := Vector2.ZERO
var secret_found := false
var frags := 0
var time := 0.0
var slow_t := 0.0
var clone: Sprite2D
var clone_t := 0.0
var clone_plat := {}
var trail: Array = []
var cam_x := 0.0
var cam_y := 0.0
var view_w := 480.0
var view_h := 270.0
var safe_margin := 0.0
var shake_amt := 0.0
var cp_idx := 0
var cp_feet := Vector2.ZERO
var collected := {}
var last_inp := {}
var dead_t := 0.0
var seen_kinds := {}
var hint_i := 0
var hint_cur := ""
var hint_t := 0.0
var wake_t := 0.0


func _ready() -> void:
	world = G.req["world"]
	level = G.req["level"]
	var run: Dictionary = Save.run
	postgame = run.get("finished", false)
	lv = LevelGen.build(run["seed"], world, level, {"skip_tut": run.get("skip_tut", false), "attempts": run.get("attempts", {})})
	_measure()
	get_viewport().size_changed.connect(_measure)

	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	bg = Background.new()
	bg.only_fx = G.main != null and G.main.use_3d()
	bg.setup(world)
	bg_layer.add_child(bg)

	tilemap = TileMapLayer.new()
	tilemap.tile_set = Art.tileset(world)
	tilemap.scale = Vector2(0.5, 0.5)
	add_child(tilemap)
	_build_tiles()
	shade = Sprite2D.new()
	shade.centered = false
	shade.scale = Vector2(G.TILE, G.TILE)
	shade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(shade)
	_build_shade()
	if bg.only_fx:
		shade.visible = false
		stage3d = preload("res://src/game/Stage3D.gd").new()
		G.main.vp3d.add_child(stage3d)
		stage3d.setup(self)
		G.main.set_3d(true)

	fx = Fx.new()
	fx.z_index = 10
	player = Player.new()
	player.setup(self, world, postgame)
	echo = Echo.new()
	echo.setup(self, world)

	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	hud = Hud.new()
	hud.game = self
	ui_layer.add_child(hud)
	controls = Controls.new()
	controls.game = self
	controls.show_selector = not player.actives.is_empty()
	ui_layer.add_child(controls)
	flash_rect = ColorRect.new()
	G.full(flash_rect)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(0, 0, 0, 0)
	ui_layer.add_child(flash_rect)

	cp_feet = Vector2(lv.start.x * G.TILE + 8.0, (lv.start.y + 1) * G.TILE)
	var cp: Dictionary = run.get("cp", {})
	var resume: bool = G.req.get("from_cp", false) and int(cp.get("world", 0)) == world and int(cp.get("level", 0)) == level
	if resume:
		cp_idx = int(cp.get("idx", 0))
		for k in cp.get("collected", []):
			collected[k] = true
		secret_found = cp.get("secret", false)
		time = cp.get("t", 0.0)
		frags = int(cp.get("frags", 0))
	_spawn()
	_build_decor()
	add_child(player)
	add_child(echo)
	add_child(fx)
	player.hp = clampi(int(run.get("hp", G.MAX_HP)), 1, G.MAX_HP) if resume else G.MAX_HP
	player.place(cp_feet)
	echo.position = player.position + Vector2(-14, -30)

	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	cam_x = player.b.x
	cam_y = player.b.y
	_camera(1.0, true)
	Snd.music("boss" if lv.boss else "w%d" % world)
	if lv.boss and boss != null:
		portal_active = false
		portal.visible = false
	run["world"] = world
	run["level"] = level
	Save.save_run()


func _measure() -> void:
	var vs := get_viewport_rect().size
	view_w = vs.x
	view_h = vs.y
	safe_margin = 0.0
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		var scr := DisplayServer.screen_get_size()
		if scr.x > 0:
			var k := view_w / float(scr.x)
			safe_margin = maxf(safe.position.x, scr.x - safe.end.x) * k


# ------------------------------------------------------------------ costruzione

func _is_wall(tx: int, ty: int) -> bool:
	if tx < 0 or tx >= lv.w:
		return true
	if ty < 0:
		return false
	if ty >= lv.h:
		return true
	var t: int = lv.cells[ty * lv.w + tx]
	return t == G.T_SOLID or t == G.T_FAKE


## Ombra morbida all'interno del terreno: più ci si allontana dalla superficie,
## più la roccia è scura. Un pixel per casella, ingrandito con filtro lineare.
func _build_shade() -> void:
	var w: int = lv.w
	var h: int = lv.h
	var d := PackedInt32Array()
	d.resize(w * h)
	for ty in range(h):
		for tx in range(w):
			d[ty * w + tx] = 9 if _is_wall(tx, ty) else 0
	for ty in range(h):
		for tx in range(w):
			var i := ty * w + tx
			if d[i] == 0:
				continue
			var m := d[i]
			if ty > 0:
				m = mini(m, d[i - w] + 1)
				if tx > 0:
					m = mini(m, d[i - w - 1] + 1)
				if tx < w - 1:
					m = mini(m, d[i - w + 1] + 1)
			else:
				m = 1
			if tx > 0:
				m = mini(m, d[i - 1] + 1)
			d[i] = m
	for ty in range(h - 1, -1, -1):
		for tx in range(w - 1, -1, -1):
			var i := ty * w + tx
			if d[i] == 0:
				continue
			var m := d[i]
			if ty < h - 1:
				m = mini(m, d[i + w] + 1)
				if tx > 0:
					m = mini(m, d[i + w - 1] + 1)
				if tx < w - 1:
					m = mini(m, d[i + w + 1] + 1)
			if tx < w - 1:
				m = mini(m, d[i + 1] + 1)
			d[i] = m
	shade_dist = d
	var col: Color = G.pal(world, "dark").darkened(0.55)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for ty in range(h):
		for tx in range(w):
			col.a = clampf((d[ty * w + tx] - 1.0) / 3.0, 0.0, 1.0) * (0.22 if world == 2 else 0.62)
			img.set_pixel(tx, ty, col)
	shade.texture = ImageTexture.create_from_image(img)


func _build_tiles() -> void:
	for ty in range(lv.h):
		for tx in range(lv.w):
			_paint(tx, ty)
			if lv.cells[ty * lv.w + tx] == G.T_UPDRAFT:
				updrafts.append(Vector2i(tx, ty))


func _paint(tx: int, ty: int) -> void:
	var t: int = lv.tile(tx, ty)
	var at := Vector2i(-1, -1)
	match t:
		G.T_SOLID:
			var mask := 0
			if not _is_wall(tx, ty - 1):
				mask |= 1
			if not _is_wall(tx + 1, ty):
				mask |= 2
			if not _is_wall(tx, ty + 1):
				mask |= 4
			if not _is_wall(tx - 1, ty):
				mask |= 8
			at = Art.at_solid(mask, tx, ty)
		G.T_ONEWAY:
			at = Art.AT_ONEWAY
		G.T_SPIKE:
			at = Art.AT_SPIKE
		G.T_SPIKE_D:
			at = Art.AT_SPIKE_D
		G.T_CRATE:
			at = Art.AT_CRATE
		G.T_BOUNCY:
			at = Art.AT_BOUNCY
		G.T_FAKE:
			at = Art.at_fake(not _is_wall(tx, ty - 1), tx, ty)
		G.T_DOOR:
			at = Art.AT_DOOR
		G.T_UPDRAFT:
			at = Art.AT_UPDRAFT
	if at.x >= 0 and (t == G.T_SOLID or t == G.T_FAKE) and bg.only_fx:
		at = Vector2i(-1, -1)
	if at.x >= 0:
		tilemap.set_cell(Vector2i(tx, ty), 0, at)
	else:
		tilemap.erase_cell(Vector2i(tx, ty))


func _spawn() -> void:
	var agitato: bool = Save.run.get("mode", "") == "agitato"
	for e in lv.ents:
		var cell := Vector2i(e["x"], e["y"])
		var center := Vector2(cell.x * G.TILE + 8.0, cell.y * G.TILE + 8.0)
		var key := "%d,%d" % [cell.x, cell.y]
		match e["t"]:
			"frag", "life", "secret":
				var kind: String = e["t"]
				if kind == "life" and not agitato:
					kind = "frag"
				if kind == "secret":
					secret_pos = center
					if secret_found:
						continue
				if collected.has(key):
					continue
				var s := Sprite2D.new()
				s.texture = Art.tex(kind)
				s.position = center
				s.z_index = 3
				add_child(s)
				match kind:
					"frag":
						s.add_child(Art.light(Color("ffc94a"), 15.0, 0.4))
					"life":
						s.add_child(Art.light(Color("ff6a6a"), 22.0, 0.45))
					"secret":
						s.add_child(Art.light(Color("c9a8ff"), 30.0, 0.6))
				pickups[cell] = {"node": s, "t": kind, "key": key}
			"cp":
				var s := Sprite2D.new()
				var on: bool = int(e["idx"]) == cp_idx
				s.texture = Art.tex("cp_on" if on else "cp_off")
				s.position = center + Vector2(0, 0)
				add_child(s)
				var lamp: Sprite2D = Art.light(Color("ffd65a"), 34.0, 0.55)
				lamp.visible = on
				s.add_child(lamp)
				var feet := Vector2(center.x, (cell.y + 1) * G.TILE)
				var lamp3d = stage3d.add_lamp(center, Color("ffd27a"), 5.0, 1.3) if stage3d != null else null
				if lamp3d != null:
					lamp3d.visible = on
				cps.append({"idx": int(e["idx"]), "node": s, "feet": feet, "on": on, "lamp": lamp, "lamp3d": lamp3d})
				if on:
					cp_feet = feet
			"portal":
				portal = preload("res://src/game/Portal.gd").new()
				portal.position = Vector2(center.x, (cell.y + 1) * G.TILE)
				add_child(portal)
				portal_rect = Rect2(center.x - 8, (cell.y + 1) * G.TILE - 30, 16, 30)
				if stage3d != null:
					stage3d.add_lamp(center + Vector2(0, -8), Color("fff0b0"), 7.0, 1.6)
			"enemy":
				var en = Enemy.new()
				add_child(en)
				en.setup(self, e["kind"], cell, e.get("shadow", false))
				enemies.append(en)
			"switch":
				var s := Sprite2D.new()
				s.texture = Art.tex("switch_up")
				s.position = Vector2(center.x, (cell.y + 1) * G.TILE - 3)
				add_child(s)
				switches.append({"node": s, "rect": Rect2(cell.x * G.TILE, (cell.y + 1) * G.TILE - 8, 16, 10), "x0": e["x0"], "x1": e["x1"], "down": false})
			"mover":
				var m := Sprite2D.new()
				m.texture = _mover_tex()
				m.centered = false
				add_child(m)
				var home := Vector2(cell.x * G.TILE, cell.y * G.TILE)
				var plat := {"x": home.x, "y": home.y, "w": 32.0, "dx": 0.0, "dy": 0.0}
				lv.platforms.append(plat)
				movers.append({"node": m, "home": home, "axis": e["axis"], "t": cell.x * 0.7, "plat": plat})
			"blade":
				var s := Sprite2D.new()
				s.texture = Art.tex("blade")
				s.z_index = 3
				add_child(s)
				blades.append({"node": s, "home": center, "axis": e["axis"], "t": cell.x * 0.9, "pos": center})
			"hint":
				hint_ents.append({"x": cell.x * G.TILE, "n": int(e["n"])})
			"boss":
				boss = Bosses.create(world)
				if boss != null:
					add_child(boss)
					boss.setup(self, Vector2(center.x, (cell.y + 1) * G.TILE))
	hint_ents.sort_custom(func(a, c): return a["x"] < c["x"])


## Decorazioni sul terreno, scelte in modo fisso dalla posizione (niente casualità:
## lo stesso livello ha sempre lo stesso aspetto). Mai dove c'è un oggetto di gioco.
func _build_decor() -> void:
	var kinds: Array = Art.decor(world)
	var busy := {}
	for e in lv.ents:
		for dx in range(-1, 2):
			busy[Vector2i(int(e["x"]) + dx, int(e["y"]))] = true
	for dx in range(-2, 3):
		busy[Vector2i(int(lv.start.x) + dx, int(lv.start.y))] = true
	var last := -9
	for tx in range(1, lv.w - 1):
		for ty in range(3, lv.h):
			if lv.tile(tx, ty) != G.T_SOLID or lv.tile(tx, ty - 1) != G.T_EMPTY or lv.tile(tx, ty - 2) != G.T_EMPTY:
				continue
			var hsh := (tx * 7919 + ty * 104729 + world * 31) % 100
			if hsh >= 13 or tx - last < 2 or busy.has(Vector2i(tx, ty - 1)):
				continue
			last = tx
			var d: Array = kinds[(tx * 13 + ty * 7) % kinds.size()]
			var tex: Texture2D = d[0]
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.position = Vector2(tx * G.TILE + (G.TILE - tex.get_width()) / 2 + (hsh % 5) - 2, ty * G.TILE - tex.get_height() + 1)
			s.flip_h = hsh % 2 == 0
			add_child(s)
			if d[1] != "":
				if stage3d != null:
					stage3d.add_lamp(s.position + Vector2(tex.get_width() * 0.5, 4), Color(d[1]), 4.5, 1.1)
				var l: Sprite2D = Art.light(Color(d[1]), 34.0, 0.4)
				l.position = Vector2(tex.get_width() * 0.5, 3)
				s.add_child(l)


func _mover_tex() -> Texture2D:
	var img := Image.create(32, 6, false, Image.FORMAT_RGBA8)
	img.fill(G.pal(world, "top"))
	img.fill_rect(Rect2i(0, 0, 32, 1), G.pal(world, "top").lightened(0.3))
	img.fill_rect(Rect2i(0, 4, 32, 2), G.pal(world, "dark"))
	img.fill_rect(Rect2i(3, 2, 2, 2), G.pal(world, "accent"))
	img.fill_rect(Rect2i(27, 2, 2, 2), G.pal(world, "accent"))
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ ciclo di gioco

func _physics_process(delta: float) -> void:
	match state:
		"play":
			_tick(delta)
		"dead":
			fx.tick(delta)
			dead_t -= delta
			if dead_t <= 0.0:
				_after_death()
		"wake":
			wake_t -= delta
			if wake_t <= 0.0:
				G.goto("game", {"world": world, "level": 1})
				state = "leaving"
		"win":
			fx.tick(delta)
			if portal != null:
				portal.t += delta


func _tick(delta: float) -> void:
	var inp: Dictionary = controls.poll()
	last_inp = inp
	if inp["pause"]:
		open_pause()
		return
	var dt := delta * (0.25 if controls.wheel_open else 1.0)
	time += dt
	if slow_t > 0.0:
		slow_t -= dt
		if slow_t <= 0.0:
			_tint(Color.WHITE)
	var wdt := dt * (G.SLOW_SCALE if slow_t > 0.0 else 1.0)

	var omega := 3.4 if world == 6 else 1.5
	for m in movers:
		m["t"] += wdt * omega
		var off: float = sin(m["t"]) * 40.0
		var np: Vector2 = m["home"] + (Vector2(off, 0) if m["axis"] == "h" else Vector2(0, off))
		var plat: Dictionary = m["plat"]
		plat["dx"] = np.x - plat["x"]
		plat["dy"] = np.y - plat["y"]
		plat["x"] = np.x
		plat["y"] = np.y
		m["node"].position = np.round()
	_tick_clone(dt)

	player.tick(inp, dt)
	trail.append([player.b.x, player.b.feet(), player.b.facing, player.anim, player.b.g])
	if trail.size() > 150:
		trail.pop_front()
	if state != "play":
		return

	for en in enemies:
		en.tick(wdt)
	if boss != null and not boss.dead:
		boss.tick(wdt)
	_tick_shots(wdt)
	_tick_blades(wdt)
	_tick_switches()
	_tick_pickups()
	_tick_hints(dt)
	_tick_fake_walls()
	echo.tick(dt)
	fx.tick(dt)
	if portal != null:
		portal.t += dt
		if portal_active and portal_rect.intersects(player.b.rect()):
			_win()
			return
	if not updrafts.is_empty() and randf() < 0.5:
		var c: Vector2i = updrafts[randi() % updrafts.size()]
		if absf(c.x * G.TILE - cam_x) < view_w * 0.6:
			fx.parts.append({"p": Vector2(c.x * G.TILE + randf() * 16.0, c.y * G.TILE + 16.0), "v": Vector2(0, -70), "l": 0.5, "c": Color(1, 1, 1, 0.5), "g": 0.0})
	_camera(dt, false)


func _camera(dt: float, snap: bool) -> void:
	var p = player.b
	var tx: float = p.x + p.facing * 22.0
	var k := 1.0 if snap else 1.0 - exp(-6.0 * dt)
	cam_x = lerpf(cam_x, tx, k)
	var lw: float = lv.w * G.TILE
	var lh: float = lv.h * G.TILE
	if lw <= view_w:
		cam_x = lw * 0.5
	else:
		cam_x = clampf(cam_x, view_w * 0.5, lw - view_w * 0.5)
	if lh <= view_h + 4.0:
		cam_y = lh - view_h * 0.5
	else:
		cam_y = clampf(lerpf(cam_y, p.y - 10.0, k), view_h * 0.5, lh - view_h * 0.5)
	shake_amt = move_toward(shake_amt, 0.0, dt * 14.0)
	var sh := Vector2.ZERO
	if shake_amt > 0.0 and not Save.settings["reduce_fx"]:
		sh = Vector2(randf_range(-shake_amt, shake_amt), randf_range(-shake_amt, shake_amt))
	cam.position = (Vector2(cam_x, cam_y) + sh).round()
	if stage3d != null:
		stage3d.sync(cam.position, Vector2(view_w, view_h))
	bg.cam_x = cam_x
	bg.cam_y = cam_y - (lh - view_h * 0.5)


func _tick_shots(wdt: float) -> void:
	var pr: Rect2 = player.b.rect().grow(-1.0)
	for s in shots:
		s["v"].y += s["g"] * wdt
		s["p"] += s["v"] * wdt
		s["l"] -= wdt
		s["node"].position = s["p"].round()
		var cell := Vector2i(int(floor(s["p"].x / G.TILE)), int(floor(s["p"].y / G.TILE)))
		if lv.solid(cell.x, cell.y) and not s.get("ghost", false):
			s["l"] = 0.0
		elif pr.grow(s.get("r", 2.0)).has_point(s["p"]):
			player.hurt(1, s["p"].x)
			s["l"] = 0.0
		if s["l"] <= 0.0:
			s["node"].queue_free()
	shots = shots.filter(func(s): return s["l"] > 0.0)


func shoot(pos: Vector2, vel: Vector2, grav: float, tex: String, life := 4.0, ghost := false) -> void:
	var n := Sprite2D.new()
	n.texture = Art.tex(tex)
	n.position = pos
	n.z_index = 6
	n.add_child(Art.light(G.pal(world, "accent"), 14.0, 0.45))
	add_child(n)
	shots.append({"node": n, "p": pos, "v": vel, "g": grav, "l": life, "ghost": ghost, "r": maxf(2.0, n.texture.get_width() * 0.4)})


func clear_shots() -> void:
	for s in shots:
		s["node"].queue_free()
	shots.clear()


func _tick_blades(wdt: float) -> void:
	var omega := 4.2 if world == 6 else 2.0
	var pc := Vector2(player.b.x, player.b.y)
	for bl in blades:
		bl["t"] += wdt * omega
		var off: float = sin(bl["t"]) * 40.0
		var pos: Vector2 = bl["home"] + (Vector2(off, 0) if bl["axis"] == "h" else Vector2(0, off))
		bl["node"].position = pos.round()
		bl["node"].rotation += wdt * 12.0
		var d := (pc - pos).abs()
		if d.x < player.b.hw + 5.0 and d.y < player.b.hh + 5.0:
			player.hurt(1, pos.x)


func _tick_switches() -> void:
	if switches.is_empty():
		return
	var groups := {}
	var pr := Rect2(player.b.x - 5.0, player.b.feet() - 4.0, 10.0, 6.0)
	for s in switches:
		var down: bool = s["rect"].intersects(pr) and player.b.on_ground
		if clone != null and s["rect"].intersects(Rect2(clone.position.x - 5.0, clone.position.y - 4.0, 10.0, 6.0)):
			down = true
		if boss != null and boss.has_method("presses") and boss.presses(s["rect"]):
			down = true
		if down != s["down"]:
			s["down"] = down
			s["node"].texture = Art.tex("switch_down" if down else "switch_up")
			if down:
				Snd.play("switch")
		var gk: int = s["x0"]
		if not groups.has(gk):
			groups[gk] = [0, 0, s["x1"]]
		groups[gk][0] += 1
		if down:
			groups[gk][1] += 1
	for gk in groups:
		var gr: Array = groups[gk]
		if gr[0] == gr[1]:
			if boss != null and boss.has_method("on_switches"):
				boss.on_switches()
			else:
				_open_doors(gk, gr[2])


func _open_doors(x0: int, x1: int) -> void:
	var opened := false
	for tx in range(x0, x1):
		for ty in range(lv.h):
			if lv.tile(tx, ty) == G.T_DOOR:
				lv.set_tile(tx, ty, G.T_EMPTY)
				tilemap.erase_cell(Vector2i(tx, ty))
				fx.burst(Vector2(tx * G.TILE + 8, ty * G.TILE + 8), G.pal(world, "accent"), 5, 50.0)
				opened = true
	if opened:
		Snd.play("secret")
		shake(2.0)


func _tick_pickups() -> void:
	var b = player.b
	for tx in range(int(floor((b.x - b.hw - 3.0) / G.TILE)), int(floor((b.x + b.hw + 3.0) / G.TILE)) + 1):
		for ty in range(int(floor((b.y - b.hh - 3.0) / G.TILE)), int(floor((b.y + b.hh + 3.0) / G.TILE)) + 1):
			var cell := Vector2i(tx, ty)
			if pickups.has(cell):
				_collect(cell)
	for c in cps:
		if not c["on"] and absf(b.x - c["feet"].x) < 12.0 and absf(b.feet() - c["feet"].y) < 28.0:
			_checkpoint(c)
	var tt := fmod(time * 4.0, 2.0) < 1.0
	if Engine.get_physics_frames() % 15 == 0:
		for cell in pickups:
			var pk: Dictionary = pickups[cell]
			if pk["t"] == "frag":
				pk["node"].texture = Art.tex("frag" if (tt != ((cell.x + cell.y) % 2 == 0)) else "frag2")


func _collect(cell: Vector2i) -> void:
	var pk: Dictionary = pickups[cell]
	pickups.erase(cell)
	collected[pk["key"]] = true
	var pos: Vector2 = pk["node"].position
	pk["node"].queue_free()
	var run: Dictionary = Save.run
	match pk["t"]:
		"frag":
			frags += 1
			run["fragments"] = int(run["fragments"]) + 1
			run["frag_bank"] = int(run["frag_bank"]) + 1
			Save.gallery["fragments"] = int(Save.gallery["fragments"]) + 1
			Snd.play("frag")
			buzz(5)
			fx.burst(pos, Color("ffd65a"), 4, 40.0, 0.0)
			if run["mode"] == "agitato" and run["frag_bank"] >= 100:
				run["frag_bank"] -= 100
				run["lives"] = int(run["lives"]) + 1
				Snd.play("life")
				echo.say(T.t("say_life"), 2.5)
		"life":
			run["lives"] = int(run["lives"]) + 1
			Snd.play("life")
			fx.ring(pos, Color("d9534f"))
		"secret":
			secret_found = true
			Snd.play("secret")
			buzz(30)
			fx.burst(pos, Color("c9a8ff"), 16, 80.0, 0.0)
			fx.ring(pos, Color("c9a8ff"))
			echo.say(T.t("say_secret"), 3.0)


func _checkpoint(c: Dictionary) -> void:
	for o in cps:
		o["on"] = false
		o["node"].texture = Art.tex("cp_off")
		o["lamp"].visible = false
		if o["lamp3d"] != null:
			o["lamp3d"].visible = false
	c["on"] = true
	c["lamp"].visible = true
	if c["lamp3d"] != null:
		c["lamp3d"].visible = true
	c["node"].texture = Art.tex("cp_on")
	cp_idx = c["idx"]
	cp_feet = c["feet"]
	Snd.play("checkpoint")
	fx.ring(c["feet"] - Vector2(0, 10), Color("ffd65a"))
	if lv.tutorial:
		pass
	save_progress()


## Salvataggio automatico: a ogni checkpoint e quando l'app va in background.
func save_progress() -> void:
	var run: Dictionary = Save.run
	run["hp"] = maxi(1, player.hp)
	run["cp"] = {"world": world, "level": level, "idx": cp_idx, "collected": collected.keys(), "secret": secret_found, "t": time, "frags": frags}
	Save.save_run()
	Save.save_global()


func _tick_hints(dt: float) -> void:
	if lv.hints.is_empty():
		return
	hint_t += dt
	while hint_i < hint_ents.size() and player.b.x >= hint_ents[hint_i]["x"]:
		var n: int = hint_ents[hint_i]["n"]
		hint_i += 1
		if n - 1 < lv.hints.size():
			hint_cur = lv.hints[n - 1]
			_show_hint()
	if hint_cur != "" and hint_t > 8.0 and hint_i < hint_ents.size():
		_show_hint()
	if hint_t > 6.0:
		controls.ghost = ""


func _show_hint() -> void:
	hint_t = 0.0
	echo.say(T.t(hint_cur), 5.0)
	controls.show_ghost(GESTURES.get(hint_cur, ""))


func _tick_fake_walls() -> void:
	var b = player.b
	var tx := int(floor(b.x / G.TILE))
	var ty := int(floor(b.y / G.TILE))
	if lv.tile(tx, ty) != G.T_FAKE:
		return
	var stack: Array = [Vector2i(tx, ty)]
	var broken_cells: Array = []
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		if lv.tile(c.x, c.y) != G.T_FAKE:
			continue
		lv.set_tile(c.x, c.y, G.T_EMPTY)
		tilemap.erase_cell(c)
		broken_cells.append(c)
		fx.burst(Vector2(c.x * G.TILE + 8, c.y * G.TILE + 8), G.pal(world, "ground"), 5, 50.0)
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			stack.append(c + d)
	_build_shade()
	if stage3d != null:
		stage3d.rebuild_cells(broken_cells)
	Snd.play("break")


# ------------------------------------------------------------------ abilità

func cd_total(ab: String) -> float:
	match ab:
		"tempo":
			return G.SLOW_TIME + G.SLOW_CD
		"riflesso":
			return G.CLONE_TIME + G.CLONE_CD
	return G.ABILITY_CD.get(ab, 1.0)


func cycle_ability() -> void:
	if player.actives.size() > 1:
		player.sel = (player.sel + 1) % player.actives.size()
		Snd.play("select")


func start_slow() -> void:
	slow_t = G.SLOW_TIME
	Snd.play("slow")
	_tint(Color(0.8, 0.85, 1.0))
	flash(Color(0.9, 0.8, 0.4, 0.25))


func _tint(c: Color) -> void:
	tilemap.modulate = c
	shade.modulate = c
	bg.tint = c


func spawn_clone() -> void:
	if clone != null:
		_end_clone()
	clone = Sprite2D.new()
	clone.modulate = Color(0.7, 0.95, 1.0, 0.75)
	clone.texture = player.frames["idle"]
	clone.z_index = 4
	clone.offset = Vector2(0, -17)
	add_child(clone)
	clone_t = G.CLONE_TIME
	clone_plat = {"x": 0.0, "y": -9999.0, "w": 16.0, "dx": 0.0, "dy": 0.0}
	lv.platforms.append(clone_plat)
	Snd.play("clone")
	_tick_clone(0.0)


func _tick_clone(dt: float) -> void:
	if clone == null:
		return
	clone_t -= dt
	if clone_t <= 0.0:
		_end_clone()
		return
	var e = trail_at(int(G.CLONE_DELAY * 60.0))
	if e == null:
		e = trail[0] if not trail.is_empty() else [player.b.x, player.b.feet(), 1, "idle", 1]
	clone.position = Vector2(round(e[0]), round(e[1]))
	clone.flip_h = e[2] < 0
	clone.texture = player.frames.get(e[3], player.frames["idle"])
	clone.visible = clone_t > 1.0 or int(clone_t * 10.0) % 2 == 0
	var top: float = e[1] - player.b.full_h
	clone_plat["dx"] = (e[0] - 8.0) - clone_plat["x"]
	clone_plat["dy"] = top - clone_plat["y"]
	if absf(clone_plat["dy"]) > 30.0:
		clone_plat["dy"] = 0.0
		clone_plat["dx"] = 0.0
	clone_plat["x"] = e[0] - 8.0
	clone_plat["y"] = top


func _end_clone() -> void:
	if clone == null:
		return
	fx.burst(clone.position - Vector2(0, 10), G.ABILITY_COLOR["riflesso"], 8, 50.0)
	clone.queue_free()
	clone = null
	clone_plat["dead"] = true
	lv.platforms.erase(clone_plat)


func trail_at(ticks_ago: int):
	var i := trail.size() - 1 - ticks_ago
	return trail[i] if i >= 0 else null


func on_crates_broken() -> void:
	for c in lv.broken:
		tilemap.erase_cell(c)
		fx.burst(Vector2(c.x * G.TILE + 8, c.y * G.TILE + 8), Color("d19a5c"), 7, 70.0)
	lv.broken.clear()
	shake(2.0)


# ------------------------------------------------------------------ effetti

func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)


func flash(c: Color) -> void:
	if Save.settings["reduce_fx"]:
		return
	flash_rect.color = c
	var tw := create_tween()
	tw.tween_property(flash_rect, "color:a", 0.0, 0.25)


func buzz(ms: int) -> void:
	if Save.settings["vibra"]:
		Input.vibrate_handheld(ms)


func cue(world_y: float) -> void:
	hud.cue(world_y - (cam_y - view_h * 0.5))


func note_seen(kind: String) -> void:
	if not seen_kinds.has(kind):
		seen_kinds[kind] = true
		Save.unlock_gallery("bestiary", kind)


func on_enemy_killed(_en) -> void:
	pass


## Solo per i test di flusso: prova la ripartenza durante un boss.
func on_player_respawn_test() -> void:
	if boss != null:
		boss.on_player_respawn(true)
		boss.on_player_respawn(false)


# ------------------------------------------------------------------ vite e morte

func player_fell() -> void:
	if state != "play":
		return
	if lv.tutorial or Save.settings["mod_god"]:
		# nel tutorial (e con l'immortalità di prova) non si perdono vite: si torna all'ultimo punto sicuro
		Snd.play("hurt")
		player.place(player.safe_pos)
		player.invuln = 1.0
		echo.say(T.t("say_careful"), 2.5)
		return
	player.die()


func player_died() -> void:
	state = "dead"
	dead_t = 1.0
	controls.reset()
	var run: Dictionary = Save.run
	run["deaths"] = int(run["deaths"]) + 1
	Save.gallery["deaths"] = int(Save.gallery["deaths"]) + 1
	_end_clone()
	slow_t = 0.0
	_tint(Color.WHITE)


func _after_death() -> void:
	var run: Dictionary = Save.run
	var mode: String = run["mode"]
	if lv.tutorial or mode == "lucido":
		_respawn()
	elif mode == "agitato":
		run["lives"] = int(run["lives"]) - 1
		if run["lives"] <= 0:
			_wake_up()
		else:
			_respawn()
	else:
		run["over"] = true
		run["time"] = float(run["time"]) + time
		Save.save_run()
		Save.save_global()
		state = "leaving"
		G.goto("gameover")


func _respawn() -> void:
	clear_shots()
	player.revive(cp_feet)
	trail.clear()
	if boss != null and not boss.dead:
		boss.on_player_respawn(Save.run["mode"] == "lucido")
	cam_x = player.b.x
	state = "play"
	save_progress()


## Sonno agitato, vite finite: Flavio "si sveglia" e riparte dall'inizio del mondo.
func _wake_up() -> void:
	var run: Dictionary = Save.run
	var snap: Dictionary = run.get("world_snap", {})
	run["fragments"] = int(snap.get("fragments", 0))
	run["frag_bank"] = int(snap.get("frag_bank", 0))
	var keep: Array = snap.get("secrets", [])
	for l in range(1, G.LEVELS + 1):
		var k := G.key(world, l)
		if run["secrets"].has(k) and not (k in keep):
			run["secrets"].erase(k)
	run["lives"] = 5
	run["hp"] = G.MAX_HP
	run["cp"] = {}
	run["level"] = 1
	if int(run["max_world"]) == world:
		run["max_level"] = 1
	run["time"] = float(run["time"]) + time
	Save.save_run()
	Save.save_global()
	state = "wake"
	wake_t = 2.6
	Snd.music("")
	Snd.play("wake")
	var arr := UI.panel(ui_layer, [UI.label(T.t("wake_title"), true), UI.label(T.t("wake_text"))], 0.85)
	overlay = arr[0]


# ------------------------------------------------------------------ fine livello

func _win() -> void:
	state = "win"
	controls.reset()
	Snd.play("portal")
	Snd.music("")
	fx.ring(portal.position - Vector2(0, 14), Color("fff3b0"))
	player.visible = false
	var run: Dictionary = Save.run
	var key := G.key(world, level)
	var first_secret: bool = secret_found and not run["secrets"].has(key)
	var rec: Dictionary = run["records"].get(key, {})
	var best_t: float = minf(float(rec.get("t", 99999.0)), time)
	run["records"][key] = {"t": best_t, "f": maxi(int(rec.get("f", 0)), frags), "s": secret_found or rec.get("s", false)}
	if secret_found:
		run["secrets"][key] = true
	var chain: Array = []
	var was_frontier: bool = world == int(run["max_world"]) and level == int(run["max_level"])
	if was_frontier:
		if level < G.LEVELS:
			run["max_level"] = level + 1
		elif world < 10:
			run["max_world"] = world + 1
			run["max_level"] = 1
			run["world_snap"] = {"fragments": run["fragments"], "frag_bank": run["frag_bank"], "secrets": run["secrets"].keys()}
			chain.append("after_%d" % world)
		else:
			run["finished"] = true
			Save.gallery["finished"] = int(Save.gallery["finished"]) + 1
			Save.gallery["incubo"] = true
			chain.append("finale")
	if first_secret and Save.world_secrets(world) == G.LEVELS:
		chain.append("memory_%d" % world)
		Save.unlock_gallery("memories", "memory_%d" % world)
	if first_secret and run["secrets"].size() >= 10 * G.LEVELS:
		chain.append("epilogue")
	if level < G.LEVELS:
		run["world"] = world
		run["level"] = level + 1
	elif world < 10:
		run["world"] = world + 1
		run["level"] = 1
	if not was_frontier and not run["finished"]:
		run["world"] = int(run["max_world"])
		run["level"] = int(run["max_level"])
	if lv.tutorial:
		Save.gallery["tut_done"] = true
	run["cp"] = {}
	run["hp"] = G.MAX_HP
	run["time"] = float(run["time"]) + time
	Save.gallery["time"] = float(Save.gallery["time"]) + time
	Save.save_run()
	Save.save_global()
	var total := 0
	for e in lv.ents:
		if e["t"] == "frag":
			total += 1
	var items: Array = [
		UI.label(T.t("level_done"), true, Color("fff3b0")),
		UI.label("%s  %d-%d" % [T.t("world_" + str(world)), world, level]),
		UI.label("%s: %d / %d" % [T.t("fragments"), frags, total]),
		UI.label("%s: %s" % [T.t("secret"), T.t("found") if secret_found else T.t("not_found")], false, Color("c9a8ff") if secret_found else Color("9aa0b4")),
		UI.label("%s: %s%s" % [T.t("time"), G.fmt_time(time), ("  " + T.t("record")) if time <= best_t and rec.has("t") else ""]),
		UI.button(T.t("continue"), func():
			state = "leaving"
			if chain.is_empty():
				G.goto("map", {"world": int(run["world"])})
			else:
				G.goto("cutscene", {"ids": chain, "then": "credits" if "finale" in chain else "map"})),
	]
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_callback(func():
		overlay = UI.panel(ui_layer, items, 0.55)[0])


# ------------------------------------------------------------------ pausa

func open_pause() -> void:
	if state != "play":
		return
	state = "pause"
	controls.reset()
	Snd.play("select")
	var items: Array = [
		UI.label(T.t("pause"), true),
		UI.button(T.t("resume"), close_pause),
		UI.button(T.t("restart_cp"), func():
			close_pause()
			clear_shots()
			player.revive(cp_feet)),
		UI.button(T.t("settings"), func():
			var s = preload("res://src/ui/Settings.gd").new()
			s.embedded = true
			overlay.visible = false
			ui_layer.add_child(s)
			s.closed.connect(func():
				overlay.visible = true
				UI.focus_first(overlay))),
		UI.button(T.t("to_map"), func():
			save_progress()
			state = "leaving"
			G.goto("map", {"world": world})),
		UI.button(T.t("quit_title"), func():
			save_progress()
			state = "leaving"
			G.goto("title")),
	]
	overlay = UI.panel(ui_layer, items, 0.6)[0]


func close_pause() -> void:
	if overlay != null:
		overlay.queue_free()
		overlay = null
	player.b.auto_high = Save.settings["auto_high"]
	state = "play"


func _unhandled_input(ev: InputEvent) -> void:
	if state == "pause" and ev is InputEventKey and ev.pressed and not ev.echo and ev.physical_keycode == KEY_ESCAPE:
		close_pause()


func _exit_tree() -> void:
	if stage3d != null:
		stage3d.queue_free()
		stage3d = null
		if G.main != null:
			G.main.set_3d(false)


func _notification(what: int) -> void:
	# pausa e salvataggio automatici quando l'app perde il focus o va in background
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if state == "play" and is_inside_tree():
			save_progress()
			if not ("--shot" in " ".join(OS.get_cmdline_user_args())):
				open_pause()
