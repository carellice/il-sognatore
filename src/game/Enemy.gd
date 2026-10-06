extends Node2D
## Nemici: un solo script, il comportamento è scelto dai dati di EnemyDefs.
## Si sconfiggono saltandoci sopra (o con lo schianto), salvo quelli invulnerabili.

const Phys = preload("res://src/game/Phys.gd")
const EnemyDefs = preload("res://src/game/EnemyDefs.gd")

var game
var kind := ""
var def := {}
var beh := ""
var b: Phys
var home := Vector2.ZERO
var alive := true
var t := 0.0
var dir := -1
var state := ""
var st := 0.0
var spr: Sprite2D
var guard_spr: Sprite2D
var shadow := false
var vulnerable := true
var dangerous := true
var seen := false
var bounces := 0
var vel := Vector2.ZERO
var target := Vector2.ZERO
var speed := 0.0
var frames := {}


func setup(g, k: String, cell: Vector2i, is_shadow: bool) -> void:
	game = g
	kind = k
	def = EnemyDefs.DEFS[k]
	beh = def["beh"]
	shadow = is_shadow
	speed = def.get("speed", 0.0)
	b = Phys.new()
	b.hw = def["w"] * 0.5
	b.hh = def["h"] * 0.5
	b.full_h = def["h"]
	b.x = cell.x * G.TILE + 8.0
	if def["slot"] == "g":
		b.y = (cell.y + 1) * G.TILE - b.hh
	elif def["slot"] == "c":
		b.g = -1
		b.y = cell.y * G.TILE + b.hh
	else:
		b.y = cell.y * G.TILE + 8.0
	home = Vector2(b.x, b.y)
	t = fmod(cell.x * 0.37, 3.0)
	spr = Sprite2D.new()
	add_child(spr)
	if beh == "copy":
		frames = Art.dark_player_frames(game.player.stage)
		spr.texture = frames["idle"]
		b.hh = game.player.b.full_h * 0.5
		b.y = (cell.y + 1) * G.TILE - b.hh
		home.y = b.y
		state = "idle"
	elif beh == "gust":
		spr.visible = false
	else:
		spr.texture = Art.shadow_tex(kind) if shadow else Art.tex(kind)
	if def.get("guard", false):
		guard_spr = Sprite2D.new()
		guard_spr.texture = Art.tex("guard")
		guard_spr.position = Vector2(0, -b.hh - 2)
		add_child(guard_spr)
	match beh:
		"shooter":
			state = "idle"
			st = def["rate"]
		"drop":
			state = "wait"
		"cross":
			state = "wait"
			st = 1.5 + fmod(cell.x * 0.61, 2.0)
			dangerous = false
		"pop":
			state = "closed" if def.get("pull", false) else "hidden"
			st = 1.0 + fmod(cell.x * 0.3, 1.5)
		"dive":
			state = "hover"
		"hop":
			st = 0.4
	z_index = 3
	_sync()


