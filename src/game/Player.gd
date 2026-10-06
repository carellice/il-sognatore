extends Node2D
## Flavio: collega la fisica (Phys.gd) a sprite, salute, abilità ed effetti.

const Phys = preload("res://src/game/Phys.gd")

var game
var b: Phys
var hp := G.MAX_HP
var invuln := 0.0
var mirror_t := 0.0
var dead := false
var stage := 0
var actives: Array = []
var sel := 0
var frames := {}
var spr: Sprite2D
var squash := Vector2.ONE
var anim := "idle"
var run_dist := 0.0
var safe_pos := Vector2.ZERO  # ultimo punto sicuro (tutorial)
var prev_feet := 0.0


func setup(g, world: int, postgame: bool) -> void:
	game = g
	stage = G.stage_of(world)
	var ab := G.abilities_for(world, postgame)
	actives = ab["actives"]
	b = Phys.new()
	b.full_h = G.STAGE_H[stage]
	b.hh = b.full_h * 0.5
	b.hw = G.BODY_HW
	b.has_double = ab["double"]
	b.has_glide = ab["glide"]
	b.auto_high = Save.settings["auto_high"]
	frames = Art.player_frames(stage)
	spr = Sprite2D.new()
	spr.texture = frames["idle"]
	add_child(spr)
	z_index = 5


func place(feet: Vector2) -> void:
	b.g = 1
	b.set_feet(feet.x, feet.y)
	b.vx = 0.0
	b.vy = 0.0
	b.on_ground = true
	b.dash_t = 0.0
	b.bubble_t = 0.0
	b.slamming = false
	b.crouch = false
	b.hh = b.full_h * 0.5
	b.set_feet(feet.x, feet.y)
	b.cd.clear()
	b.ride = null
	safe_pos = feet
	prev_feet = feet.y
	_sync()


func ability() -> String:
	return actives[sel] if not actives.is_empty() else ""


func tick(inp: Dictionary, dt: float) -> void:
	if dead:
		return
	invuln = maxf(0.0, invuln - dt)
	mirror_t = maxf(0.0, mirror_t - dt)
	var i := inp.duplicate()
	if mirror_t > 0.0:
		i["mx"] = -float(i.get("mx", 0.0))
	if i.get("ab_swipe", false):
		if i.get("undo", false):
			b.undo_jump()
		i["ab"] = ability()
	prev_feet = b.feet()
	var lv = game.lv
	b.step(i, dt, lv)
	for ev in b.events:
		_on_event(ev)
	# spine
	if _touches_spike(lv):
		hurt(1, b.x - b.facing)
	# punto sicuro: a terra, lontano dai bordi
	if b.on_ground and b.g == 1 and b.ride == null and invuln <= 0.0:
		var tx := int(floor(b.x / G.TILE))
		var ty := int(floor((b.feet() + 2.0) / G.TILE))
		if lv.tile(tx, ty) == G.T_SOLID and lv.tile(tx - 1, ty) == G.T_SOLID and lv.tile(tx + 1, ty) == G.T_SOLID:
			safe_pos = Vector2(tx * G.TILE + 8.0, ty * G.TILE)
	if b.y > lv.h * G.TILE + 28.0 or b.y < -90.0:
		game.player_fell()
	_animate(dt)
	_sync()


func _touches_spike(lv) -> bool:
	for tx in range(int(floor((b.x - b.hw + 2.0) / G.TILE)), int(floor((b.x + b.hw - 2.0) / G.TILE)) + 1):
		for ty in range(int(floor((b.y - b.hh) / G.TILE)), int(floor((b.y + b.hh - 0.01) / G.TILE)) + 1):
			var t: int = lv.tile(tx, ty)
			if t == G.T_SPIKE and b.y + b.hh > ty * G.TILE + 8.0:
				return true
			if t == G.T_SPIKE_D and b.y - b.hh < ty * G.TILE + 8.0:
				return true
	return false


func _on_event(ev: String) -> void:
	var feet := Vector2(b.x, b.feet())
	match ev:
		"jump":
			Snd.play("jump")
			game.buzz(8)
			game.fx.puff(feet, 4)
			squash = Vector2(0.78, 1.22)
		"djump":
			Snd.play("djump")
			game.buzz(8)
			game.fx.ring(feet, Color.WHITE)
			squash = Vector2(0.8, 1.2)
		"land":
			Snd.play("land")
			game.fx.puff(feet, 4)
			squash = Vector2(1.25, 0.78)
		"dash":
			Snd.play("dash")
			game.fx.burst(Vector2(b.x, b.y), G.ABILITY_COLOR["scatto"], 8, 50.0)
		"bubble":
			Snd.play("bubble")
		"pop":
			Snd.play("pop")
			game.fx.burst(Vector2(b.x, b.y), G.ABILITY_COLOR["bolla"], 10, 60.0)
		"flip":
			Snd.play("flip")
			game.fx.ring(Vector2(b.x, b.y), G.ABILITY_COLOR["gravita"])
		"slam":
			Snd.play("dash")
		"slam_land":
			Snd.play("slam")
			game.shake(4.0)
			game.buzz(20)
			game.fx.burst(feet, Color.WHITE, 10, 80.0)
			game.fx.puff(feet, 8)
			squash = Vector2(1.4, 0.65)
		"bounce":
			Snd.play("bounce")
		"superbounce":
			Snd.play("bounce")
			game.shake(3.0)
			game.fx.ring(feet, G.ABILITY_COLOR["schianto"])
		"break":
			Snd.play("break")
			game.on_crates_broken()
		"tempo":
			game.start_slow()
		"riflesso":
			game.spawn_clone()


