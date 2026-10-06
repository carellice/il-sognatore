extends "res://src/game/bosses/BossBase.gd"
## L'Incubo, il boss finale: un'ombra enorme che usa tutte le abilità contro Flavio.
## Fase 1: scatto e gravità. Fase 2: tempo e bolla. Fase 3: riflesso, schianto e planata.

var eye := Vector2.ZERO
var shield_t := 0.0
var side := 1
var hand_x := 0.0
var hand_t := -1.0
var orbit := 0.0


func _reset() -> void:
	hand_t = -1.0
	_on_phase()


func _on_phase() -> void:
	eye = [Vector2(arena.x * 0.5, 52.0), Vector2(arena.x * 0.5, 98.0), Vector2(arena.x * 0.5, 128.0)][mini(phase, 2)]
	pos = eye
	shield_t = 0.0
	st = 2.0


func on_switches() -> void:
	if phase == 2 and shield_t <= 0.0:
		shield_t = 6.0
		Snd.play("secret")
		game.flash(Color(0.8, 0.9, 1.0, 0.3))


func _tick(dt: float) -> void:
	var p = game.player
	var pb = p.b
	pos = eye + Vector2(sin(t * 1.3) * 5.0, sin(t * 2.1) * 3.0)
	var weak := Rect2(pos.x - 13.0, pos.y - 13.0, 26.0, 26.0)
	match phase:
		0:
			# muri d'ombra con un varco basso: si passa con lo scatto
			if st <= 0.0:
				st = 3.2 / rate()
				side = -side
				var x := 8.0 if side == 1 else arena.x - 8.0
				var y := home.y - 20.0
				while y > 36.0:
					game.shoot(Vector2(x, y), Vector2(side * 120.0, 0), 0.0, "shot_ray", 6.0, true)
					y -= 8.0
				Snd.play("shoot")
			# l'occhio pende dal soffitto: ci si arriva solo cadendo all'insù
			if pb.g == -1:
				stomp(weak)
		1:
			# lame in orbita: col tempo rallentato si passa, con la bolla si sale
			orbit += dt * 4.6 * rate()
			for i in range(3):
				var a := orbit + i * TAU / 3.0
				var bp := pos + Vector2(cos(a), sin(a)) * 32.0
				if absf(pb.x - bp.x) < pb.hw + 5.0 and absf(pb.y - bp.y) < pb.hh + 5.0:
					p.hurt(1, bp.x)
			if st <= 0.0:
				st = 1.3 / rate()
				game.shoot(Vector2(randf_range(30.0, arena.x - 30.0), 36.0), Vector2(0, 130), 0.0, "shot_bolt")
			stomp(weak)
		2:
			shield_t = maxf(0.0, shield_t - dt)
			# mani d'ombra dal pavimento: meglio restare in aria
			if hand_t < 0.0 and st <= 0.0:
				hand_t = 1.2
				hand_x = pb.x
				Snd.play("warn")
			if hand_t >= 0.0:
				hand_t -= dt
				if hand_t < 0.6 and hand_t > 0.1:
					touch(Rect2(hand_x - 7.0, home.y - 42.0, 14.0, 42.0))
				if hand_t < 0.0:
					st = 1.8 / rate()
			if shield_t > 0.0:
				stomp(weak)
			elif pb.rect().intersects(weak) and pb.vy > 0.0 and not p.dead:
				p.bounce_off(false)
				Snd.play("bounce")


func _draw() -> void:
	var dark := Color(0.06, 0.03, 0.1, 0.92)
	# corpo d'ombra che riempie la parte alta dell'arena
	var cam_top := Vector2(arena.x * 0.5, 30.0) - pos
	draw_circle(cam_top + Vector2(0, -30), 150.0, dark)
	for i in range(7):
		var x := -210.0 + i * 70.0 + sin(t * 1.5 + i) * 10.0
		draw_colored_polygon(PackedVector2Array([cam_top + Vector2(x - 26, 60), cam_top + Vector2(x + 26, 60), cam_top + Vector2(x + sin(t * 2.0 + i) * 8.0, 118 + sin(t + i) * 12.0)]), dark)
	# occhio
	draw_circle(Vector2.ZERO, 15.0, Color("1a1423"))
	draw_circle(Vector2.ZERO, 12.0, Color.WHITE)
	var look := (Vector2(game.player.b.x, game.player.b.y) - pos).normalized() * 4.0
	draw_circle(look, 6.0, Color("ff3b6b"))
	draw_circle(look, 3.0, Color("1a1423"))
	if phase == 1:
		var blade := Art.tex("blade")
		for i in range(3):
			var a := orbit + i * TAU / 3.0
			draw_texture(blade, (Vector2(cos(a), sin(a)) * 32.0 - Vector2(7, 7)).round())
	if phase == 2:
		if shield_t <= 0.0:
			draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 24, Color("c08cff"), 2.0)
			draw_arc(Vector2.ZERO, 23.0, t * 3.0, t * 3.0 + 3.0, 12, Color("ff3b6b"), 1.0)
		elif int(shield_t * 8.0) % 2 == 0:
			draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 24, Color(1, 1, 1, 0.25), 1.0)
		if hand_t >= 0.0:
			var hx := hand_x - pos.x
			var gy := home.y - pos.y
			if hand_t >= 0.6:
				draw_rect(Rect2(hx - 8, gy - 3, 16, 3), Color(0.3, 0.1, 0.5, 0.9))
			else:
				draw_texture(Art.tex("mano"), Vector2(hx - 5, gy - 40))
				draw_texture(Art.tex("mano"), Vector2(hx - 5, gy - 22))