func tick(dt: float) -> void:
	if not alive:
		return
	var p = game.player
	var pb: Phys = p.b
	var dx := pb.x - b.x
	var dy := pb.y - b.y
	if absf(dx) > 430.0 and beh != "cross":
		return
	if not seen and absf(dx) < 210.0:
		seen = true
		game.note_seen(kind)
	t += dt
	var lv = game.lv
	match beh:
		"patrol":
			_gravity(dt)
			var hit := b.move_x(lv, dir * speed * dt)
			var land := b.move_y(lv, b.vy * dt)
			if land != 0:
				b.vy = 0.0
			if hit or (land == 1 and not _floor_ahead(lv)):
				dir = -dir
		"hop":
			_gravity(dt)
			st -= dt
			if b.move_x(lv, b.vx * dt):
				b.vx = -b.vx
				dir = -dir
			var land := b.move_y(lv, b.vy * dt)
			if land != 0:
				b.vy = 0.0
			if land == 1:
				b.vx = 0.0
				if st <= 0.0:
					b.vy = -float(def["jump"])
					st = 1.1
					if speed > 0.0:
						dir = 1 if dx > 0.0 else -1
						b.vx = dir * speed
		"chase":
			_chase(dt, lv, pb, dx, dy)
		"fly":
			_fly(dt, dx)
		"shooter":
			_gravity(dt)
			if b.move_y(lv, b.vy * dt) != 0:
				b.vy = 0.0
			dir = 1 if dx > 0.0 else -1
			st -= dt
			if state == "idle" and st <= 0.0:
				if absf(dx) < 230.0 and absf(dy) < 120.0:
					state = "charge"
					st = 0.5
				else:
					st = 0.3
			elif state == "charge" and st <= 0.0:
				_fire(dx)
				state = "post"
				st = 0.35
			elif state == "post" and st <= 0.0:
				state = "idle"
				st = def["rate"]
			vulnerable = not def.get("guard", false) or state == "idle"
		"drop":
			_drop(dt, lv, pb, dx)
		"cross":
			_cross(dt, pb)
		"pop":
			_pop(dt, pb, dx, dy)
		"pendulum":
			var ang := sin(t * 2.0) * 1.1
			b.x = home.x + sin(ang) * 44.0
			b.y = home.y + cos(ang) * 44.0
		"gust":
			dangerous = false
			if fmod(t, 3.8) < 2.2 and pb.dash_t <= 0.0:
				var zone := Rect2(home.x - 22.0, home.y + b.hh - 62.0, 44.0, 62.0)
				if zone.intersects(pb.rect()):
					pb.push_x -= 85.0
		"copy":
			_copy(dt, dx, dy)
		"dive":
			_dive(dt, lv, pb, dx, dy)
	_sync()
	if dangerous:
		_touch(p, pb)


func _gravity(dt: float) -> void:
	b.vy = clampf(b.vy + G.GRAVITY * b.g * dt, -G.MAX_FALL, G.MAX_FALL)


func _floor_ahead(lv) -> bool:
	var ax := int(floor((b.x + dir * (b.hw + 2.0)) / G.TILE))
	var ay := int(floor((b.feet() + 2.0 * b.g) / G.TILE))
	var tt: int = lv.tile(ax, ay)
	if not (Phys._is_solid(tt) or tt == G.T_ONEWAY):
		return false
	var body: int = lv.tile(ax, int(floor((b.feet() - 2.0 * b.g) / G.TILE)))
	return body != G.T_SPIKE and body != G.T_SPIKE_D


func _chase(dt: float, lv, pb: Phys, dx: float, dy: float) -> void:
	var active := absf(dx) < 120.0 and absf(dy) < 72.0
	if def.get("fly", false):
		var pos := Vector2(b.x, b.y)
		var v := Vector2.ZERO
		if active:
			v = (Vector2(pb.x, pb.y) - pos).normalized() * speed
			dir = 1 if dx > 0.0 else -1
		elif pos.distance_to(home) > 2.0:
			v = (home - pos).normalized() * speed * 0.6
		b.x += v.x * dt
		b.y += v.y * dt + sin(t * 4.0) * 0.15
		if def.has("shoot"):
			st -= dt
			if state == "" and st <= 0.0 and active:
				state = "charge"
				st = 0.5
			elif state == "charge" and st <= 0.0:
				state = ""
				st = def["rate"]
				var d := (Vector2(pb.x, pb.y) - pos).normalized()
				game.shoot(pos, d * 115.0, 0.0, "shot_ray")
				Snd.play("shoot")
		return
	_gravity(dt)
	var vx := 0.0
	if active:
		dir = 1 if dx > 0.0 else -1
		if absf(dx) > 3.0:
			vx = dir * speed
	if vx != 0.0 and (b.on_ground and not _floor_ahead(lv)) and not def.get("hop", false):
		vx = 0.0
	b.move_x(lv, vx * dt)
	var land := b.move_y(lv, b.vy * dt)
	b.on_ground = land == 1
	if land != 0:
		b.vy = 0.0
	if land == 1 and active and def.get("hop", false):
		if _floor_ahead(lv):
			b.vy = -130.0
		else:
			b.move_x(lv, -vx * dt)


