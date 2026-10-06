extends "res://src/game/bosses/BossBase.gd"
## Il Sindaco Sottosopra: salta tra pavimento e soffitto; invertendo la gravità
## lo si insegue e gli si piomba addosso (serve una caduta lunga).

const W := 18.0
const H := 38.0
const CEIL := 48.0

var side := 1  # 1 pavimento, -1 soffitto
var leap := 0.0
var sw := 0.0
var from_y := 0.0


func _reset() -> void:
	side = 1
	pos = Vector2(home.x, home.y - H * 0.5)
	st = 1.5
	sw = 3.0
	leap = 0.0


func _y_for(s: int) -> float:
	return home.y - H * 0.5 if s == 1 else CEIL + H * 0.5


func _on_hit() -> void:
	sw = 0.0


func _tick(dt: float) -> void:
	var pb = game.player.b
	sw -= dt
	if leap > 0.0:
		leap -= dt
		pos.y = lerpf(_y_for(side), from_y, clampf(leap / 0.45, 0.0, 1.0))
	else:
		pos.y = _y_for(side)
		if absf(pb.x - pos.x) > 6.0:
			pos.x += signf(pb.x - pos.x) * 42.0 * rate() * dt
		if sw <= 0.0:
			sw = 3.6 / rate()
			from_y = pos.y
			side = -side
			leap = 0.45
			Snd.play("flip")
		if st <= 0.0:
			st = 1.7 / rate()
			var d := (Vector2(pb.x, pb.y) - pos).normalized()
			game.shoot(pos, d * 105.0, 0.0, "shot_seed")
			Snd.play("shoot")
	var body := Rect2(pos.x - W * 0.5, pos.y - H * 0.5, W, H)
	var head := Rect2(body.position.x - 2.0, body.position.y - 2.0 if side == 1 else body.end.y - 10.0, W + 4.0, 12.0)
	if leap > 0.0 or not stomp(head, 270.0):
		touch(body.grow(-2.0))


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, side))
	var o := Vector2(-W * 0.5, -H * 0.5)
	draw_rect(Rect2(o + Vector2(3, -8), Vector2(12, 9)), Color("1a1423"))
	draw_rect(Rect2(o + Vector2(0, 0), Vector2(18, 2)), Color("1a1423"))
	draw_rect(Rect2(o + Vector2(3, -3), Vector2(12, 2)), Color("d9534f"))
	draw_rect(Rect2(o + Vector2(4, 2), Vector2(10, 9)), Color("f2c6a0"))
	draw_rect(Rect2(o + Vector2(6, 5), Vector2(2, 2)), Color("1a1423"))
	draw_rect(Rect2(o + Vector2(11, 5), Vector2(2, 2)), Color("1a1423"))
	draw_rect(Rect2(o + Vector2(5, 8), Vector2(8, 2)), Color("4a2f1f"))
	draw_rect(Rect2(o + Vector2(1, 11), Vector2(16, 17)), Color("303246"))
	for i in range(8):
		draw_rect(Rect2(o + Vector2(3 + i * 1.5, 12 + i * 2), Vector2(3, 2)), Color("ffd166"))
	draw_rect(Rect2(o + Vector2(3, 28), Vector2(5, 10)), Color("1a1423"))
	draw_rect(Rect2(o + Vector2(10, 28), Vector2(5, 10)), Color("1a1423"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
