extends "res://src/game/bosses/BossBase.gd"
## Il Grande Orologio: le lancette spazzano l'arena; rallentando il tempo
## si passa tra loro e si colpisce il meccanismo centrale.

var dirn := 1.0
var a1 := 0.0
var a2 := 2.0


func _reset() -> void:
	pos = Vector2(arena.x * 0.5, 100.0)
	a1 = -1.2
	a2 = 2.4


func _on_hit() -> void:
	dirn = -dirn


func _hand(angle: float, length: float) -> void:
	var pb = game.player.b
	var d := Vector2(cos(angle), sin(angle))
	var a := pos + d * 18.0
	var b := pos + d * length
	var p := Vector2(pb.x, pb.y)
	var q := Geometry2D.get_closest_point_to_segment(p, a, b)
	if absf(p.x - q.x) < pb.hw + 2.0 and absf(p.y - q.y) < pb.hh + 2.0:
		game.player.hurt(1, q.x)


func _tick(dt: float) -> void:
	a1 += dt * 2.5 * rate() * dirn
	a2 -= dt * 1.6 * rate() * dirn
	if not stomp(Rect2(pos.x - 13.0, pos.y - 16.0, 26.0, 14.0)) and invuln <= 0.0:
		_hand(a1, 150.0)
		_hand(a2, 76.0)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 24.0, Color("5a4014"))
	draw_circle(Vector2.ZERO, 21.0, Color("e6c15a"))
	draw_circle(Vector2.ZERO, 18.0, Color("fff5f0"))
	for i in range(12):
		var a := i * TAU / 12.0
		draw_rect(Rect2(Vector2(cos(a), sin(a)) * 15.0 - Vector2(1, 1), Vector2(2, 2)), Color("1a1423"))
	var d1 := Vector2(cos(a1), sin(a1))
	var d2 := Vector2(cos(a2), sin(a2))
	draw_line(d1 * 18.0, d1 * 150.0, Color("1a1423"), 5.0)
	draw_line(d1 * 18.0, d1 * 150.0, Color("d9d9d9"), 3.0)
	draw_line(d2 * 18.0, d2 * 76.0, Color("1a1423"), 6.0)
	draw_line(d2 * 18.0, d2 * 76.0, Color("d9534f"), 4.0)
	draw_circle(Vector2.ZERO, 8.0, Color("d9534f"))
	draw_circle(Vector2(-2, -2), 3.0, Color("ffb0a8"))
	draw_rect(Rect2(-6, -22, 12, 4), Color("ffd65a") if int(t * 6.0) % 2 == 0 else Color("c9962e"))