func _fly(dt: float, dx: float) -> void:
	match def["path"]:
		"h":
			b.x = home.x + sin(t * speed / 40.0) * 40.0
			dir = 1 if cos(t * speed / 40.0) > 0.0 else -1
		"v":
			b.y = home.y + sin(t * speed / 32.0) * 32.0
		"sine":
			b.x = home.x + sin(t * speed / 48.0) * 48.0
			b.y = home.y + sin(t * speed / 11.0) * 10.0
			dir = 1 if cos(t * speed / 48.0) > 0.0 else -1
		"circle":
			b.x = home.x + cos(t * speed / 24.0) * 24.0
			b.y = home.y + sin(t * speed / 24.0) * 24.0
	if def.get("shoot", "") == "down":
		st -= dt
		if st <= 0.0 and absf(dx) < 170.0:
			st = def["rate"]
			game.shoot(Vector2(b.x, b.y + 6.0), Vector2(0, 150), 0.0, "shot_bolt")
			Snd.play("shoot")
	if def.get("mirror", false):
		st -= dt


func _fire(dx: float) -> void:
	var pos := Vector2(b.x, b.y - 2.0)
	Snd.play("shoot")
	match def["shot"]:
		"arc":
			game.shoot(pos, Vector2(dir * clampf(absf(dx), 40.0, 150.0) * 0.85, -175.0), 380.0, "shot_ink")
		"straight":
			game.shoot(pos, Vector2(dir * 125.0, 0), 0.0, "shot_seed")
		"spread":
			for k in [-1, 0, 1]:
				game.shoot(pos, Vector2(dir * 35.0 + k * 45.0, -195.0), 380.0, "shot_candy")


func _drop(dt: float, lv, pb: Phys, dx: float) -> void:
	match state:
		"wait":
			dangerous = true
			if absf(dx) < 30.0 and pb.y > b.y:
				state = "shake"
				st = 0.35
		"shake":
			st -= dt
			if st <= 0.0:
				state = "fall"
				b.vy = 0.0
				bounces = 0
		"fall":
			b.vy = minf(b.vy + 620.0 * dt, 280.0)
			if b.vx != 0.0 and b.move_x(lv, b.vx * dt):
				b.vx = -b.vx
			var land := b.move_y(lv, b.vy * dt)
			if land == 1 or b.y > lv.h * G.TILE + 40.0:
				if def.get("bounce", false) and bounces < 3 and land == 1:
					bounces += 1
					b.vy = -230.0 + bounces * 45.0
					b.vx = (1.0 if dx > 0.0 else -1.0) * 45.0
					Snd.play("bounce")
				else:
					game.fx.burst(Vector2(b.x, b.y), Color("cfe8ff"), 8, 60.0)
					state = "gone"
					st = 1.8
					dangerous = false
					visible = false
		"gone":
			st -= dt
			if st <= 0.0:
				b.x = home.x
				b.y = home.y
				b.vx = 0.0
				b.vy = 0.0
				state = "wait"
				visible = true


func _cross(dt: float, pb: Phys) -> void:
	var cl: float = game.cam_x - game.view_w * 0.5
	var cr: float = game.cam_x + game.view_w * 0.5
	match state:
		"wait":
			visible = false
			dangerous = false
			st -= dt
			if st <= 0.0 and absf(pb.x - home.x) < 380.0:
				state = "warn"
				st = 0.8
				b.y = home.y
				if Save.settings["sound_cues"]:
					game.cue(home.y)
				Snd.play("warn")
		"warn":
			st -= dt
			b.x = cr + 20.0
			if st <= 0.0:
				state = "go"
				visible = true
				dangerous = true
		"go":
			b.x -= speed * dt
			b.y += 10.0 * dt
			if randf() < 0.5:
				game.fx.spark(Vector2(b.x + 6.0, b.y), Color("ffe27a"))
			if b.x < cl - 40.0:
				state = "wait"
				st = 3.0


