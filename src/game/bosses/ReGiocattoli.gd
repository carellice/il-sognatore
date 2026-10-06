extends "res://src/game/bosses/BossBase.gd"
## Re dei Giocattoli: carica da una parte all'altra; quando sbatte contro il muro
## resta stordito e gli si salta in testa.

const W := 30.0
const H := 38.0

var dir := -1


func _reset() -> void:
	pos = Vector2(home.x, home.y - H * 0.5)
	state = "idle"
	st = 1.4
	dir = -1


func _on_hit() -> void:
	state = "idle"
	st = 0.9


func _tick(dt: float) -> void:
	var pb = game.player.b
	match state:
		"idle":
			if st <= 0.0:
				dir = 1 if pb.x > pos.x else -1
				state = "windup"
				st = 0.55
				Snd.play("warn")
		"windup":
			if st <= 0.0:
				state = "charge"
		"charge":
			pos.x += dir * 150.0 * rate() * dt
			if pos.x < W * 0.5 + 2.0 or pos.x > arena.x - W * 0.5 - 2.0:
				pos.x = clampf(pos.x, W * 0.5 + 2.0, arena.x - W * 0.5 - 2.0)
				state = "stun"
				st = 2.6 - phase * 0.4
				game.shake(5.0)
				Snd.play("slam")
		"stun":
			if st <= 0.0:
				state = "idle"
				st = 0.4
	var body := Rect2(pos.x - W * 0.5, pos.y - H * 0.5, W, H)
	if state == "stun":
		stomp(Rect2(body.position.x, body.position.y - 2.0, W, 14.0))
	else:
		touch(body.grow(-2.0))


func _draw() -> void:
	var shake := sin(t * 60.0) * 1.5 if state == "windup" else 0.0
	var o := Vector2(-W * 0.5 + shake, -H * 0.5)
	draw_rect(Rect2(o + Vector2(2, 14), Vector2(26, 18)), Color("9aa0b4"))
	draw_rect(Rect2(o + Vector2(2, 14), Vector2(26, 2)), Color("cfd6e6"))
	draw_rect(Rect2(o + Vector2(10, 19), Vector2(10, 8)), Color("d9534f"))
	draw_rect(Rect2(o + Vector2(5, 0), Vector2(20, 14)), Color("cfd6e6"))
	draw_rect(Rect2(o + Vector2(14, -5), Vector2(2, 5)), Color("555a6e"))
	draw_rect(Rect2(o + Vector2(12, -8), Vector2(6, 4)), Color("ffd65a"))
	var eye := Color("d9534f") if state == "charge" or state == "windup" else Color("1a1423")
	if state == "stun":
		for i in range(2):
			var c := o + Vector2(10 + i * 10, 6)
			draw_arc(c, 3.0, t * 8.0, t * 8.0 + 4.5, 8, Color("1a1423"), 1.0)
		for i in range(3):
			var a := t * 4.0 + i * TAU / 3.0
			draw_rect(Rect2(o + Vector2(15 + cos(a) * 12.0, -10 + sin(a) * 3.0), Vector2(2, 2)), Color("ffd65a"))
	else:
		draw_rect(Rect2(o + Vector2(8, 4), Vector2(4, 4)), eye)
		draw_rect(Rect2(o + Vector2(18, 4), Vector2(4, 4)), eye)
	draw_rect(Rect2(o + Vector2(9, 10), Vector2(12, 2)), Color("555a6e"))
	draw_rect(Rect2(o + Vector2(-2, 16), Vector2(4, 12)), Color("555a6e"))
	draw_rect(Rect2(o + Vector2(28, 16), Vector2(4, 12)), Color("555a6e"))
	draw_circle(o + Vector2(8, 34), 4.0, Color("1a1423"))
	draw_circle(o + Vector2(22, 34), 4.0, Color("1a1423"))
	draw_circle(o + Vector2(8, 34), 1.5, Color("9aa0b4"))
	draw_circle(o + Vector2(22, 34), 1.5, Color("9aa0b4"))