func hurt(amount: int, from_x: float) -> void:
	if invuln > 0.0 or dead or game.state != "play" or Save.settings["mod_god"]:
		return
	if b.bubble_t > 0.0:
		b.pop_bubble()
	hp -= amount
	Snd.play("hurt")
	game.buzz(40)
	game.shake(3.0)
	game.flash(Color(1, 0.3, 0.3, 0.35))
	if hp <= 0:
		die()
		return
	invuln = G.INVULN
	b.lock_t = 0.25
	b.vy = -180.0 * b.g
	b.vx = (1.0 if b.x >= from_x else -1.0) * 120.0
	b.on_ground = false
	b.slamming = false
	b.dash_t = 0.0


func die() -> void:
	if dead:
		return
	dead = true
	hp = 0
	Snd.play("die")
	game.fx.burst(Vector2(b.x, b.y), Color("fff3b0"), 18, 90.0)
	visible = false
	game.player_died()


func revive(feet: Vector2) -> void:
	dead = false
	hp = G.MAX_HP
	invuln = 1.0
	mirror_t = 0.0
	visible = true
	place(feet)


func bounce_off(strong: bool) -> void:
	b.vy = -(G.JUMP_V if strong else 230.0) * b.g
	b.jumping = strong
	b.on_ground = false
	b.djump_used = false
	b.slamming = false


func _animate(dt: float) -> void:
	var a := "idle"
	if b.lock_t > 0.0:
		a = "hurt"
	elif b.crouch or b.dash_t > 0.0:
		a = "slide"
	elif b.gliding:
		a = "glide"
	elif not b.on_ground:
		a = "jump" if b.vy * b.g < 0.0 or b.bubble_t > 0.0 else "fall"
	elif absf(b.vx) > 12.0:
		run_dist += absf(b.vx) * dt
		a = "run%d" % (int(run_dist / 9.0) % 4)
	anim = a
	spr.texture = frames[a]


func _sync() -> void:
	position = Vector2(round(b.x), round(b.feet()))
	spr.offset = Vector2(0, -17 * b.g)
	squash = squash.lerp(Vector2.ONE, 0.2)
	spr.scale = squash
	spr.flip_h = b.facing < 0
	spr.flip_v = b.g < 0
	spr.visible = invuln <= 0.0 or int(invuln * 14.0) % 2 == 0
	spr.modulate = Color(1.6, 0.7, 1.6) if mirror_t > 0.0 else (Color(1.0, 0.8, 0.9) if b.slow_t > 0.0 else Color.WHITE)
	queue_redraw()


func _draw() -> void:
	if b == null:
		return
	_draw_shadow()
	if b.bubble_t > 0.0:
		var c := Vector2(0, -b.hh * b.g)
		var col: Color = G.ABILITY_COLOR["bolla"]
		var blink := b.bubble_t < 0.8 and int(b.bubble_t * 12.0) % 2 == 0
		if not blink:
			draw_arc(c, b.hh + 5.0, 0.0, TAU, 20, col, 1.0)
			draw_circle(c, b.hh + 4.0, Color(col.r, col.g, col.b, 0.18))
			draw_rect(Rect2(c.x - 6, c.y - b.hh, 2, 2), Color.WHITE)
	if b.slamming:
		for i in range(3):
			draw_rect(Rect2(-4 + i * 4, (-b.full_h - 6 - i * 3) * b.g, 1, 6), G.ABILITY_COLOR["schianto"])


## Ombra ai piedi: più piccola e tenue quando Flavio è in aria.
func _draw_shadow() -> void:
	if b.g < 0 or dead:
		return
	var lv = game.lv
	var tx := int(floor(b.x / G.TILE))
	var ty0 := int(floor((b.feet() - 1.0) / G.TILE))
	for ty in range(ty0, ty0 + 6):
		var t: int = lv.tile(tx, ty)
		if t == G.T_SOLID or t == G.T_ONEWAY or t == G.T_CRATE or t == G.T_BOUNCY or t == G.T_FAKE:
			var gy: float = ty * G.TILE - b.feet()
			if gy < -2.0:
				continue
			var k := clampf(1.0 - gy / 80.0, 0.0, 1.0)
			var w := 3.0 + 4.0 * k
			draw_rect(Rect2(-w, gy, w * 2.0, 1), Color(0, 0, 0.05, 0.28 * k))
			draw_rect(Rect2(-w + 1.0, gy + 1.0, w * 2.0 - 2.0, 1), Color(0, 0, 0.05, 0.28 * k))
			return