func _pop(dt: float, pb: Phys, dx: float, dy: float) -> void:
	st -= dt
	if def.get("pull", false):
		if st <= 0.0:
			state = "open" if state == "closed" else "closed"
			st = 1.8 if state == "open" else 2.2
		dangerous = state == "open"
		if dangerous and absf(dx) < 84.0 and absf(dy) < 50.0 and pb.dash_t <= 0.0:
			pb.push_x += -signf(dx) * 68.0
		spr.texture = (Art.shadow_tex("tombino_o") if shadow else Art.tex("tombino_o")) if dangerous else (Art.shadow_tex("tombino") if shadow else Art.tex("tombino"))
		return
	match state:
		"hidden":
			dangerous = false
			if absf(dx) < 46.0 and absf(dy) < 64.0 and st <= 0.0:
				state = "warn"
				st = 0.55
		"warn":
			if st <= 0.0:
				state = "up"
				st = 1.0
				Snd.play("warn")
		"up":
			dangerous = st < 0.9
			if st <= 0.0:
				state = "hidden"
				st = 1.2


func _copy(dt: float, dx: float, dy: float) -> void:
	st -= dt
	match state:
		"idle":
			dangerous = false
			spr.modulate.a = 0.55
			if absf(dx) < 90.0 and absf(dy) < 60.0:
				state = "follow"
				st = 6.0
		"follow":
			var e = game.trail_at(66)
			if e != null:
				b.x = lerpf(b.x, e[0], 0.5)
				b.y = lerpf(b.y, e[1] - b.hh * e[4], 0.5)
				dir = e[2]
				spr.texture = frames.get(e[3], frames["idle"])
				spr.flip_v = e[4] < 0
			spr.modulate.a = 0.9
			dangerous = st < 5.4
			if st <= 0.0:
				state = "cool"
				st = 3.0
				game.fx.burst(Vector2(b.x, b.y), Color("4a2a7a"), 10, 50.0)
		"cool":
			dangerous = false
			b.x = home.x
			b.y = home.y
			spr.texture = frames["idle"]
			spr.flip_v = false
			spr.modulate.a = 0.25
			if st <= 0.0:
				state = "idle"


func _dive(dt: float, lv, pb: Phys, dx: float, dy: float) -> void:
	var pos := Vector2(b.x, b.y)
	match state:
		"hover":
			b.y = home.y + sin(t * 3.0) * 3.0
			dir = 1 if dx > 0.0 else -1
			if absf(dx) < 96.0 and dy > 14.0 and dy < 150.0:
				state = "aim"
				st = 0.4
				Snd.play("warn")
		"aim":
			st -= dt
			if st <= 0.0:
				target = Vector2(pb.x, pb.y)
				vel = (target - pos).normalized() * speed
				state = "dive"
				st = 1.3
		"dive":
			st -= dt
			b.x += vel.x * dt
			b.y += vel.y * dt
			if b.y >= target.y or st <= 0.0 or lv.solid(int(floor(b.x / G.TILE)), int(floor((b.y + b.hh) / G.TILE))):
				state = "rise"
		"rise":
			var v := home - pos
			if v.length() < 3.0:
				state = "hover"
			else:
				v = v.normalized() * 62.0
				b.x += v.x * dt
				b.y += v.y * dt


func _touch(p, pb: Phys) -> void:
	if p.dead or not pb.rect().intersects(b.rect().grow(-1.0)):
		return
	var can_die: bool = not def.get("invuln", false) and vulnerable
	if pb.slamming and can_die:
		kill()
		return
	var falling := pb.vy * pb.g > 30.0
	var above: bool = (p.prev_feet - b.y) * pb.g <= -b.hh * 0.2
	if falling and above and can_die:
		kill()
		p.bounce_off(game.last_inp.get("jh", false))
		return
	if def.get("knock", false):
		pb.vx = (1.0 if pb.x >= b.x else -1.0) * 230.0
		pb.vy = -150.0 * pb.g
		pb.lock_t = 0.2
		pb.on_ground = false
		Snd.play("bounce")
	elif def.get("sticky", false):
		if pb.slow_t <= 0.0:
			Snd.play("sticky")
		pb.slow_t = 2.0
	elif def.get("mirror", false):
		if st <= 0.0:
			p.mirror_t = 2.0
			st = 2.6
			Snd.play("flip")
			game.flash(Color(0.7, 0.5, 1.0, 0.3))
	else:
		p.hurt(1, b.x)


func kill() -> void:
	alive = false
	visible = false
	Snd.play("stomp")
	game.buzz(15)
	game.fx.burst(Vector2(b.x, b.y), Color("4a2a7a") if shadow else Color.WHITE, 10, 70.0)
	game.on_enemy_killed(self)


func _sync() -> void:
	position = Vector2(round(b.x), round(b.y))
	if spr.texture != null and beh != "copy":
		var th := spr.texture.get_height()
		if def["slot"] == "g":
			spr.position.y = b.hh - th * 0.5 + 1.0
		elif def["slot"] == "c":
			spr.position.y = -(b.hh - th * 0.5) - 1.0
			spr.flip_v = true
		spr.flip_h = dir > 0
	elif beh == "copy":
		spr.position.y = b.hh - 17.0 if not spr.flip_v else -(b.hh - 17.0)
		spr.flip_h = dir < 0
	match beh:
		"shooter":
			spr.position.x = sin(t * 60.0) if state == "charge" else 0.0
		"drop":
			spr.position.x = sin(t * 70.0) * 1.5 if state == "shake" else 0.0
		"pop":
			if not def.get("pull", false):
				spr.visible = state == "up"
		"patrol":
			if def.get("spin", false):
				spr.rotation = t * 6.0 * dir
		"chase":
			if kind == "trottola":
				spr.flip_h = int(t * 10.0) % 2 == 0
			spr.modulate = Color(1.6, 0.8, 0.8) if state == "charge" else Color.WHITE
	if kind == "piccione":
		spr.flip_v = true
	if guard_spr != null:
		guard_spr.visible = not vulnerable
	queue_redraw()


func _draw() -> void:
	match beh:
		"pendulum":
			draw_line(home - position, Vector2.ZERO, Color("5a4014"), 1.0)
			draw_rect(Rect2(home - position - Vector2(2, 2), Vector2(4, 4)), Color("c9962e"))
		"gust":
			if fmod(t, 3.8) < 2.2:
				for i in range(7):
					var yy := b.hh - 6.0 - i * 8.0
					var xx := fposmod(-t * 120.0 + i * 37.0, 44.0) - 22.0
					draw_rect(Rect2(xx, yy, 10, 1), Color(1, 1, 1, 0.55))
					draw_rect(Rect2(xx + 3, yy + 3, 6, 1), Color(1, 1, 1, 0.3))
			else:
				for i in range(3):
					draw_rect(Rect2(-12 + i * 10, b.hh - 3, 4, 1), Color(1, 1, 1, 0.25))
		"pop":
			if state == "warn":
				draw_rect(Rect2(-7, b.hh - 2, 14, 2), Color(0.3, 0.1, 0.5, 0.8))
				draw_rect(Rect2(-3 + sin(t * 40.0) * 2.0, b.hh - 5, 6, 3), Color(0.3, 0.1, 0.5, 0.8))
